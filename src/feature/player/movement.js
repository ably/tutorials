import {
    LEFT_KEY,
    RIGHT_KEY,
    UP_KEY,
    DOWN_KEY,
    SPRITE_SIZE,
    MAP_HEIGHT,
    MAP_WIDTH,
} from '../constants'
import store from '../../config/store'
import { getNewPosition, channelId } from '../../util'
require('../../ably')

const localPlayerSteps = JSON.parse(localStorage.getItem('steps'))
let playerSteps = localPlayerSteps || 0

export const movement = player => {
    //TODO: Add Ably Script
    window.Ably.connection.on(function(stateChange) {
        console.log('New connection state is ' + stateChange.current)
    })

    const outboundChannel = window.Ably.channels.get(
        'cloudflare:worker:' + channelId(6)
    )

    const getCurrentTiles = () => {
        const level = store.getState().control.level
        return store.getState().map.tiles[level]
    }

    const observeBoundaries = newPos => {
        return (
            newPos[0] >= 0 &&
            newPos[0] <= MAP_HEIGHT - SPRITE_SIZE &&
            newPos[1] >= 0 &&
            newPos[1] <= MAP_WIDTH - SPRITE_SIZE
        )
    }

    const getNextTiles = newPos => {
        const tiles = getCurrentTiles()
        const x = newPos[1] / SPRITE_SIZE
        const y = newPos[0] / SPRITE_SIZE
        const nextTiles = tiles[y][x]
        return nextTiles
    }

    const handleWin = newPos => {
        const tiles = store.getState().map.tiles
        const level = store.getState().control.level
        const score = store.getState().control.score
        const nextTiles = getNextTiles(newPos)
        if (nextTiles === 2) {
            if (tiles.length > level + 1) {
                window.localStorage.setItem('level', level + 1)
                window.localStorage.setItem('score', score)
                window.localStorage.setItem('isComplete', true)

                store.dispatch({
                    type: 'UPDATE_SCORE',
                    payload: {
                        level: level + 1,
                        score: score + 10,
                    },
                })

                // TODO: Add Ably Outbound Channel
                outboundChannel.publish('player', { playerSteps }, err => {
                    if (err) {
                        return console.error('Failed to publish', err)
                    }
                    console.log('published')
                })
                return window.alert(
                    ` Delivery ${level + 1} completed successfully!`
                )
            }
            store.dispatch({
                type: 'PLAY',
                payload: {
                    isPlaying: false,
                },
            })
            return window.alert('Well done! Deliveries Complete!')
        }
    }
    const observeImpassable = newPos => {
        const tiles = getCurrentTiles()
        const x = newPos[1] / SPRITE_SIZE
        const y = newPos[0] / SPRITE_SIZE
        const nextTiles = tiles[y][x]
        return nextTiles === 0 ? false : true
    }

    const getWalkIndex = () => {
        const walkingIndex = store.getState().player.walkingIndex
        return walkingIndex >= 7 ? 0 : walkingIndex + 1
    }

    const directionMove = (direction, newPos) => {
        const walkingIndex = getWalkIndex()
        const walkingSteps = JSON.parse(localStorage.getItem('steps'))
        store.dispatch({
            type: 'MOVE_PLAYER',
            payload: {
                position: newPos,
                direction,
                walkingIndex,
                spriteLocation: getNewPosition([], direction, walkingIndex)
                    .location,
                steps: walkingSteps,
            },
        })
    }

    const attemptMove = direction => {
        const oldPos = store.getState().player.position
        const isPlaying = true
        const newPos = getNewPosition(oldPos, direction, null).postion
        if (
            isPlaying &&
            observeBoundaries(newPos) &&
            observeImpassable(newPos)
        ) {
            localStorage.setItem('steps', playerSteps++)
            handleWin(newPos)
            return directionMove(direction, newPos)
        }
    }

    const keyPress = e => {
        e.preventDefault()
        switch (e.keyCode) {
            case LEFT_KEY:
                return attemptMove('WEST')
            case RIGHT_KEY:
                return attemptMove('EAST')
            case UP_KEY:
                return attemptMove('NORTH')
            case DOWN_KEY:
                return attemptMove('SOUTH')
            default:
                return attemptMove(e.keyCode)
        }
    }

    const handleKeyDown = e => {
        const { username } = store.getState().user
        if (username) {
            keyPress(e)
        }
    }

    window.addEventListener('keydown', e => {
        handleKeyDown(e)
    })

    return player
}

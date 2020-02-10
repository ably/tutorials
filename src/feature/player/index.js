import React, { useEffect } from 'react'
import walkSprite from './player_walk.png'
import { connect } from 'react-redux'
import { movement } from './movement'
import store from '../../config/store'

const Player = props => {
    useEffect(() => {
        const username = localStorage.getItem('username')
        if (username) {
            const inboundChannel = window.Ably.channels.get('cloudflare-bot')
            inboundChannel.subscribe(function(message) {
                if (message.data.endGame) {
                    localStorage.removeItem('username')
                    store.dispatch({
                        type: 'PLAY',
                        payload: {
                            isPlaying: message.data.isPlaying,
                        },
                    })
                    store.dispatch({
                        type: 'END_GAME',
                        payload: {
                           endGame: message.data.endGame
                        },
                    })
                    store.dispatch({
                        type: 'USERNAME',
                        payload: {
                           username: null
                        },
                    })
                  
                }
            })
            inboundChannel.presence.enterClient(username)
        }
    }, [])
    return (
        <>
            <div
                style={{
                    position: 'absolute',
                    top: props.position[0],
                    left: props.position[1],
                    backgroundImage: `url('${walkSprite}')`,
                    backgroundPosition: props.spriteLocation,
                    width: '40px',
                    height: '40px',
                }}
            />
        </>
    )
}

const mapStateToProps = state => {
    return {
        ...state.player,
        members: state.members,
        isPlaying: state.global.isPlaying,
        timer: state.timing.timer,
    }
}

export default connect(mapStateToProps)(movement(Player))

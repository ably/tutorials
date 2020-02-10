import { SPRITE_SIZE } from "../feature/constants"

export const getSpriteTile = type => {
    switch (type) {
        case 0:
            return 'stones'
        case 2: 
            return 'finish'
        default:
            return 'default'
    }
}


export const getNewPosition = (oldPos, direction, walkingIndex) => {
    switch (direction) {
        case 'NORTH':
            return {
                postion: [oldPos[0] - SPRITE_SIZE, oldPos[1]],
                location: `${SPRITE_SIZE * walkingIndex}px ${SPRITE_SIZE *
                    3}px`,
            }
        case 'SOUTH':
            return {
                postion: [oldPos[0] + SPRITE_SIZE, oldPos[1]],
                location: `${SPRITE_SIZE * walkingIndex}px ${SPRITE_SIZE *
                    0}px`,
            }
        case 'WEST':
            return {
                postion: [oldPos[0], oldPos[1] - SPRITE_SIZE],
                location: `${SPRITE_SIZE * walkingIndex}px ${SPRITE_SIZE *
                    2}px`,
            }
        case 'EAST':
            return {
                postion: [oldPos[0], oldPos[1] + SPRITE_SIZE],
                location: `${SPRITE_SIZE * walkingIndex}px ${SPRITE_SIZE *
                    1}px`,
            }
        default:
            return {
                postion: [0, 0],
                location: '0px 0px',
            }
    }
}

export const random = max => Math.floor(Math.random() * Math.floor(max))

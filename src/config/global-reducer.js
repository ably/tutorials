const isPlaying = JSON.parse(localStorage.getItem('isPlaying'))
const initialState = {
    isPlaying: isPlaying || false,
}


export default (state = initialState, { type, payload }) => {
    switch (type) {
        case 'PLAY':
            return { ...payload }
        default:
            return state
    }
}


const initialTimeState = {
    timer: 0
}

export const timeReducer = (state = initialTimeState, { type, payload }) => {
    switch (type) {
        case 'TIMER':
            return { ...payload }
        default:
            return state
    }
}

const username = localStorage.getItem('username')
const initialUserState = {
    username: username || ''
}

export const userReducer = (state = initialUserState, { type, payload }) => {
    switch (type) {
        case 'USERNAME':
            return { ...payload }
        default:
            return state
    }
}


const initialMemberState = {
    members: [] 
}

export const membersReducer = (state = initialMemberState, { type, payload }) => {
    switch (type) {
        case 'MEMBERS_PRESENCE':
            return { ...payload }
        default:
            return state
    }
}

const initialGameState = {
    endGame: false
}

export const endGameReducer = (state = initialGameState, { type, payload }) => {
    switch (type) {
        case 'END_GAME':
            return { ...payload }
        default:
            return state
    }
}

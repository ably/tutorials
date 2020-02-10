const score  = JSON.parse(localStorage.getItem('score'))
const level =  JSON.parse(localStorage.getItem('level'))

const initialState = {
    score: score || 0,
    level: level || 0,
}

export default (state = initialState, { type, payload }) => {
    switch (type) {
        case 'UPDATE_SCORE':
            return { ...payload }
        default:
            return state
    }
}

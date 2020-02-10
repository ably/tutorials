const initialState = {
    tiles: [],
}

export default (state = initialState, { type, payload }) => {
    switch (type) {
        case 'ADD_TILES':
            return { ...payload }

        default:
            return state
    }
}

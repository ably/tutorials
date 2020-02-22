import { createStore, combineReducers } from 'redux'
import playerReducer from '../feature/player/reducer'
import mapReducer from '../feature/map/reducer'
import controllReducer from '../feature/navigation/reducer'
import globalReducer, { timeReducer, userReducer, membersReducer, endGameReducer } from './global-reducer'

const appReducer = combineReducers({
    player: playerReducer,
    map: mapReducer,
    control: controllReducer,
    global: globalReducer,
    timing: timeReducer,
    user: userReducer,
    members: membersReducer,
    endGame: endGameReducer
})

const rootReducer = (state, action) => {
    return appReducer(state, action)
}

const store = createStore(
    rootReducer,
    window.__REDUX_DEVTOOLS_EXTENSION__ && window.__REDUX_DEVTOOLS_EXTENSION__()
)

export default store

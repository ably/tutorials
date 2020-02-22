import React from 'react'
import World from './feature/world'
import Scoreboard from './feature/scoreboard'
import { Switch, Route, BrowserRouter as Router } from 'react-router-dom'

function App() {
    //const match = useRouteMatch()
    return (
        <Router>
            <div>
                <Switch>
                    <Route path="/scoreboard">
                        <Scoreboard />
                    </Route>
                    <Route path="/">
                        <main className="arcade">
                            <h1 className="arcade-top">FaaS-T DELIVERY!</h1>
                            <div className="arcade-back">
                                <World />
                            </div>
                            <a href="/scoreboard" rel="noopener noreferrer nofollow" target="_blank" className="base">Go to alerts dashboard</a>
                        </main>
                    </Route>
                </Switch>
            </div>
        </Router>
    )
}

export default App

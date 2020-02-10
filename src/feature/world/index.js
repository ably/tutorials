import React from 'react'
import Popup from '../popup'
import Player from '../player'
import Map from '../map'
import store from '../../config/store'
import '../../index.css'

const World = () => {
    const username = store.getState().user.username
    
    return (
        <div className="world">
            {!username ? (
                <Popup />
            ) : (
                <>
                    <Map />
                    <Player />
                </>
            )}
        </div>
    )
}

export default World

import React, { useEffect } from 'react'
import { connect } from 'react-redux'
import { SPRITE_SIZE, MAP_WIDTH, MAP_HEIGHT } from '../constants'
import { getSpriteTile } from '../../util'
import { tiles } from '../../data/maps'
import store from '../../config/store'
import './index.css'

const MapTiles = props => {
    return (
        <div
            className={`tile ${getSpriteTile(props.value)}`}
        />
    )
}
const MapRow = props => {
    return (
        <div className="row" style={{ height: SPRITE_SIZE }}>
            {props.tiles.map((tile, index) => (
                <MapTiles key={index} value={tile} />
            ))}
        </div>
    )
}

const Map = props => {
    useEffect(() => {
        store.dispatch({
            type: 'ADD_TILES',
            payload: { tiles },
        })
        if (props.endGame) {
            localStorage.clear()
        }
    }, [props.score, props.endGame])

    return (
        <div
            style={{
                position: 'relative',
                top: '0px',
                left: '0px',
                width: MAP_WIDTH,
                height: MAP_HEIGHT,
            }}
        >
            {!props.endGame &&
                props.tiles[props.level] &&
                props.tiles[props.level].map((row, index) => (
                    <MapRow key={index} tiles={row} />
                ))}
            {props.endGame && (
                <h1 className="end">
                    Game Over! <span className="end-text">You've reached the end of your shift :)</span>
                </h1>
            )}
        </div>
    )
}

const mapStateToProps = state => {
    return {
        level: state.control.level,
        tiles: state.map.tiles,
        score: state.control.score,
        isPlaying: state.global.isPlaying,
        timer: state.timing.timer,
        endGame: state.endGame.endGame,
    }
}

export default connect(mapStateToProps)(Map)

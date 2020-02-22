import React, { useEffect } from 'react'
import './index.css'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import {
    faPlay,
    faPause,
    faClock,
    faRedo,
    faInfo,
    faFeather,
    faCrown,
    faWalking,
} from '@fortawesome/free-solid-svg-icons'
import { connect } from 'react-redux'
import store from '../../config/store'

const Navigation = props => {
    const handleClick = () => {
        props.dispatch({
            type: 'PLAY',
            payload: { isPlaying: !props.isPlaying },
        })
        window.localStorage.setItem('isPlaying', !props.isPlaying)
    }

    useEffect(() => {
        let timer = store.getState().timing.timer
        const doInterval = () => {
            if (props.isPlaying) {
                store.dispatch({
                    type: 'TIMER',
                    payload: {
                        timer,
                    },
                })
            }
            const isPlaying = store.getState().global.isPlaying
            if (!isPlaying) {
                stopInterval()
            }
            const isComplete = JSON.parse(localStorage.getItem('isComplete'))
            if (isComplete) {
                window.localStorage.setItem('isComplete', false)
                console.log('Is complete ran', timer)
                timer = 0
                store.dispatch({
                    type: 'TIMER',
                    payload: {
                        timer: 0,
                    },
                })
            }
            timer++
        }

        const interval = setInterval(doInterval, 1000)

        const stopInterval = () => {
            clearInterval(interval)
        }
    }, [props.isPlaying])

    return (
        <div className="wrapper">
            <div className="inner-wrapper">
                {props.username && (
                    <button
                        onClick={() => handleClick()}
                    >
                        {props.isPlaying ? (
                            <FontAwesomeIcon icon={faPause} />
                        ) : (
                            <FontAwesomeIcon icon={faPlay} />
                        )}
                    </button>
                )}
                {props.isPlaying && (
                    <button onClick={() => window.location.reload(false)}>
                        <FontAwesomeIcon icon={faRedo} />
                    </button>
                )}
                <button>
                    <FontAwesomeIcon icon={faInfo} />
                </button>
                <div className="div">
                    <span>
                        <FontAwesomeIcon icon={faClock} />
                    </span>
                    <span>{props.timer}</span>
                </div>
                <div className="div">
                    <span>
                        <span>
                            <FontAwesomeIcon icon={faCrown} />
                        </span>
                    </span>
                    <span>{props.score}</span>
                </div>
                <div className="div">
                    <span>
                        <span>
                            <FontAwesomeIcon icon={faWalking} />
                        </span>
                    </span>
                    <span>{props.steps}/60</span>
                </div>
                <div className="div">
                    <span>
                        <FontAwesomeIcon icon={faFeather} />
                    </span>
                    <span>LV. {props.level + 1}</span>
                </div>
            </div>
        </div>
    )
}

const mapStateToProps = state => ({
    score: state.control.score,
    level: state.control.level,
    isPlaying: state.global.isPlaying,
    timer: state.timing.timer,
    steps: state.player.steps,
    username: state.user.username,
})

export default connect(mapStateToProps)(Navigation)

import React from 'react'
import './index.css'
import { connect } from 'react-redux'
const Popup = props => {
    const submitUserDetails = () => {
            props.dispatch({
                type: 'USERNAME',
                payload: {
                    username: "player",
                },
            })
        localStorage.setItem('username', "player")
        window.location.reload(true)
    }

    return (
        <div className="pop-wrapper">
            <h5>Use the arrow keys to drive to the mailboxes to deliver your parcels</h5>
            <br />
            <button onClick={submitUserDetails}>
                Play!
            </button>
        </div>
    )
}

const mapStateToProps = state => ({
    ...state.user,
})

export default connect(mapStateToProps)(Popup)

import React from 'react'
import { Realtime } from 'ably/browser/static/ably-commonjs.js'
import '../../index.css'

class Scoreboard extends React.Component {
    constructor() {
        super();
        this.scoreboard = [];
        console.log("subscribing to ably");
        
        const ably = new Realtime('<API_KEY>')
        ably.connection.on('connected', () => {
            console.log('Successfully connected!')
            
            const inboundChannel = ably.channels.get('cloudflare-bot');
            inboundChannel.subscribe(message => {
                console.log(message.data.playerSteps);
                   
                if(typeof message === 'undefined') return;
                if(typeof message.data === 'undefined') return;
                if(message.data.length === 0) return;

                this.scoreboard.push(message.data.playerSteps);
                this.setState(this.scoreboard);
            })
        })
    }
    render() {
        return (
            <main className="scoreboard">
                <h1 className="scoreboard-title">Dashboard</h1>
                <ul className="scoreboard-list">
                    {
                        this.scoreboard.map((value, i) => {
                            console.log(value);
                        return <li className="scoreboard-item" key={i}>Parcel delivered in {value} steps</li>
                        })
                    }
                </ul>
            </main>
        )
    }
}

export default Scoreboard

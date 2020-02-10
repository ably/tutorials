import { Realtime } from 'ably/browser/static/ably-commonjs.js'
import { ABLY_API_KEY } from './key'

window.Ably = new Realtime(ABLY_API_KEY)
import * as Ably from 'ably'
//TODO: Replace <PRIVATE_API_KEY> with the API_KEY obtained from your Ably's Dashboard
export const ABLY_API_KEY = '<PRIVATE_API_KEY>'
export const ably = new Ably.Realtime(`${ABLY_API_KEY}`)

import { publishToAbly, jsonResponse, parseDataBody } from '../util/ably'
export default async request => {
    //TODO: Add Cloudflare Script
    try {
        const body = await request.text()
        const data = JSON.parse(body)
        const incomingPublisedData = parseDataBody(data)
        if (data) {
                const ably = await publishToAbly({
                    key: '1Mp0GA.sk52-w:0wBfApEvp7mnSI49',
                    data: incomingPublisedData,
                })

                return jsonResponse(ably, 'delivered')
        }
        return jsonResponse(null, 'Request Body cannot be empty!')
    } catch (error) {
        return new Response(error, { status: 500 })
    }
}

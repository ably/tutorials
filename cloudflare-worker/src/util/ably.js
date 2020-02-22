/**
 *
 * @param {{key: string, data: any, channel: string}} query
 * @returns Promsie fetch API responses.json()
 */
export const publishToAbly = async query => {
    try {
        const { key, data } = query

        const URL = `https://rest.ably.io/channels/cloudflare-bot/messages?envolped=false&key=${key}`
        const request = await fetch(`${URL}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                data
            }),
        })
        console.log('Publishin', data)

        return await request.json()
    } catch (error) {
        return error
    }
}

export const retriveMessages = async query => {
    try {
        const { key, channel } = query
        const URL = `https://rest.ably.io/channels/${channel}/messages?key=${key}`
        const request = await fetch(`${URL}`)
        return await request.json()
    } catch (error) {
        return await error
    }
}

export const channelId = length => {
    var result = ''
    var characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    var charactersLength = characters.length
    for (var i = 0; i < length; i++) {
        result += characters.charAt(
            Math.floor(Math.random() * charactersLength)
        )
    }
    return result
}


export const jsonResponse = (data, message) =>{
  return  new Response(
        JSON.stringify({
            data,
            message: message
        }),
        {
            headers: {
                'Content-type': 'application/json',
                status: 200,
            },
        }
    )
}

export const parseDataBody = data => {
    return JSON.parse(data.messages[0].data)
}
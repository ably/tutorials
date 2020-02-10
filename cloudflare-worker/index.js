import { parseDataBody } from 'ably'
const key = 'YOUR_API_KEY_HERE'; // Replace with your Ably API key!

addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
    try {
        const body = await request.text();   // Get the body from the response
        const data = JSON.parse(body);       // Parse body to JavaScript object
        
        if (!data) {
            return jsonResponse(null, 'Request Body cannot be empty!');
        }

        // Unpack the stringified message we're posting from our HTML game 
        const incomingPublisedData = parseDataBody(data);

        // Call Ably REST API to publish message
        await publishToAbly(incomingPublisedData);

        // Return a response from the Cloudflare function
        // This response is discarded in this example.
        return new Response ("OK");

    } catch (error) {
        return new Response(error, { status: 500 });
    }
}


async function publishToAbly(data) {
    try {
        const URL = `https://rest.ably.io/channels/cloudflare-bot/messages?key=${key}`
        
        await fetch(`${URL}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ data })
        });

    } catch (error) {
        return error
    }
}

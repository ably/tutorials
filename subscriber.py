#pip3 install sseclient-py - install the sseclient
import json
import sseclient

apiKey = 'INSERT_API_KEY_HERE'

if 'INSERT' in apiKey:
    print("Please replace your API key")
    exit()
channels = 'date-channel,time-channel'
url = 'https://realtime.ably.io/sse?v=1.1&key=%s&channels=%s' % (apiKey, channels)

def with_urllib3(url):
    """Get a streaming response for the given event feed using urllib3."""
    import urllib3
    http = urllib3.PoolManager()
    return http.request('GET', url, preload_content=False)

response = with_urllib3(url)  
client = sseclient.SSEClient(response)
for event in client.events():
    message = json.loads(event.data)
    print("Channel: %s  - Message: %s  - %s " % (message['channel'], message['name'], message['data']))
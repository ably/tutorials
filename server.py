from __future__ import unicode_literals
from ably import AblyRest
import web
import json

raise RuntimeError('Insert your API key')  # REMOVE THIS

client = AblyRest('{{ApiKey}}')


class index:
    def GET(self):
        html = open('index.html')
        return html.read()


class auth:
    def GET(self):
        web.header('Content-Type', 'application/json')
        return json.dumps(client.auth.create_token_request().to_dict())


urls = (
    '/', index,
    '/auth', auth
)

app = web.application(urls, globals())

if __name__ == "__main__":
    app.run()

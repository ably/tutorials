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
        username = web.cookies().get('username')
        if username is not None:
            token_params = {
                'capability': {
                    '*': ['publish', 'subscribe']
                },
                'client_id': username
            }
        else:
            token_params = {
                'capability': {
                    'notifications': ['subscribe']
                }
            }
        web.header('Content-Type', 'application/json')
        return json.dumps(client.auth.create_token_request(token_params).to_dict())


class login:
    def GET(self):
        username = web.input().get('username')
        if username is not None:
            web.setcookie('username', username)
            raise web.seeother('/')
        else:
            raise web.InternalError('Username is required to login')


class logout:
    def GET(self):
        web.setcookie('username', None, -1)
        raise web.seeother('/')


urls = (
    '/', index,
    '/auth', auth,
    '/login', login,
    '/logout', logout
)

app = web.application(urls, globals())

if __name__ == "__main__":
    app.run()

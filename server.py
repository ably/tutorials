from __future__ import unicode_literals
from ably import AblyRest
import web

raise RuntimeError('Insert your API key')  # REMOVE THIS

client = AblyRest('{{ApiKey}}')


class index:
    def GET(self):
        return 'Hello, I am a very simple server'


urls = (
    '/', index
)

app = web.application(urls, globals())

if __name__ == "__main__":
    app.run()

from __future__ import unicode_literals
from ably import AblyRest
import web

apiKey = '{{ApiKey}}'

if 'ApiKey' in apiKey:
    raise RuntimeError('Insert your API key')

client = AblyRest(apiKey)

render = web.template.render('templates/')


class index:
    def GET(self):
        return render.index(apiKey)


urls = (
    '/', index
)

app = web.application(urls, globals())

if __name__ == "__main__":
    app.run()

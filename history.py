from __future__ import unicode_literals
from ably import AblyRest

raise RuntimeError('Insert your API key')  # REMOVE THIS

client = AblyRest('{{ApiKey}}')

print('Instancing channel...')

channel = client.channels.get('persisted:sounds')

print('Publishing messages...')

channel.publish('play', 'bark')
channel.publish('play', 'meow')
channel.publish('play', 'cluck')

print('Retrieving messages...')

paginatedResult = channel.history()

for message in paginatedResult.items:
    print('Last message published: {}'.format(message.data))

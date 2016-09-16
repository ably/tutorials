from __future__ import unicode_literals
from ably import AblyRest

client = AblyRest('{{ApiKey}}')

print('Retrieving channel...')

channel = client.channels.get('persisted:sounds')

print('Publishing messages...')

channel.publish('play', 'bark')
channel.publish('play', 'meow')
channel.publish('play', 'cluck')

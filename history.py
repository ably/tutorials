from __future__ import unicode_literals
from ably import AblyRest

client = AblyRest('{{ApiKey}}')

print('Retrieving channel...')

channel = client.channels.get('persisted:sounds')

print('Publishing messages...')

channel.publish('play', 'bark')
channel.publish('play', 'meow')
channel.publish('play', 'cluck')

print('Releasing channel...')
# this part is only for tutorial purposes, in real you can use same instance of $channel
del channel
client.channels.release('persisted:sounds')

print('Retrieving channel...')

channel = client.channels.get('persisted:sounds')

print('Retrieving messages...')

paginatedResult = channel.history()

for message in paginatedResult.items:
    print('Last message published: {}'.format(message.data))

import { useState, useEffect } from 'react'
import { useNetInfo } from '@react-native-community/netinfo'
import { ably } from '../env'
import * as Location from 'expo-location'
import * as Permissions from 'expo-permissions'

export const useAblyChannel = (channel, dependencies) => {
  //set HUB_STREAM  channel
  const HUB_STREAM =
    '[product:ably-flightradar24/heathrow-flights]flights:airport:LHR'

  //const netInfo = useNetInfo()

  const [onMessage, setOnMessage] = useState('Please wait..')

  // set ably connection
  const [isConnected, setConnection] = useState(false)
  const [isLoading, setLoading] = useState(true)
  //fetch channel data
  const [channelData, setChannelData] = useState(null)

  useEffect(() => {
    console.log('Ran Use Effects', channel)
    ably.connection.on(function(stateChange) {
      console.log('New connection state is ' + stateChange.current)
      setOnMessage(stateChange.current)
      setLoading(true)
    })

    const useChannel = ably.channels.get(`${HUB_STREAM}:${channel}`)
    useChannel.subscribe(message => {
      if (message.data.length > 0) {
        setOnMessage('Loading Data...')
        setLoading(false)
        setChannelData(message.data)
      }
    })
  }, [])

  return [isConnected, isLoading, onMessage, channelData]
}

export const geoLocationHook = dependencies => {
  const [geoLoading, setGeoLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState(null)
  const [location, setLocation] = useState(null)

  useEffect(() => {
    Permissions.askAsync(Permissions.LOCATION)
      .then(status => {
        Location.getCurrentPositionAsync({}).then(_location => {
          setLocation(_location)
          setGeoLoading(false)
        })
      })
      .catch(err => {
        setErrorMessage(err)
      })
  }, dependencies)

  //console.log()
  return [location, geoLoading, errorMessage]
}

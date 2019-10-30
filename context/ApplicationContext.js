import React, { useState } from 'react'
import Context from './context'
import { ably } from '../env'

const HUB_STREAM = '[product:ably-flightradar24/heathrow-flights]flights:plane'

export default ApplicationContext = ({ children }) => {
  const [arrivals, setArrivalsData] = useState(null)

  const [isLoading, setIsLoading] = useState(true)

  const [departures, setDeparturesData] = useState(null)

  const setChannel = iATA => {
    console.log(`This ${iATA} was clicked`)
    return ably.channels.get(`${HUB_STREAM}:${iATA}`)
  }

  const departureListener = message => {
    console.log('Still Listening Departure', message.data)
    message.data && setIsLoading(false) || setDeparturesData(message.data)
  }

  const arrivalListener = message => {
    console.log('Still Listening', message.data)
    message.data && setIsLoading(false) || setArrivalsData(message.data)
  }

  const unsubscribe = (useChannel, type) => {
    console.log(`unmounting sub ${type}`)
    useChannel.off()
    useChannel.unsubscribe()
    type === 'arrival' ? setArrivalsData(null) : setDeparturesData(null)
    setIsLoading(true)
  }

  const setArrivals = (iATA, action) => {
    action === 'reset'
      ? unsubscribe(setChannel(iATA), 'arrival')
      : setChannel(iATA).subscribe(arrivalListener)
  }

  const setDepartures = (iATA, action) => {
    action === 'reset'
      ? unsubscribe(setChannel(iATA), 'departure')
      : setChannel(iATA).subscribe(departureListener)
  }

  return (
    <Context.Provider
      value={{
        arrivals,
        departures,
        isLoading,
        setIsLoading,
        setArrivals,
        setDepartures
      }}
    >
      {children}
    </Context.Provider>
  )
}

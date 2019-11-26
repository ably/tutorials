import React, { useState } from 'react'
import Context from './context'
import { ably } from '../env'

const HUB_STREAM = '<HUB_API_STREAM_CHANNEL>'

export default ApplicationContext = ({ children }) => {
  const [arrivals, setArrivalsData] = useState(null)

  const [isLoading, setIsLoading] = useState(true)

  const [departures, setDeparturesData] = useState(null)

  //add subscrpition listeners here 
  
  
  // add unsubscribe listeners here

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

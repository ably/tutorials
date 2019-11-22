import React from 'react'

export default React.createContext({
  arrivals: {},
  departures: {},
  isLoading: true,
  setIsLoading: isLoading => {},
  setArrivals: (arrivals, action) => {},
  setDepartures: (departures, action) => {}
})

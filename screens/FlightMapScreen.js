import React, { useContext, useEffect } from 'react'
import context from '../context/context'
import FlightDashboard from '../components/FlightDashboard'

export default FlightMapScreen = ({ navigation }) => {
  const {
    arrivals,
    departures,
    setArrivals,
    setDepartures
  } = useContext(context)

  const handleClose = () => {
    arrivals
      ? navigation.navigate('Arrivals')
      : navigation.navigate('Departure')
  }

  useEffect(() => {
    return () => {
      console.log('unmounted!')
      arrivals
        ? setArrivals(arrivals.iataId, 'reset')
        : setDepartures(departures.iataId, 'reset')
    }
  }, [])

  return (
    <>
      {arrivals ? (
        <FlightDashboard data={arrivals} handleClose={() => handleClose()} />
      ) : (
        <FlightDashboard data={departures} handleClose={() => handleClose()} />
      )}
    </>
  )
}

FlightMapScreen.navigationOptions = {
  header: null
}
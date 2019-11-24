import React, { useContext, useEffect } from 'react'
import { Text, View, ActivityIndicator } from 'react-native'
import ApplicationContext from '../context/context'
import { Button } from 'native-base'

export default PopModal = ({ navigation }) => {
  const {
    setArrivals,
    isLoading,
    arrivals,
    departures,
    setDepartures
  } = useContext(ApplicationContext)

  let reset = true
  const iataId = navigation.getParam('iataId')
  const action = navigation.getParam('action')
  useEffect(() => {
    return () => {
      reset = false
      action === 'arrival'
        ? setArrivals(`${iataId}`, 'reset')
        : setDepartures(`${iataId}`, 'reset')
      navigation.setParams({ action: 'reset' })
    }
  }, [])

  const handleGoBackHome = (arrival, departure) => {
    navigation.navigate('FlightMap', { arrival, departure })
  }

  const handleCancel = () => {
    navigation.goBack()
  }

  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      {reset && isLoading ? (
        <>
          {action === 'arrival' && setArrivals(`${iataId}`, null)}
          {action === 'departure' && setDepartures(`${iataId}`, null)}
          <ActivityIndicator size="large" color="#000" />
          <Text style={{ fontSize: 12 }}>Loading live location of {iataId} </Text>
        </>
      ) : (
        <View
          style={{
            flexDirection: 'row',
            alignItems: 'center',
            flexGrow: 1
          }}
        >
          <Button
            style={{ marginRight: 10 }}
            onPress={() => handleGoBackHome(arrivals, departures)}
            bordered
            dark
          >
            <Text style={{ padding: 10 }}>Launch Live Tracking?</Text>
          </Button>
          <Button
            style={{ marginLeft: 10 }}
            onPress={() => handleCancel()}
            bordered
            dark
          >
            <Text style={{ padding: 10 }}>Cancel</Text>
          </Button>
        </View>
      )}
    </View>
  )
}

PopModal.navigationOptions = {
  header: null
}

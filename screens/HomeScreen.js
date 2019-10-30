import React from 'react'
import { ActivityIndicator, View, StyleSheet } from 'react-native'

import MapView, { PROVIDER_GOOGLE, Marker } from 'react-native-maps'

import { geoLocationHook } from '../hooks/ably.hooks'

export default HomeScreen = ({ navigation }) => {
  const [location, geoLoading] = geoLocationHook([])

  return (
    <View style={styles.container}>
      {!geoLoading ? (
        <MapView
          provider={PROVIDER_GOOGLE}
          style={styles.map}
          initialRegion={{
            latitude: location.coords.latitude,
            longitude: location.coords.longitude,
            latitudeDelta: 0.0922,
            longitudeDelta: 0.0421
          }}
        >
          <Marker
            coordinate={{
              latitude: location.coords.latitude,
              longitude: location.coords.longitude
            }}
            pinColor="#000"
          />
        </MapView>
      ) : (
        <ActivityIndicator
          size="large"
          style={{ flex: 1, justifyContent: 'center' }}
          color="#000"
        />
      )}
    </View>
  )
}

HomeScreen.navigationOptions = {
  header: null
}

const styles = StyleSheet.create({
  map: {
    ...StyleSheet.absoluteFillObject
  },
  container: {
    flex: 1,
    backgroundColor: '#fff'
  }
})

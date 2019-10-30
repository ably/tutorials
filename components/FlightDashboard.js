import React, { useEffect } from 'react'
import { View, Text, Dimensions } from 'react-native'
import ListIcons from './ListIcons'
import { Button } from 'native-base'
import MapView, { PROVIDER_GOOGLE, Polyline, Marker } from 'react-native-maps'
import { Ionicons } from '@expo/vector-icons'
import { styles } from './styles'

const { width, height } = Dimensions.get('window')

const ASPECT_RATIO = width / height

const LATITUDE_DELTA = 0.0022
const LONGITUDE_DELTA = 0.0421

const coordinates = []
export default FlightDashboard = ({ handleClose, data }) => {
  useEffect(() => {
    coordinates.push({ latitude: data.lat, longitude: data.long })
  }, [data])

  return (
    <View style={styles.container}>
      <MapView
        ref={ref => (map = ref)}
        provider={PROVIDER_GOOGLE}
        style={styles.map_view}
        initialRegion={{
          latitude: data.lat,
          longitude: data.long,
          latitudeDelta: LATITUDE_DELTA,
          longitudeDelta: LONGITUDE_DELTA
        }}
        mapType="mutedStandard"
      >
        {coordinates.length > 0 && (
          <>
            <Marker
              identifier="flight"
              coordinate={{ latitude: data.lat, longitude: data.long }}
              pinColor="#FFF"
              tracksViewChanges={true}
            >
              <Ionicons
                name="ios-airplane"
                size={40}
                style={{ transform: [{ rotateZ: '-200deg' }] }}
              />
            </Marker>
            <Polyline
              coordinates={[...coordinates]}
              strokeColor="#000"
              strokeWidth={3}
            />
          </>
        )}
      </MapView>
      <View style={styles.dashboarWrap}>
        <View style={styles.dashboard}>
          <ListIcons icon="ios-airplane" text={data.airline} label="AIRL" />
          <ListIcons icon="ios-trending-up" text={data.long} label="LNG" />
          <ListIcons icon="ios-speedometer" text={data.speed} label="Speed" />
          <ListIcons icon="ios-trending-down" text={data.lat} label="LAT" />
          <ListIcons icon="ios-flash" text={data.iataId} label="IATAID" />
        </View>
        <Button
          onPress={() => handleClose()}
          style={styles.endButton}
          bordered
          dark
        >
          <Text style={{ textAlign: 'center' }}>End</Text>
        </Button>
      </View>
    </View>
  )
}

import React from 'react'
import { StyleSheet, Text, Button } from 'react-native'
import { Container, Thumbnail } from 'native-base'

export default HomeScreen = ({ navigation }) => {
  const uri =
    'https://specials-images.forbesimg.com/imageserve/5d54137895808800097cbe00/960x0.jpg?fit=scale'

  return (
    <Container style={styles.container}>
      <Thumbnail large source={{ uri }} style={{ alignSelf: 'center' }} />
      <Text style={{ textAlign: 'center', marginTop: 10, fontSize: 20 }}>
        Watch and Track Arrivals to and Departure
      </Text>
      <Text style={{ textAlign: 'center', fontSize: 20 }}>
        From London Heathrow Airport
      </Text>
      <Button
        onPress={() => {
          navigation.navigate('App')
        }}
        title="Start Flight Tracking Mode"
      />
    </Container>
  )
}

HomeScreen.navigationOptions = {
  header: null,
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    justifyContent: 'center',
  },
})

import React, { useEffect } from 'react'
import { Container, Text } from 'native-base'
import { StyleSheet } from 'react-native'

export default DepartureScreen = ({ navigation }) => {
  //TODO:

  useEffect(() => {
    console.log('Depature Mounted')
  }, [])

  return (
    <Container style={styles.container}>
      <Text style={styles.text}>
        Complete the Tutorial to see Departures Data
      </Text>
    </Container>
  )
}

DepartureScreen.navigationOptions = {
  title: 'Departures from London',
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 15,
    backgroundColor: '#fff',
  },
  text: {
    textAlign: 'center',
  },
})

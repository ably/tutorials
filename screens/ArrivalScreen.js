import React, { useEffect } from 'react'
import { StyleSheet } from 'react-native'
import { Container, Text } from 'native-base'

export default ArrivalScreen = ({ navigation }) => {
  // TODO:

  useEffect(() => {
    console.log('Arrival Mounted')
  }, [])

  return (
    <Container style={styles.container}>
      <Text style={styles.text}>Complete the Tutorial to see Arrival Data</Text>
    </Container>
  )
}

ArrivalScreen.navigationOptions = {
  title: 'Arrivals to London',
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

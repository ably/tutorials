import React from 'react'
import { View, Text, StyleSheet, Dimensions, ActivityIndicator } from 'react-native'

const { width, height } = Dimensions.get('window')

export default LoadingScreen = ({ message }) => {
  return (
    <View style={styles.container}>
      <ActivityIndicator size="large" color="#000" />
      <Text style={styles.message}>{message}</Text>
    </View>
  )
}

const styles = StyleSheet.create({
  message: {
    fontSize: 16,
    textAlign: 'center',
    margin: 10
  },

  container: {
    flex: 1,
    justifyContent: 'center'
  }
})

import React from 'react'
import { View, Text } from 'react-native'
import { Ionicons } from '@expo/vector-icons'

export default ListIcons = ({icon, text, label}) => {
  return (
    <View style={{ padding: 15 }}>
      <Ionicons name={icon} style={{ alignSelf: 'center' }} size={23} />
      <Text  style={{ alignSelf: 'center' }}>{text}</Text>
      <Text  style={{ alignSelf: 'center' }}>{label}</Text>
    </View>
  )
}


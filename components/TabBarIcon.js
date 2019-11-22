import React from 'react'
import { Ionicons } from '@expo/vector-icons'
import Colors from '../constants/Colors'

export default TabBarIcon = props => {
  return (
    <Ionicons
      name={props.name}
      size={27}
      style={{ transform: [{ rotateZ: `${props.rotate}` }] }}
      color={props.focused ? Colors.tabIconSelected : Colors.tabIconDefault}
    />
  )
}

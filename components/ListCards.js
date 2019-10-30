import React from 'react'
import { Card, CardItem, Body, Text, Left } from 'native-base'
import { Ionicons } from '@expo/vector-icons'

export const ListCards = ({ text, rotate, action }) => {
  const deg = rotate ? '45deg' : '-45deg'
  const color = rotate ? '#dbd81d' : '#7cbf80'

  const handleActions = action => {
    action()
  }

  return (
    <Card noShadow>
      <CardItem button onPress={() => handleActions(action)}>
        <Left>
          <Ionicons
            name="ios-airplane"
            size={30}
            color={color}
            style={{ transform: [{ rotateZ: `${deg}` }] }}
          />
          <Body style={{ display: 'flex' }}>
            <Text>{text}</Text>
          </Body>
        </Left>
      </CardItem>
    </Card>
  )
}

//#c27e7e
//#7cbf80

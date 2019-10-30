import React, { useState } from 'react'
import { StyleSheet } from 'react-native'
import { ListCards } from '../components/ListCards'
import { Container, Content, Fab, Icon, Button } from 'native-base'
import { useAblyChannel } from '../hooks/ably.hooks'

export default ArrivalScreen = ({ navigation }) => {
  const [active, setActive] = useState(false)
  const [
    isConnecting,
    isLoading,
    displayMessqage,
    channelData
  ] = useAblyChannel('arrivals', [])

  const Arrivals = channelData
    ? channelData.map((item, index) => {
        return (
          <ListCards
            key={index}
            text={`${item.origin} - ${item.destination} (${item.iataId})`}
            icon="ios-airplane"
            //action={() => setArrivals(`${item.iataId}`)}
            action={() =>
              navigation.navigate('PopModal', {
                iataId: item.iataId,
                action: 'arrival'
              })
            }
            rotate
          />
        )
      })
    : []

  return (
    <Container>
      {isLoading ? (
        <LoadingScreen message={displayMessqage} />
      ) : (
        <>
          <Content>{Arrivals}</Content>
          <Fab
            active={active}
            direction="up"
            containerStyle={{}}
            style={{ backgroundColor: '#000' }}
            position="bottomRight"
            onPress={() =>
              navigation.navigate('Search', {
                data: channelData,
                type: 'arrival',
                rotate: true
              })
            }
          >
            <Icon name="search" />
          </Fab>
        </>
      )}
    </Container>
  )
}

ArrivalScreen.navigationOptions = {
  title: 'Arrivals to London'
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 15,
    backgroundColor: '#fff'
  }
})

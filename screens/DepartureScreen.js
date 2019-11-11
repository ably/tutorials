import React, { useContext, useEffect } from 'react'
import { ListCards } from '../components/ListCards'
import { Container, Content, Fab, Icon } from 'native-base'
import LoadingScreen from '../components/LoadingScreen'
import { useAblyChannel } from '../hooks/ably.hooks'
import AppContext from '../context/context'
import FabButton from '../components/FabButton'

export default DepartureScreen = ({ navigation }) => {
  const [isConnecting, isLoading, displayMessage, channelData] = useAblyChannel(
    'depatures',
    []
  )

  useEffect(() => {
    console.log('Depature mounted')
  }, [])

  const Departures = channelData
    ? channelData.map((item, index) => {
        // console.log(channelData)
        return (
          <ListCards
            key={index}
            text={`${item.origin} - ${item.destination} (${item.iataId})`}
            icon="ios-airplane"
            action={() =>
              navigation.navigate('PopModal', {
                iataId: item.iataId,
                action: 'departure'
              })
            }
          />
        )
      })
    : []

  return (
    <Container>
      {isLoading ? (
        <LoadingScreen message={displayMessage} />
      ) : (
        <>
          <Content>{Departures}</Content>
          <FabButton navigation={navigation} channelData={channelData} />
        </>
      )}
    </Container>
  )
}

DepartureScreen.navigationOptions = {
  title: 'Departures from London'
}

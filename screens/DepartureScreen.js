import React, { useEffect } from 'react'
import { ListCards } from '../components/ListCards'
import { Container, Content } from 'native-base'
import LoadingScreen from '../components/LoadingScreen'
import { useAblyChannel } from '../hooks/ably.hooks'
import FabButton from '../components/FabButton'

export default DepartureScreen = ({ navigation }) => {
  const [isLoading, displayMessage, channelData] = useAblyChannel(
    'departures',
    []
  )

  useEffect(() => {
    console.log('Departure Component Mounted')
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
                action: 'departure',
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
          <FabButton
            navigation={navigation}
            channelData={channelData}
            type="departure"
          />
        </>
      )}
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

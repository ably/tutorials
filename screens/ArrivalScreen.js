import React, { useEffect } from 'react'
import { StyleSheet } from 'react-native'
import { ListCards } from '../components/ListCards'
import { Container, Content } from 'native-base'
import { useAblyChannel } from '../hooks/ably.hooks'
import FabButton from '../components/FabButton'

export default ArrivalScreen = ({ navigation }) => {
   const [isLoading, displayMessqage, channelData] = useAblyChannel(
     'arrivals',
     []
   )

   useEffect(() => {
     console.log('Arrival Component Mounted')
   }, [])

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
                 action: 'arrival',
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
           <FabButton
             navigation={navigation}
             channelData={channelData}
             type="arrival"
           />
         </>
       )}
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

import React, { useState } from 'react'
import {
  Button,
  Container,
  Header,
  Item,
  Icon,
  Input,
  Text,
  View
} from 'native-base'
import { ListCards } from './ListCards'

export default SearchModal = ({ navigation }) => {
  const [searchContent, setSearchContent] = useState(null)
  const data = navigation.getParam('data')
  const type = navigation.getParam('type')
  const rotate = navigation.getParam('rotate')

  const searchFlights = keyword => {
    const item = data.find(element => element.iataId === keyword)
    const renderSearch =
      item !== undefined ? (
        <ListCards
          text={`${item.origin} - ${item.destination} (${item.iataId})`}
          icon="ios-airplane"
          action={() =>
            navigation.navigate('PopModal', {
              iataId: item.iataId,
              action: type
            })
          }
          rotate={rotate}
        />
      ) : (
        <View style={{ justifyContent : "center" }}>
          <Text style={{textAlign : "center"}}>Sorry We Can't Find Your Search</Text>
        </View>
      )
    console.log(keyword, item)
    setSearchContent(renderSearch)
  }

  const handleCancel = () => {
    navigation.goBack()
  }

  return (
    <Container>
      <Header searchBar rounded>
        <Item>
          <Icon name="ios-search" />
          <Input
            placeholder="Enter an IATAID"
            onChange={e => searchFlights(e.nativeEvent.text.toUpperCase())}
          />
          <Icon name="ios-airplane" />
        </Item>
      </Header>
      {searchContent}
      <Button
        onPress={() => handleCancel()}
        dark
        bordered
        style={{
          marginTop: 20,
          marginBottom: 5,
          marginLeft: 10,
          marginRight: 10,
          justifyContent: 'center'
        }}
      >
        <Text>Close</Text>
      </Button>
    </Container>
  )
}

SearchModal.navigationOptions = {
  title: 'Search LHR Flights',
  headerLeft: null
}

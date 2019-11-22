import React, { useState } from 'react'
import { Fab, Button, Icon } from 'native-base'

const FabButton = ({ navigation, channelData }) => {
  const [active, setActive] = useState(false)

  return (
    <Fab
      active={active}
      direction="up"
      containerStyle={{}}
      style={{ backgroundColor: '#000' }}
      position="bottomRight"
      onPress={() => setActive(!active)}
    >
      <Icon name="more" />
      <Button
        style={{ backgroundColor: '#000' }}
        onPress={() =>
          navigation.navigate('Search', {
            data: channelData,
            type: 'arrival',
            rotate: true
          })
        }
      >
        <Icon name="search" fontSize={30} />
      </Button>
      <Button
        style={{ backgroundColor: '#000' }}
        onPress={() => navigation.navigate('Home')}
      >
        <Icon name="home" />
      </Button>
    </Fab>
  )
}

export default FabButton

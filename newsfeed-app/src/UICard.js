import React from 'react'
import { Card, Image, Segment } from 'semantic-ui-react'

function formatAMPM(date) {
  var hours = date.getHours();
  var minutes = date.getMinutes();
  var ampm = hours >= 12 ? 'PM' : 'AM';
  hours %= 12;
  hours = hours ? hours : 12;
  minutes = minutes < 10 ? '0' + minutes : minutes;
  var strTime = hours + ':' + minutes + ' ' + ampm;
  return strTime;
}

const UICard = (props) => {
  return (
    <Segment>
{props.events.map((event, index) => {
  return (
    <Card fluid key={index} index={index}>
      <Card.Content>
        <Image
          floated='right'
          size='mini'
          src={event.image}
        />
        <Card.Header>{event.name}</Card.Header>
        <Card.Meta>{formatAMPM(event.date)}</Card.Meta>
        <Card.Description>
          {event.summary}
        </Card.Description>
      </Card.Content>
    </Card>
     )
    })}
  </Segment>
)
  }

export default UICard
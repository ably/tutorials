import React, { useState, useEffect, useRef } from "react";
import * as Ably from "ably";
import {
  Container,
  Header,
  Divider,
  Button,
  Form,
  TextArea,
  Label
} from "semantic-ui-react";

import "./App.css";
import UICard from "./UICard";

// User avatars
const avatarsInAssets = [
  "https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_8.png?1536042504672",
  "https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_3.png?1536042507202",
  "https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_6.png?1536042508902",
  "https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_10.png?1536042509036",
  "https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_7.png?1536042509659",
  "https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_9.png?1536042513205",
  "https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_2.png?1536042514285",
  "https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_1.png?1536042516362",
  "https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_4.png?1536042516573",
  "https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_5.png?1536042517889"
];

// User names
const names = [
  "Ross",
  "Monica",
  "Rachel",
  "Joey",
  "Chandler",
  "Steve",
  "Bill",
  "Elon",
  "Tom",
  "Shaun"
];

// Get random
function getRandomArbitrary(min, max) {
  return Math.floor(Math.random() * (max - min) + min);
}

const myId =
  "id-" +
  Math.random()
    .toString(36)
    .substr(2, 16);
const apiKey = "<YOUR-API-KEY>";

// Ably Instance
const ably = new Ably.Realtime({
  key: apiKey,
  clientId: myId,
  echoMessages: false
});
const chatChannel = ably.channels.get("chat");
const presenceChannel = ably.channels.get("presence");
const metaChannel = ably.channels.get("[meta]channel.lifecycle");
let my = {};
my.avatar = avatarsInAssets[getRandomArbitrary(0, 9)];
my.name = names[getRandomArbitrary(0, 9)];

const App = () => {
  const scrollRef = useRef(null); // for getting scroll ref
  const [todoInput, setTodoInput] = useState(""); // User Input/Message
  const [state, setState] = useState({
    msgs: [],
    newMsgs: []
  }); // to hold all messages and incoming new messages
  const [onlineUsers, setOnlineUsers] = useState(0); // for online users

  let you = {};

  useEffect(() => {
    // Subscribing for userInfo details to assign name and avatar
    chatChannel.subscribe("userInfo", data => {
      var dataObj = JSON.parse(JSON.stringify(data));
      if (dataObj.clientId !== myId) {
        you.avatar = dataObj.data.avatar;
        you.name = dataObj.data.name;
      }
    });

    // When a new member joins publish it's userInfo details
    presenceChannel.presence.subscribe("enter", function(member) {
      if (member.clientId !== myId) {
        chatChannel.publish("userInfo", {
          avatar: my.avatar,
          name: my.name
        });
      }
    });

    presenceChannel.presence.enter();

    // Get all members and publish userInfo details
    presenceChannel.presence.get(function(err, members) {
      for (var i in members) {
        if (members[i].clientId !== myId) {
          chatChannel.publish("userInfo", {
            avatar: my.avatar,
            name: my.name
          });
        }
      }
    });

    // Subscribing for chatMessage
    chatChannel.subscribe("chatMessage", data => {
      var dataObj = JSON.parse(JSON.stringify(data));
      var message = dataObj.data.message;
      var date = new Date(dataObj.data.date);

      // Updating the state newMsgs with new incoming message
      setState(prevState => {
        return {
          ...prevState,
          newMsgs: [
            ...prevState.newMsgs,
            { summary: message, image: you.avatar, date: date, name: you.name }
          ]
        };
      });
    });

    // Using Channel Occupancy to get online users
    metaChannel.subscribe("channel.occupancy", msg => {
      var msgJSONobj = JSON.parse(JSON.stringify(msg.data));
      if (msgJSONobj.name === "chat") {
        // Update the state OnlineUsers
        setOnlineUsers(msgJSONobj.status.occupancy.metrics.connections);
      }
    });
  }, []);

  function sendMyMessage() {
    const newMsgId =
      "msg-id-" +
      Math.random()
        .toString(36)
        .substr(2, 6);
    setTodoInput("");
    if (todoInput !== "") {
      // Publishing the message
      chatChannel.publish("chatMessage", {
        message: todoInput,
        localMsgId: newMsgId,
        date: new Date()
      });

      // Updating the state msgs with the message of the current user and sorting
      setState(prevState => {
        return {
          ...prevState,
          msgs: [
            ...prevState.msgs,
            {
              summary: todoInput,
              image: my.avatar,
              date: new Date(),
              name: my.name
            }
          ].sort((a, b) => b.date - a.date)
        };
      });
    }
  }

  function getMessages() {
    // Updating the state with latest messages and sorting
    setState(prevState => {
      return {
        ...prevState,
        msgs: [...prevState.msgs, ...prevState.newMsgs].sort(
          (a, b) => b.date - a.date
        ),
        newMsgs: []
      };
    });

    // Scrolling to top for viewing new messages
    scrollRef.current.scrollTop = 0;
  }

  return (
    <Container textAlign="left" className="App-header">
      <Header as="h2">Ably React Tutorial - RealTime</Header>
      <Form>
        <TextArea
          value={todoInput}
          placeholder="Post an update"
          onChange={e => setTodoInput(e.target.value)}
        />
        <div className="App-button">
          <Button content="Send" primary onClick={sendMyMessage} />
        </div>
      </Form>
      <div className="App-users">
        {onlineUsers !== 0 && (
          <Label>
            User{onlineUsers === 1 ? "" : "s"} Online - {onlineUsers.toString()}
          </Label>
        )}
      </div>
      <Divider />
      <div onClick={getMessages} className="App-update">
        {state.newMsgs.length !== 0 && (
          <Label>
            {state.newMsgs.length.toString()} new update
            {state.newMsgs.length === 1 ? "" : "s"} have arrived!
          </Label>
        )}
      </div>
      {state.msgs.length !== 0 && (
        <div ref={scrollRef} className="App-cards">
          <UICard events={state.msgs} />
        </div>
      )}
    </Container>
  );
};

export default App;

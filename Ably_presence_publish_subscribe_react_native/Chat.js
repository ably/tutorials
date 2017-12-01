/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from "react";
import { StyleSheet, View, AsyncStorage } from "react-native";

var realtime = require("ably").Realtime;
var ably, channel;

export default class Chat extends Component<{}> {
  constructor(props) {
    super(props);
    this.state = {
      user: "",
      msg: [],
      txt: "",
      usersCount: 0
    };
  }

  componentDidMount = () => {
    AsyncStorage.getItem("user")
      .then(value => {
        this.setState({ user: value });
        this.subscribe();
      })
      .done();
  };

  subscribe = () => {
    ably = new realtime({
      key: "Ecaj0g.JZ8Xqg:eX0US8u7zENvxfvA",
      clientId: this.state.user
    });
    channel = ably.channels.get("cog-tie");
    channel.presence.subscribe("enter", member => {
      var data = {
        msg: "joined the chat",
        user: member.clientId,
        action: "joined"
      };

      var newmsg = this.state.msg;

      newmsg.push(data);

      channel.presence.get((err, members) => {
        this.setState({ msg: newmsg, usersCount: members.length });
      });
    });

    channel.presence.subscribe("leave", member => {
      var data = {
        msg: "left the chat",
        user: member.clientId,
        action: "left"
      };

      var newmsg = this.state.msg;

      newmsg.push(data);

      channel.presence.get((err, members) => {
        this.setState({ msg: newmsg, usersCount: members.length });
      });
    });

    channel.presence.enter();

    channel.subscribe("message", msg => {
      var newmsg = this.state.msg;

      newmsg.push(msg.data);

      this.setState({ msg: newmsg, txt: "" });
    });
  };

  render = () => {
    return <View style={styles.container} />;
  };
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#F5FCFF",
    paddingTop: 10
  }
});

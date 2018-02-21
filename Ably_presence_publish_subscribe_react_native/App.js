/**
* Sample React Native App
* https://github.com/facebook/react-native
* @flow
*/
import React, { Component } from "react";
import Chat from "./Chat";
import { StyleSheet, View, Text, TextInput, Button, AsyncStorage } from "react-native";

export default class App extends Component<{}> {
  constructor(props) {
    super(props);
    this.state = { txt: "", user: null };
    this.handler = this.handler.bind(this);
  }

  componentDidMount = () => {
    AsyncStorage.getItem("user")
      .then(value => {
        this.setState({ user: value });
      })
      .done();
  };
  submitName = () => {
    AsyncStorage.setItem("user", this.state.txt);
    this.setState({ user: this.state.txt });
  };

  handler = () => {
    this.setState({
      user: null
    });
  };
  getRender = () => {
    if (this.state.user != null) {
      return <Chat handler={this.handler} />;
    } else {
      return (
        <View style={styles.container}>
          <Text style={{ alignItems: "center" }}>
            Please Give us a name to join the chat with
          </Text>
          <View
            style={{
              flexWrap: "wrap",
              alignItems: "center",
              flexDirection: "row"
            }}
          >
            <TextInput
              value={this.state.txt}
              style={{ width: "80%" }}
              placeholder="Enter Your message!"
              onChangeText={txt => this.setState({ txt })}
            />

            <Button
              style={{ width: "20%" }}
              onPress={this.submitName}
              title="Send"
              color="#841584"
            />
          </View>
        </View>
      );
    }
  };

  render = ()=> {
    return this.getRender();
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#F5FCFF"
  }
});

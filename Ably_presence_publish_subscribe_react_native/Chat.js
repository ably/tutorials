/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */
import React, { Component } from "react";
import { StyleSheet, View } from "react-native";
export default class Chat extends Component<{}> {
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

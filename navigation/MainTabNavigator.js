import React from 'react'
import { Platform } from 'react-native'
import {
  createStackNavigator,
  createBottomTabNavigator
} from 'react-navigation'

import TabBarIcon from '../components/TabBarIcon'
import HomeScreen from '../screens/HomeScreen'
import ArrivalScreen from '../screens/ArrivalScreen'
import DepartureScreen from '../screens/DepartureScreen'
import PopModal from '../components/PopModal'
import FlightMapScreen from '../screens/FlightMapScreen'
import SearchModal from '../components/SearchModal'

const config = Platform.select({
  web: { headerMode: 'screen' },
  default: {}
})

const navigateRoute = (navigation, label, rotate) => {
  let tabBarVisible
  if (navigation.state.routes.length > 1) {
    navigation.state.routes.map(route => {
      if (route.routeName === 'FlightMap') {
        tabBarVisible = false
      } else {
        tabBarVisible = true
      }
    })
  }

  return {
    tabBarVisible,
    tabBarLabel: label,
    tabBarIcon: ({ focused }) => (
      <TabBarIcon
        focused={focused}
        name={Platform.OS === 'ios' ? 'ios-airplane' : 'md-airplane'}
        rotate={rotate}
      />
    ),
    tabBarOptions: { activeTintColor: '#000' }
  }
}

const HomeStack = createStackNavigator(
  {
    Home: HomeScreen
  },
  config
)

HomeStack.navigationOptions = {
  tabBarLabel: 'Home',
  tabBarIcon: ({ focused }) => (
    <TabBarIcon
      focused={focused}
      name={Platform.OS === 'ios' ? `ios-home` : 'md-home'}
      rotate="0deg"
    />
  ),
  tabBarOptions: { activeTintColor: 'black' }
}

HomeStack.path = ''

const FlightMapStack = createStackNavigator(
  {
    FlightMap: FlightMapScreen
  },
  config
)

FlightMapStack.navigationOptions = {
  tabBarLabel: 'Flight Map',
  tabBarOptions: { activeTintColor: '#000' }
}

const ArrivalStack = createStackNavigator(
  {
    Arrivals: ArrivalScreen,
    PopModal: PopModal,
    Search: SearchModal,
    FlightMap: FlightMapScreen
  },
  {
    mode: 'modal'
  }
)

/* ArrivalStack.navigationOptions = {
  tabBarLabel: 'Arrivals',
  tabBarIcon: ({ focused }) => (
    <TabBarIcon
      focused={focused}
      name={Platform.OS === 'ios' ? 'ios-airplane' : 'md-airplane'}
      rotate="45deg"
    />
  ),
  tabBarOptions: { activeTintColor: 'black' }
}
 */
ArrivalStack.navigationOptions = ({ navigation }) => {
  return navigateRoute(navigation, 'Arrival', '45deg')
}

ArrivalScreen.path = ''

const DepartureStack = createStackNavigator(
  {
    Departure: DepartureScreen,
    PopModal: PopModal,
    Search: SearchModal,
    FlightMap: FlightMapScreen
  },
  {
    mode: 'modal'
  }
)
DepartureStack.navigationOptions = ({ navigation }) => {
  return navigateRoute(navigation, 'Departure', '-45deg')
}

DepartureScreen.path = ''

const tabNavigator = createBottomTabNavigator({
  ArrivalStack,
  DepartureStack
})

tabNavigator.path = ''

export default tabNavigator

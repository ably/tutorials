import React from 'react'
import { Platform } from 'react-native'
import {
  createStackNavigator,
  createBottomTabNavigator,
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
  default: {},
})

const navigateRoute = (navigation, label, rotate) => {
  let tabBarVisible
  if (navigation.state.routes.length > 1) {
    navigation.state.routes.map(route => {
      if (
        route.routeName === 'FlightMap' ||
        route.routeName === 'Search' ||
        route.routeName === 'PopModal'
      ) {
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
    tabBarOptions: { activeTintColor: '#000' },
  }
}

export const HomeStack = createStackNavigator(
  {
    Home: HomeScreen,
  },
  config
)

HomeStack.navigationOptions = ({ navigation }) => {
  return navigateRoute(navigation, 'Home', '45deg')
}

HomeStack.path = ''

const FlightMapStack = createStackNavigator(
  {
    FlightMap: FlightMapScreen,
  },
  config
)

FlightMapStack.navigationOptions = {
  tabBarLabel: 'Flight Map',
  tabBarOptions: { activeTintColor: '#000' },
}

const ArrivalStack = createStackNavigator(
  {
    Arrivals: ArrivalScreen,
    PopModal: PopModal,
    Search: SearchModal,
    FlightMap: FlightMapScreen,
  },
  {
    mode: 'modal',
  }
)

ArrivalStack.navigationOptions = ({ navigation }) => {
  return navigateRoute(navigation, 'Arrival', '45deg')
}

ArrivalScreen.path = ''

const DepartureStack = createStackNavigator(
  {
    Departure: DepartureScreen,
    PopModal: PopModal,
    Search: SearchModal,
    FlightMap: FlightMapScreen,
  },
  {
    mode: 'modal',
  }
)
DepartureStack.navigationOptions = ({ navigation }) => {
  return navigateRoute(navigation, 'Departure', '-45deg')
}

DepartureScreen.path = ''


export const BottomTabNavigator = createBottomTabNavigator({
  ArrivalStack,
  DepartureStack,
})

BottomTabNavigator.path = ''

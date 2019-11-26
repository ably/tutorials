import {StyleSheet} from 'react-native'

export const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: '#fff'
    },
    map_view: {
      ...StyleSheet.absoluteFillObject
    },
    dashboard: {
      backgroundColor: '#FFFFFF',
      flexDirection: 'row'
    },
    dashboarWrap: {
      position: 'absolute',
      backgroundColor: '#FFF',
      left: 0,
      right: 0,
      height: 150,
      borderTopLeftRadius: 20,
      borderTopRightRadius: 20,
      flex: 1,
      flexDirection: 'column',
      alignItems: 'center',
      flexWrap: 'wrap',
      bottom: 0
    },
    endButton: {
      position: 'absolute',
      bottom: 10,
      borderWidth: 1,
      color: '#000',
      width: 100,
      justifyContent: 'center',
      padding: 10
    }
  })
  
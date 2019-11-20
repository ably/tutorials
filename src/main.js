import * as VueGoogleMaps from 'vue2-google-maps'
 
Vue.use(VueGoogleMaps, {
  load: {
    key: 'AIzaSyBv7z18VAJ8MwpoY4FAJZv5zKWtJ8doLJE',
    libraries: 'places', // This is required if you use the Autocomplete plugin
    
  },
})

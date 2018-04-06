<template>
  <div id="app">
    <h1>Tic Tac Toe</h1>
    <set-name v-if="status !== 'loading'" :state="state" @set-name="onSetName" />
    <router-view v-if="status === 'ready'" :state="state" :status="status" :key="$route.path" />
    <p v-if="status === 'loading'">Connecting...</p>
  </div>
</template>

<script>
import GameState from './game';
import SetName from './components/set-name';

export default {
  name: 'App',

  components: {
    SetName
  },

  data() {
    return {
      status: 'loading',
      state: GameState.create(this.$route.params.id),
    };
  },

  methods: {
    onSetName(name) {
      this.status = 'ready';
    }
  },

  created() {
    const route = this.$route;
    const gameId = route.name === 'Game' ? route.params.id : null;
    this.status = this.state.userName ? 'ready' : 'set-name';
  },
};
</script>

<style>
@import url('https://fonts.googleapis.com/css?family=Alegreya+Sans:400,500,700');

body {
  background-color: #001824;
  color: #f7f7f7;
}
body, button, input {
  font-family: 'Alegreya Sans', sans-serif;
  font-size: 24px;
  font-weight: 500;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
h1 {
  margin: 40px 0;
  font-size: 48px;
  line-height: 32px;
  font-weight: 700;
  color: #FEC500;
}
#app {
  text-align: center;
}
</style>

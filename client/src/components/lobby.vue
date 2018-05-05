<template>
  <div class="lobby">
    <div class="games-list">
      <ul v-if="games.length > 0">
        <li v-for="game in games"><a :href="`/${game.gameId}`">Enter game versus {{ game.name }}</a></li>
      </ul>
      <div v-if="games.length === 0">There are no other games to join at the moment.</div>
    </div>
    <large-button @click="onCreateGame" text="Create Game" :is-disabled="false" />
  </div>
</template>

<script>
import LargeButton from './large-button';
import generate from 'nanoid/generate';
import { enterLobby } from '../state';

export default {
  name: 'lobby',

  data() {
    return {
      games: [],
      pending: false
    }
  },

  components: {
    LargeButton,
  },

  methods: {
    onCreateGame() {
      this.pending = true;
      const gameId = generate('0123456789abcdefghijklmnopqrstuvwxyz', 8);
      this.$router.push(`/${gameId}`);
    },

    onGamePending(clientId, game) {
      const index = this.games.findIndex(g => g.clientId === clientId);
      if (!game && index !== -1) {
        this.games.splice(index, 1);
      }
      else if (game && index === -1) {
        this.games.push({ clientId, ...game });
      }
    }
  },

  mounted() {
    enterLobby(this.onGamePending.bind(this));
  }
};
</script>

<style scoped>
.games-list {
  padding: 20px;
  color: #27627F;
  background-color: #011018;
}
ul {
  margin: 0;
  padding: 0;
  display: inline-flex;
  flex-direction: column;
  align-items: flex-start;
  list-style-type: none;
}
li a {
  display: block;
  color: #FEC500;
}
</style>

<template>
  <div class="game">
    <div class="game__board" v-if="otherPlayerName">
      <div class="game__other-player-name">Your opponent is {{ otherPlayerName }}</div>
      <game-board @select-position="onSelectPosition" :board="board" :active="isMyTurn"
                  :winningState="winningState" :isWinner="isWinner" />
      <div class="game__turn">{{ currentTurn }}</div>
      <large-button @click="onReturnToLobby" text="Back to Lobby" v-if="winningState || isDraw" />
    </div>
    <div class="game__waiting" v-else>
      <div class="game__waiting-message" v-if="!otherPlayerName">Waiting for an opponent...</div>
    </div>
  </div>
</template>

<script>
import GameBoard from './game-board';
import LargeButton from './large-button';
import { enterGame } from '../state';

export default {
  name: 'game',

  data() {
    return {
      gameId: this.$route.params.id,
      selectPosition: null,
      otherPlayerName: '',
      winningState: false,
      isMyTurn: false,
      isWinner: false,
      isDraw: false,
      board: [0,0,0,0,0,0,0,0,0]
    };
  },

  components: {
    GameBoard,
    LargeButton,
  },

  computed: {
    url() {
      return location.href;
    },

    currentTurn() {
      return this.isDraw ? `Dagnabbit. It's a draw.` : this.winningState
        ? this.isWinner ? 'You won the game!' : `${this.otherPlayerName} is the winner.`
        : this.isMyTurn ? `It's your turn` : `Waiting for ${this.otherPlayerName} to make a move`;
    }
  },

  methods: {
    onGameStateUpdated(state) {
      this.otherPlayerName = state.otherPlayerName;
      this.board = [...state.board];

      const currentPlayerId = state[state.currentPlayer];
      const isCurrentPlayer = state.clientId === currentPlayerId;

      if (state.status === 'in-progress') {
        this.isMyTurn = isCurrentPlayer;
      }
      else {
        if (state.status === 'win') {
          this.winningState = [...state.winCondition];
          this.isWinner = isCurrentPlayer;
        }
        else if (state.status ==='draw') {
          this.isDraw = true;
        }
        this.isMyTurn = false;
      }
    },

    onSelectPosition(position) {
      this.selectPosition(position);
    },

    onReturnToLobby() {
      this.$router.push(`/lobby`);
    }
  },

  mounted() {
    this.selectPosition = enterGame(this.gameId, this.onGameStateUpdated.bind(this));
  },
};
</script>

<style scoped>
.game {
  display: flex;
  justify-content: center;
}
.game__turn {
  margin-top: 40px;
}
.game__waiting-message {
  margin: 20px;
  color: #27627F;
}
.game__other-player-name {
  margin-bottom: 40px;
}
</style>

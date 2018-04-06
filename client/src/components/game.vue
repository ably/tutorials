<template>
  <div class="game">
    <div class="game__waiting" v-if="!otherPlayerName">
      <div class="game__waiting-message" v-if="!otherPlayerName">{{ waitingMessage }}</div>
      <div class="game__shareable-link" v-if="!otherPlayerClientId && playerNumber === 1">
        <div class="game__share-message">Copy this link and give it to a friend:</div>
        <div class="game__url" @click="onClickUrl">{{ url }}</div>
      </div>
    </div>
    <div class="game__board" v-if="otherPlayerName">
      <div class="game__vs">vs</div>
      <div class="game__other-player-name">{{ otherPlayerName }}</div>
      <game-board :state="state" :board="board" :active="isMyTurn" :final="final" :isWinner="isWinner" />
      <div class="game__turn">{{ currentTurn }}</div>
      <create-game :state="state" v-if="final || isDraw" />
    </div>
  </div>
</template>

<script>
import GameBoard from './game-board';
import CreateGame from './create-game';

export default {
  name: 'game',
  props: ['status', 'state', 'isGameCreator'],

  data() {
    return {
      gameStatus: 'pending',
      playerNumber: 0,
      otherPlayerClientId: '',
      otherPlayerName: '',
      final: false,
      isMyTurn: false,
      isWinner: false,
      isDraw: false,
      board: [0,0,0,0,0,0,0,0,0]
    };
  },

  components: {
    GameBoard,
    CreateGame,
  },

  computed: {
    url() {
      return location.href;
    },

    currentTurn() {
      return this.isDraw ? `Dagnabbit. It's a draw.` : this.final
        ? this.isWinner ? 'You won the game!' : `${this.otherPlayerName} is the winner.`
        : this.isMyTurn ? `It's your turn` : `Waiting for ${this.otherPlayerName} to make a move`;
    },

    waitingMessage() {
      return this.playerNumber === 0 ? 'Loading...'
        : this.otherPlayerClientId ? 'Opponent is now connecting...'
        : 'Waiting for opponent';
    }
  },

  methods: {
    onClickUrl(e) {
      const selection = window.getSelection();
      const range = document.createRange();
      range.selectNodeContents(e.target);
      selection.removeAllRanges();
      selection.addRange(range);
    },

    onStateMessage(msg) {
      const myClientId = this.state.clientId;
      switch(msg.name || msg.action) {
        case 'player1':
          if(msg.data.clientId === myClientId) {
            this.playerNumber = 1;
          }
          else {
            this.otherPlayerClientId = msg.data.clientId;
          }
          break;

        case 'player2':
          if(msg.data.clientId === myClientId) {
            this.playerNumber = 2;
          }
          else {
            this.otherPlayerClientId = msg.data.clientId;
          }
          break;

        case 'state': {
          const state = msg.data;
          this.board = Array.from(state.board);
          const isCurrentPlayer = state.currentPlayer === this.playerNumber - 1;
          switch (state.status) {
            case 'win':
              this.final = Array.from(state.winCondition);
              this.isWinner = isCurrentPlayer;
              this.isMyTurn = false;
              break;
            case 'draw':
              this.isDraw = true;
              this.isMyTurn = false;
              break;
            case 'in-progress':
              this.isMyTurn = isCurrentPlayer;
              break;
          }

          if (this.final || this.isDraw) {
            this.state.exitGame();
          }
          break;
        }

        case 'enter':
        case 'update':
        case 'present':
          if(msg.clientId === this.otherPlayerClientId) {
            this.otherPlayerName = msg.data && msg.data.name;
          }
          break;
      }
    }
  },

  mounted() {
    const gameId = this.$route.params.id;

    this.state
      .enterGame(gameId, this.onStateMessage.bind(this))
      .catch(console.error);
  },
};
</script>

<style scoped>
.game {
  display: flex;
  justify-content: center;
}
.game__vs {
  margin-bottom: 4px;
  color: #27627F;
}
.game__turn {
  margin-top: 40px;
}
.game__waiting-message {
  margin: 20px;
  color: #27627F;
}
.game__shareable-link {
  margin-top: 40px;
}
.game__share-message {
  margin-bottom: 10px;
  font-size: 18px;
}
.game__url {
  padding: 10px 20px;
  color: #001824;
  background-color: #FEC500;
}
.game__other-player-name {
  margin-bottom: 40px;
}
</style>

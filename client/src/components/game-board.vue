<template>
  <div :class="{ 'game-board': true, 'game-board--active': active }">
    <template v-for="(state, position) in board">
      <game-board-cell
        :position="position"
        :state="state"
        :final="final && final.includes(position) && (isWinner ? 'win' : 'loss')"
        :key="position"
        @select-cell="onClickCell" />
    </template>
  </div>
</template>

<script>
import GameBoardCell from './game-board-cell';

export default {
  name: 'game-board',
  props: ['state', 'board', 'final', 'active', 'isWinner'],

  components: {
    GameBoardCell,
  },

  methods: {
    onClickCell(position) {
      if(this.active) {
        this.state.selectBoardPosition(position)
          .catch(console.error);
      }
    }
  }
};
</script>

<style>
.game-board {
  display: inline-grid;
  grid-template-rows: 1fr 1fr 1fr;
  grid-template-columns: 1fr 1fr 1fr;
  width: 200px;
  height: 200px;
  font-size: 48px;
}
</style>

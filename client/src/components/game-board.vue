<template>
  <div :class="{ 'game-board': true, 'game-board--active': active }">
    <template v-for="(state, position) in board">
      <game-board-cell
        :position="position"
        :state="state"
        :final="winningState && winningState.includes(position) && (isWinner ? 'win' : 'loss')"
        :key="position"
        @select-cell="onClickCell" />
    </template>
  </div>
</template>

<script>
import GameBoardCell from './game-board-cell';

export default {
  name: 'game-board',
  props: ['board', 'winningState', 'active', 'isWinner'],

  components: {
    GameBoardCell,
  },

  methods: {
    onClickCell(position) {
      if(this.active) {
        this.$emit('select-position', position);
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

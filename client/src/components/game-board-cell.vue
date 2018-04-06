<template>
  <div :class="['game-board__cell', rowClass, colClass, stateClass, finalClass]" @click="click(position)">
    <i v-if="state === 1" class="far fa-circle"></i>
    <i v-else-if="state === 2" class="fas fa-times"></i>
  </div>
</template>

<script>
export default {
  name: 'game-board-cell',
  props: ['position', 'state', 'final'],

  computed: {
    rowClass() { return `game-board__cell--row-${Math.floor(this.position / 3)}`; },
    colClass() { return `game-board__cell--col-${this.position % 3}`; },
    stateClass() { return `game-board__cell--${this.state ? 'set' : 'unset'}`; },
    finalClass() { return this.final ? `game-board__cell--${this.final}` : false; }
  },

  methods: {
    click(position) {
      this.$emit('select-cell', position);
    }
  }
};
</script>

<style>
.game-board__cell {
  display: flex;
  justify-content: center;
  align-items: center;
}
.game-board__cell--win {
  color: #81B60F;
}
.game-board__cell--loss {
  color: #73021B;
}
.game-board--active .game-board__cell--unset {
  background-color: rgba(224, 255, 0, 0.1);
  cursor: pointer;
}
.game-board--active .game-board__cell--unset:hover {
  background-color: rgba(224, 255, 0, 0.3);
}
.game-board__cell--row-0.game-board__cell--col-0 {
  border-radius: 5px 0 0 0;
}
.game-board__cell--row-0.game-board__cell--col-2 {
  border-radius: 0 5px 0 0;
}
.game-board__cell--row-2.game-board__cell--col-0 {
  border-radius: 0 0 0 5px;
}
.game-board__cell--row-2.game-board__cell--col-2 {
  border-radius: 0 0 5px 0;
}
.game-board__cell--row-1,
.game-board__cell--row-2 {
  border-top: 5px solid #f7f7f7;
}
.game-board__cell--col-1,
.game-board__cell--col-2 {
  border-left: 5px solid #f7f7f7;
}
i.fa-circle {
  font-size: 48px;
}
i.fa-times {
  font-size: 60px;
}
</style>

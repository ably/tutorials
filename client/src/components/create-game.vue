<template>
  <div :class="{ 'create-game': true, pending: this.pending }">
    <button @click="click" :disabled="isDisabled">{{ buttonText }}</button>
  </div>
</template>

<script>
export default {
  name: 'create-game',

  props: {
    state: null,
    disabled: {
      type: Boolean,
      default: false
    }
  },

  data() {
    return {
      buttonText: 'Create Game',
      isDisabled: this.disabled,
      pending: false
    };
  },

  methods: {
    click() {
      this.pending = true;
      this.isDisabled = true;
      this.buttonText = 'Creating Game...';
      this.state.newGame()
        .then(game => this.$router.push(`/${game.gameId}`))
        .catch(console.error);
    }
  },
};
</script>

<style scoped>
button {
  border: none;
  border-radius: 5px;
  padding: 15px 30px;
  font-weight: 500;
  outline: none;
  color: #f7f7f7;
  background-color: #73021B;
}
.create-game {
  margin-top: 40px;
}
.create-game:not(.pending) button[disabled] {
  color: #27627F;
  background-color: #003D50;
  opacity: 0.5;
}
.create-game.pending button {
  color: #27627F;
  background-color: #003D50;
}
.create-game:not(.pending) button:not([disabled]) {
  cursor: pointer;
}
.create-game:not(.pending) button:not([disabled]):hover {
  color: #FEC500;
}
.create-game:not(.pending) button:not([disabled]):active {
  color: #001824;
  background-color: #FEC500;
}
</style>

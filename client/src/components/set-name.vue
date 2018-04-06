<template>
  <div class="set-name">
    <input type="text" placeholder="Enter your name here" ref="input" :value="state.userName" @input="onInput" />
  </div>
</template>

<script>
export default {
  name: 'set-name',
  props: ['state', 'name'],

  data() {
    return {
      value: this.state.name,
      timerHandle: 0
    };
  },

  methods: {
    onInput({ target: { value } }) {
      if (!value.trim()) {
        return;
      }
      clearTimeout(this.timerHandle);
      this.timerHandle = setTimeout(() => this.state
        .setUserName(value)
        .then(() => this.$emit('set-name', value))
        .catch(console.error),
        500);
    },
  },

  mounted() {
    if (!this.value) {
      this.$refs.input.focus();
    }
  }
};
</script>

<style scoped>
.set-name {
  display: block;
}
input {
  border: none;
  outline: none;
  text-align: center;
  line-height: 36px;
  color: #f7f7f7;
  background-color: rgba(0, 0, 0, 0.2);
}
input::placeholder {
  color: #e7e7e7;
}
input:focus::placeholder {
  color: rgba(255, 255, 255, 0.15);
}
</style>

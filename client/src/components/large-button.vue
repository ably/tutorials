<template>
  <div :class="{ 'large-button': true }">
    <button @click="click" :disabled="isDisabled">{{ text }}</button>
  </div>
</template>

<script>
export default {
  name: 'large-button',

  props: {
    text: {
      type: String,
      default: 'Submit'
    },
    isDisabled: {
      type: Boolean,
      default: false
    }
  },

  methods: {
    click() {
      this.$emit('click');
    }
  }
};
</script>

<style scoped>
button {
  border: none;
  border-radius: 5px;
  padding: 10px 30px;
  font-weight: 500;
  outline: none;
  color: #f7f7f7;
  background-color: #73021B;
}
.large-button {
  margin-top: 40px;
}
.large-button button[disabled] {
  color: #27627F;
  background-color: #003D50;
  opacity: 0.5;
}
.large-button button:not([disabled]) {
  cursor: pointer;
}
.large-button button:not([disabled]):hover {
  color: #FEC500;
}
.large-button button:not([disabled]):active {
  color: #001824;
  background-color: #FEC500;
}
</style>

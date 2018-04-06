<template>
  <div class="home">
    <create-game :state="state" :disabled="status !== 'ready'" />
  </div>
</template>

<script>
import CreateGame from './create-game';

export default {
  name: 'home',
  props: ['status', 'state'],

  components: {
    CreateGame,
  },
};
</script>

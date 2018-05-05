<template>
  <div class="home">
    <set-name :name="name" @set-name="onSetName" @accept-name="onAcceptName" />
    <large-button @click="onAcceptName" text="Enter Lobby" :is-disabled="!name" />
  </div>
</template>

<script>
import LargeButton from './large-button';
import SetName from './set-name';
import generate from 'nanoid/generate';
import { storeUserName, retrieveUserName } from '../state';

export default {
  name: 'home',

  data() {
    return {
      name: retrieveUserName()
    }
  },

  components: {
    SetName,
    LargeButton,
  },

  methods: {
    onSetName(name) {
      this.name = name;
      this.preventCreate = name.length === 0;
    },

    onAcceptName() {
      storeUserName(this.name);
      this.$router.push(`/lobby`);
    }
  }
};
</script>

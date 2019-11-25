<template>
  <div id="app">
    <GmapMap
      :center="{ lat: initialPosition.lat, lng: initialPosition.lng }"
      :zoom="10"
      map-type-id="terrain"
      style="width: 100%; height: 90%"
    >
      <!-- check if icon link in makers payload then display -->
      <GmapMarker
        :key="index"
        v-for="(m, index) in markers"
        :position="m.position"
        :clickable="true"
        :draggable="false"
        @click="center = m.position"
        :icon="m.icon"
        :title="m.userName"
      />
    </GmapMap>

    <div class="notification">
      <p>Online Users: {{ markers.length }}</p>
      <ul>
        <li v-for="(user, i) in onlineUsers" :key="i">
          <pre v-text="user.data.userName"></pre>
        </li>
      </ul>
    </div>
  </div>
</template>

import axios from "axios";
import * as Ably from "ably";
import Loading from "vue-loading-overlay";
import "vue-loading-overlay/dist/vue-loading.css";

var ably = new Ably.Realtime({
  key: "<ably key>",
  clientId: `${Math.random() * 1000000}`
});

  mounted() {
    const name = prompt(
      "To get started, input your name in the field below and locate your friends around based on your location, please turn on your location setting \n What is your name?"
    );
    this.usersName = name;
    const channel = prompt("Enter name of channel you are interested in");
    this.channelName = channel;
  },
    fetchData() {
      if (!("geolocation" in navigator)) {
        this.errorStr = "Geolocation is not available.";
        return;
      }
      this.gettingLocation = true;
      navigator.geolocation.watchPosition(
        pos => {
          this.gettingLocation = false;
          this.initialPosition.lat = pos.coords.latitude;
          this.initialPosition.lng = pos.coords.longitude;
          const userData = {
            position: {
              lat: pos.coords.latitude,
              lng: pos.coords.longitude
            },
            userName: this.usersName
          };
          this.userlocation = userData;
          this.updateRoom(userData);
        },
        err => {
          this.gettingLocation = false;
          this.errorStr = err.message;
        }
      );
    },

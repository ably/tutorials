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

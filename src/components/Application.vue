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

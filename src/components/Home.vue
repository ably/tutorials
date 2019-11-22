<template>
  <div class="home">
    <div class="write-up">
      <h4>Dear Friend,</h4>
      <p>Welcome to friend-finder the App</p>
      <h3>Getting Started</h3>
      <ul>
        <li>Click on the big green button to start</li>
        <li>Enter your name and click Enter</li>
        <li>
          Enter the name of your friends channel, or enter the name of a channel
          you want to create ,for you and your friends, then hit Enter
        </li>
        <li>Share your channel name with your friends to join</li>
        <li>you can zoom in and out to see your friends from the map</li>
        <li>
          You would have detailed information about current friends in your
          channel
        </li>
      </ul>
      <a href="#/app" class="button">Get Started</a>
    </div>
  </div>
</template>

<script>
export default {};
</script>

<style>
.home {
  background: #f1f6fd;
  height: 100vh;
}

img {
  width: 40%;
}

.write-up {
  margin-left: 3.0rem;
}

h4, h5 {
  font-size: 25px;
  font-weight: normal;
}

.button {
  padding: 1.0rem;
  border: 1px solid teal;
  background: teal;
  color: white;
  font-size: 14px;
  font-weight: bold;
  text-decoration: none;
  margin-top: 2.0rem;
}
</style>

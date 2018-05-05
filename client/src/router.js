import Vue from 'vue';
import Router from 'vue-router';
import Home from './components/home';
import Lobby from './components/lobby';
import Game from './components/game';

Vue.use(Router);

export default new Router({
  mode: 'history',
  routes: [
    {
      path: '/',
      name: 'Home',
      component: Home,
    },
    {
      path: '/lobby',
      name: 'Lobby',
      component: Lobby,
    },
    {
      path: '/:id',
      name: 'Game',
      component: Game,
    },
  ],
});

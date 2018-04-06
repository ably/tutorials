import Vue from 'vue';
import Router from 'vue-router';
import Home from '@/components/home';
import Game from '@/components/game';

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
      path: '/:id',
      name: 'Game',
      component: Game,
    },
  ],
});

import { createRouter, createWebHashHistory } from 'vue-router';
import Layout from './components/Layout.vue';
import Login from './views/Login.vue';
import Dashboard from './views/Dashboard.vue';
import Teams from './views/Teams.vue';
import Employees from './views/Employees.vue';
import Needs from './views/Needs.vue';
import Comments from './views/Comments.vue';
import Posts from './views/Posts.vue';
import Icons from './views/Icons.vue';
import Users from './views/Users.vue';
import Agent from './views/Agent.vue';

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/login', component: Login },
    {
      path: '/',
      component: Layout,
      children: [
        { path: '', redirect: '/dashboard' },
        { path: 'dashboard', component: Dashboard },
        { path: 'teams', component: Teams },
        { path: 'employees', component: Employees },
        { path: 'needs', component: Needs },
        { path: 'comments', component: Comments },
        { path: 'posts', component: Posts },
        { path: 'icons', component: Icons },
        { path: 'users', component: Users },
        { path: 'agent', component: Agent },
      ],
    },
  ],
});

router.beforeEach(to => {
  const token = localStorage.getItem('lp-token');
  if (to.path !== '/login' && !token) return '/login';
  if (to.path === '/login' && token) return '/';
  return true;
});

export default router;

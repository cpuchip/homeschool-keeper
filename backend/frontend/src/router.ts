import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/pages/LoginPage.vue'),
      meta: { requiresGuest: true }
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('@/pages/RegisterPage.vue'),
      meta: { requiresGuest: true }
    },
    {
      path: '/',
      component: () => import('@/layouts/AppLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          name: 'dashboard',
          component: () => import('@/pages/DashboardPage.vue')
        },
        {
          path: 'log',
          name: 'quick-log',
          component: () => import('@/pages/QuickLogPage.vue')
        },
        {
          path: 'students',
          name: 'students',
          component: () => import('@/pages/StudentsPage.vue')
        },
        {
          path: 'students/:id',
          name: 'student-detail',
          component: () => import('@/pages/StudentDetailPage.vue')
        },
        {
          path: 'subjects',
          name: 'subjects',
          component: () => import('@/pages/SubjectsPage.vue')
        },
        {
          path: 'logs',
          name: 'logs',
          component: () => import('@/pages/LogsPage.vue')
        },
        {
          path: 'settings',
          name: 'settings',
          component: () => import('@/pages/SettingsPage.vue')
        }
      ]
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: () => import('@/pages/NotFoundPage.vue')
    }
  ]
})

// Navigation guards
router.beforeEach((to, _from, next) => {
  const authStore = useAuthStore()
  
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next({ name: 'login', query: { redirect: to.fullPath } })
  } else if (to.meta.requiresGuest && authStore.isAuthenticated) {
    next({ name: 'dashboard' })
  } else {
    next()
  }
})

export default router

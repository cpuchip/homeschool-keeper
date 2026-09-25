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
      path: '/onboarding',
      name: 'onboarding',
      component: () => import('@/pages/OnboardingPage.vue'),
      meta: { requiresAuth: true }
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
        },
        {
          path: 'trash',
          name: 'trash',
          component: () => import('@/pages/TrashPage.vue')
        },
        {
          path: 'export',
          name: 'export',
          component: () => import('@/pages/ExportPage.vue')
        }
      ]
    },
    {
      path: '/admin',
      component: () => import('@/pages/admin/AdminLayout.vue'),
      meta: { requiresAuth: true, requiresSuperAdmin: true },
      children: [
        {
          path: '',
          redirect: '/admin/dashboard'
        },
        {
          path: 'dashboard',
          name: 'admin-dashboard',
          component: () => import('@/pages/admin/AdminDashboard.vue')
        },
        {
          path: 'families',
          name: 'admin-families',
          component: () => import('@/pages/admin/AdminFamilies.vue')
        },
        {
          path: 'families/:id',
          name: 'admin-family-detail',
          component: () => import('@/pages/admin/AdminFamilyDetail.vue')
        },
        {
          path: 'orgs',
          name: 'admin-orgs',
          component: () => import('@/pages/admin/AdminOrgs.vue')
        },
        {
          path: 'orgs/:id',
          name: 'admin-org-detail',
          component: () => import('@/pages/admin/AdminOrgDetail.vue')
        },
        {
          path: 'storage',
          name: 'admin-storage',
          component: () => import('@/pages/admin/AdminStorage.vue')
        },
        {
          path: 'telemetry',
          name: 'admin-telemetry',
          component: () => import('@/pages/admin/AdminTelemetry.vue')
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
router.beforeEach(async (to, _from, next) => {
  const authStore = useAuthStore()
  
  // Fetch user session on first navigation (check if already logged in via cookie)
  if (!authStore.initialized) {
    await authStore.fetchUser()
  }
  
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next({ name: 'login', query: { redirect: to.fullPath } })
  } else if (to.meta.requiresGuest && authStore.isAuthenticated) {
    next({ name: 'dashboard' })
  } else {
    next()
  }
})

export default router

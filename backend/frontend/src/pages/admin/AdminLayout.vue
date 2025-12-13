<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const activeTab = ref('dashboard')

// Check if user is super admin
const isSuperAdmin = computed(() => {
  return authStore.user?.email === 'cpuchip@gmail.com'
})

onMounted(() => {
  if (!isSuperAdmin.value) {
    router.push('/dashboard')
  }
})

const tabs = [
  { id: 'dashboard', label: 'Dashboard', icon: '📊' },
  { id: 'families', label: 'Families', icon: '👨‍👩‍👧‍👦' },
  { id: 'orgs', label: 'Organizations', icon: '🏢' },
  { id: 'storage', label: 'R2 Storage', icon: '💾' },
  { id: 'telemetry', label: 'Telemetry', icon: '📈' },
]

function navigateToTab(tabId: string) {
  activeTab.value = tabId
  router.push(`/admin/${tabId}`)
}

// Set active tab based on current route
onMounted(() => {
  const path = router.currentRoute.value.path
  const tabId = path.split('/').pop()
  if (tabId && tabs.some(t => t.id === tabId)) {
    activeTab.value = tabId
  }
})
</script>

<template>
  <div v-if="isSuperAdmin" class="min-h-screen bg-gray-50">
    <!-- Header -->
    <header class="bg-gradient-to-r from-purple-600 to-indigo-600 text-white shadow-lg">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold">🔒 Super Admin Portal</h1>
            <p class="text-purple-200 text-sm">Home School Logs Management</p>
          </div>
          <div class="flex items-center gap-4">
            <span class="text-purple-200 text-sm">{{ authStore.user?.email }}</span>
            <router-link to="/dashboard" class="bg-white/20 hover:bg-white/30 px-4 py-2 rounded-lg transition">
              ← Back to App
            </router-link>
          </div>
        </div>
      </div>
    </header>

    <!-- Tab Navigation -->
    <nav class="bg-white border-b shadow-sm">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex space-x-8">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            @click="navigateToTab(tab.id)"
            :class="[
              'py-4 px-1 border-b-2 font-medium text-sm transition-colors',
              activeTab === tab.id
                ? 'border-indigo-500 text-indigo-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            ]"
          >
            <span class="mr-2">{{ tab.icon }}</span>
            {{ tab.label }}
          </button>
        </div>
      </div>
    </nav>

    <!-- Content -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <router-view />
    </main>
  </div>

  <div v-else class="min-h-screen flex items-center justify-center bg-gray-50">
    <div class="text-center">
      <h1 class="text-2xl font-bold text-gray-900 mb-4">Access Denied</h1>
      <p class="text-gray-600 mb-4">You don't have permission to access this area.</p>
      <router-link to="/dashboard" class="text-indigo-600 hover:text-indigo-800">
        ← Return to Dashboard
      </router-link>
    </div>
  </div>
</template>

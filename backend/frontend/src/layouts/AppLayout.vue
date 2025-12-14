<script setup lang="ts">
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const router = useRouter()

const isSuperAdmin = computed(() => authStore.user?.isSuperAdmin === true)

async function handleLogout() {
  await authStore.logout()
  router.push('/login')
}
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <!-- Sidebar -->
    <div class="fixed inset-y-0 left-0 w-64 bg-white shadow-lg">
      <div class="flex items-center justify-center h-16 border-b">
        <span class="text-xl font-bold text-primary-600">📚 Homeschool Keeper</span>
      </div>
      
      <nav class="mt-6">
        <router-link
          to="/"
          class="flex items-center px-6 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-primary-50 text-primary-600 border-r-4 border-primary-600"
        >
          <span class="mr-3">🏠</span>
          Dashboard
        </router-link>
        <router-link
          to="/log"
          class="flex items-center px-6 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-primary-50 text-primary-600 border-r-4 border-primary-600"
        >
          <span class="mr-3">✏️</span>
          Quick Log
        </router-link>
        <router-link
          to="/students"
          class="flex items-center px-6 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-primary-50 text-primary-600 border-r-4 border-primary-600"
        >
          <span class="mr-3">👨‍👩‍👧‍👦</span>
          Students
        </router-link>
        <router-link
          to="/subjects"
          class="flex items-center px-6 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-primary-50 text-primary-600 border-r-4 border-primary-600"
        >
          <span class="mr-3">📚</span>
          Subjects
        </router-link>
        <router-link
          to="/logs"
          class="flex items-center px-6 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-primary-50 text-primary-600 border-r-4 border-primary-600"
        >
          <span class="mr-3">📋</span>
          Log History
        </router-link>
        <router-link
          to="/settings"
          class="flex items-center px-6 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-primary-50 text-primary-600 border-r-4 border-primary-600"
        >
          <span class="mr-3">⚙️</span>
          Settings
        </router-link>
        
        <!-- Super Admin Link -->
        <router-link
          v-if="isSuperAdmin"
          to="/admin"
          class="flex items-center px-6 py-3 text-purple-700 hover:bg-purple-50 mt-4 border-t"
          active-class="bg-purple-50 text-purple-600 border-r-4 border-purple-600"
        >
          <span class="mr-3">🔒</span>
          Admin Portal
        </router-link>
      </nav>

      <div class="absolute bottom-0 left-0 right-0 p-4 border-t">
        <button
          class="w-full btn-secondary text-sm"
          @click="handleLogout"
        >
          Sign Out
        </button>
      </div>
    </div>

    <!-- Main Content -->
    <div class="ml-64 p-8">
      <router-view />
    </div>
  </div>
</template>

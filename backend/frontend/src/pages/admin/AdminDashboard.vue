<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getDashboardStats, type DashboardStats } from '../../api/admin'

const stats = ref<DashboardStats | null>(null)
const loading = ref(true)
const error = ref('')

async function loadStats() {
  loading.value = true
  error.value = ''
  try {
    stats.value = await getDashboardStats()
  } catch (e: any) {
    error.value = e.response?.data?.error || 'Failed to load stats'
  } finally {
    loading.value = false
  }
}

onMounted(loadStats)

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleString()
}
</script>

<template>
  <div>
    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-4">
      <p class="text-red-600">{{ error }}</p>
      <button @click="loadStats" class="mt-2 text-red-700 underline">Retry</button>
    </div>

    <!-- Stats Dashboard -->
    <div v-else-if="stats">
      <div class="mb-6">
        <h2 class="text-xl font-semibold text-gray-900">System Overview</h2>
        <p class="text-sm text-gray-500">Last updated: {{ formatDate(stats.generatedAt) }}</p>
      </div>

      <!-- Stats Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <!-- Families -->
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-gray-500">Total Families</p>
              <p class="text-3xl font-bold text-gray-900">{{ stats.totalFamilies }}</p>
            </div>
            <div class="text-4xl">👨‍👩‍👧‍👦</div>
          </div>
        </div>

        <!-- Organizations -->
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-gray-500">Organizations</p>
              <p class="text-3xl font-bold text-gray-900">{{ stats.totalOrgs }}</p>
            </div>
            <div class="text-4xl">🏢</div>
          </div>
        </div>

        <!-- Students -->
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-gray-500">Total Students</p>
              <p class="text-3xl font-bold text-gray-900">{{ stats.totalStudents }}</p>
            </div>
            <div class="text-4xl">🎒</div>
          </div>
        </div>

        <!-- Log Entries -->
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-gray-500">Log Entries</p>
              <p class="text-3xl font-bold text-gray-900">{{ (stats.totalLogs ?? 0).toLocaleString() }}</p>
            </div>
            <div class="text-4xl">📝</div>
          </div>
        </div>
      </div>

      <!-- Premium & Storage Stats -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <!-- Premium Features -->
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Premium Features</h3>
          <div class="space-y-4">
            <div class="flex items-center justify-between">
              <span class="text-gray-600">Families with Sync Enabled</span>
              <span class="text-xl font-semibold text-indigo-600">{{ stats.syncEnabled }}</span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-gray-600">Families with Uploads Enabled</span>
              <span class="text-xl font-semibold text-indigo-600">{{ stats.uploadsEnabled }}</span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-gray-600">Premium Adoption Rate</span>
              <span class="text-xl font-semibold text-indigo-600">
                {{ stats.totalFamilies > 0 ? ((stats.uploadsEnabled / stats.totalFamilies) * 100).toFixed(1) : 0 }}%
              </span>
            </div>
          </div>
        </div>

        <!-- Storage Stats -->
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">R2 Storage</h3>
          <div class="space-y-4">
            <div class="flex items-center justify-between">
              <span class="text-gray-600">Total Work Samples</span>
              <span class="text-xl font-semibold text-emerald-600">{{ (stats.totalWorkSamples ?? 0).toLocaleString() }}</span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-gray-600">Total Storage Used</span>
              <span class="text-xl font-semibold text-emerald-600">{{ formatBytes(stats.totalStorageBytes) }}</span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-gray-600">Average per Family</span>
              <span class="text-xl font-semibold text-emerald-600">
                {{ stats.uploadsEnabled > 0 ? formatBytes(stats.totalStorageBytes / stats.uploadsEnabled) : '0 B' }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Links -->
      <div class="bg-gradient-to-r from-indigo-50 to-purple-50 rounded-xl border border-indigo-100 p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div class="flex flex-wrap gap-4">
          <router-link
            to="/admin/families"
            class="bg-white hover:bg-gray-50 border rounded-lg px-4 py-2 text-sm font-medium text-gray-700 transition"
          >
            View All Families →
          </router-link>
          <router-link
            to="/admin/orgs"
            class="bg-white hover:bg-gray-50 border rounded-lg px-4 py-2 text-sm font-medium text-gray-700 transition"
          >
            View Organizations →
          </router-link>
          <router-link
            to="/admin/storage"
            class="bg-white hover:bg-gray-50 border rounded-lg px-4 py-2 text-sm font-medium text-gray-700 transition"
          >
            View Storage Details →
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

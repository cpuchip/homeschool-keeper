<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { getStorageStats, type StorageSummary } from '../../api/admin'

const router = useRouter()
const storage = ref<StorageSummary[]>([])
const loading = ref(true)
const error = ref('')

async function loadStorage() {
  loading.value = true
  error.value = ''
  try {
    storage.value = await getStorageStats()
  } catch (e: any) {
    error.value = e.response?.data?.error || 'Failed to load storage stats'
  } finally {
    loading.value = false
  }
}

onMounted(loadStorage)

const totalStats = computed(() => {
  return {
    totalFiles: storage.value.reduce((sum, s) => sum + s.fileCount, 0),
    totalBytes: storage.value.reduce((sum, s) => sum + s.totalBytes, 0),
    familiesWithUploads: storage.value.filter(s => s.fileCount > 0).length,
    familiesEnabled: storage.value.filter(s => s.uploadsEnabled).length,
  }
})

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

function viewFamily(id: string) {
  router.push(`/admin/families/${id}`)
}
</script>

<template>
  <div>
    <div class="mb-6">
      <h2 class="text-xl font-semibold text-gray-900">R2 Storage Overview</h2>
      <p class="text-sm text-gray-500">View storage usage per family (no file access)</p>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-4">
      <p class="text-red-600">{{ error }}</p>
      <button @click="loadStorage" class="mt-2 text-red-700 underline">Retry</button>
    </div>

    <div v-else>
      <!-- Summary Stats -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Total Files</p>
          <p class="text-3xl font-bold text-gray-900">{{ totalStats.totalFiles.toLocaleString() }}</p>
        </div>
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Total Storage</p>
          <p class="text-3xl font-bold text-emerald-600">{{ formatBytes(totalStats.totalBytes) }}</p>
        </div>
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Families with Files</p>
          <p class="text-3xl font-bold text-indigo-600">{{ totalStats.familiesWithUploads }}</p>
        </div>
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Uploads Enabled</p>
          <p class="text-3xl font-bold text-blue-600">{{ totalStats.familiesEnabled }}</p>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="storage.length === 0" class="text-center py-12 bg-gray-50 rounded-lg">
        <p class="text-gray-500">No storage data yet. Families need to upload work samples first.</p>
      </div>

      <!-- Storage Table -->
      <div v-else class="bg-white rounded-xl shadow-sm border overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Family</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Files</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Total Size</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Avg per File</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th class="px-6 py-3"></th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr
              v-for="item in storage"
              :key="item.familyId"
              class="hover:bg-gray-50"
            >
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm font-medium text-gray-900">{{ item.familyName }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {{ item.fileCount.toLocaleString() }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {{ formatBytes(item.totalBytes) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ item.fileCount > 0 ? formatBytes(item.totalBytes / item.fileCount) : '-' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  v-if="item.uploadsEnabled"
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800"
                >
                  Enabled
                </span>
                <span
                  v-else
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-600"
                >
                  Disabled
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                <button
                  @click="viewFamily(item.familyId)"
                  class="text-indigo-600 hover:text-indigo-900"
                >
                  View Family →
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Privacy Notice -->
      <div class="mt-6 bg-amber-50 border border-amber-200 rounded-lg p-4">
        <p class="text-amber-800 text-sm">
          <strong>🔒 Privacy Note:</strong> This view shows aggregate storage data only. 
          You cannot view, access, or download individual work samples from this portal.
        </p>
      </div>
    </div>
  </div>
</template>

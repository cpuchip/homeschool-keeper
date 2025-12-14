<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { getFamilies, type FamilySummary } from '../../api/admin'

const router = useRouter()
const families = ref<FamilySummary[]>([])
const loading = ref(true)
const error = ref('')
const searchQuery = ref('')
const filterPremium = ref<'all' | 'sync' | 'uploads' | 'none'>('all')

async function loadFamilies() {
  loading.value = true
  error.value = ''
  try {
    families.value = await getFamilies()
  } catch (e: any) {
    error.value = e.response?.data?.error || 'Failed to load families'
  } finally {
    loading.value = false
  }
}

onMounted(loadFamilies)

const filteredFamilies = computed(() => {
  let result = families.value

  // Search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(f => 
      f.name.toLowerCase().includes(query) ||
      f.state.toLowerCase().includes(query)
    )
  }

  // Premium filter
  if (filterPremium.value === 'sync') {
    result = result.filter(f => f.syncEnabled)
  } else if (filterPremium.value === 'uploads') {
    result = result.filter(f => f.uploadsEnabled)
  } else if (filterPremium.value === 'none') {
    result = result.filter(f => !f.syncEnabled && !f.uploadsEnabled)
  }

  return result
})

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString()
}

function viewFamily(id: string) {
  router.push(`/admin/families/${id}`)
}
</script>

<template>
  <div>
    <div class="mb-6 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <h2 class="text-xl font-semibold text-gray-900">Families ({{ families.length }})</h2>
      
      <div class="flex flex-col sm:flex-row gap-3">
        <!-- Search -->
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search families..."
          class="border rounded-lg px-4 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
        />
        
        <!-- Premium Filter -->
        <select
          v-model="filterPremium"
          class="border rounded-lg px-4 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
        >
          <option value="all">All Families</option>
          <option value="sync">Sync Enabled</option>
          <option value="uploads">Uploads Enabled</option>
          <option value="none">Free Tier</option>
        </select>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-4">
      <p class="text-red-600">{{ error }}</p>
      <button @click="loadFamilies" class="mt-2 text-red-700 underline">Retry</button>
    </div>

    <!-- Empty State -->
    <div v-else-if="filteredFamilies.length === 0" class="text-center py-12 bg-gray-50 rounded-lg">
      <p class="text-gray-500">No families found</p>
    </div>

    <!-- Families Table -->
    <div v-else class="bg-white rounded-xl shadow-sm border overflow-hidden">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Family</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">State</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Students</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Logs</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Storage</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Premium</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
            <th class="px-6 py-3"></th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr
            v-for="family in filteredFamilies"
            :key="family.id"
            class="hover:bg-gray-50 cursor-pointer"
            @click="viewFamily(family.id)"
          >
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-gray-900">{{ family.name }}</div>
              <div v-if="family.organizationIds.length > 0" class="text-xs text-gray-500">
                🏢 In {{ family.organizationIds.length }} org(s)
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ family.state }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ family.studentCount }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ family.logCount.toLocaleString() }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ family.storageUsedMB.toFixed(2) }} MB</td>
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="flex gap-2">
                <span
                  v-if="family.syncEnabled"
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800"
                >
                  Sync
                </span>
                <span
                  v-if="family.uploadsEnabled"
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800"
                >
                  Uploads
                </span>
                <span
                  v-if="!family.syncEnabled && !family.uploadsEnabled"
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-600"
                >
                  Free
                </span>
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ formatDate(family.createdAt) }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
              <button class="text-indigo-600 hover:text-indigo-900">View →</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

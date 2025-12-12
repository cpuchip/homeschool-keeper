<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { getOrganizations, type OrgSummary } from '../../api/admin'

const router = useRouter()
const orgs = ref<OrgSummary[]>([])
const loading = ref(true)
const error = ref('')
const searchQuery = ref('')

async function loadOrgs() {
  loading.value = true
  error.value = ''
  try {
    orgs.value = await getOrganizations()
  } catch (e: any) {
    error.value = e.response?.data?.error || 'Failed to load organizations'
  } finally {
    loading.value = false
  }
}

onMounted(loadOrgs)

const filteredOrgs = computed(() => {
  if (!searchQuery.value) return orgs.value
  const query = searchQuery.value.toLowerCase()
  return orgs.value.filter(o =>
    o.name.toLowerCase().includes(query) ||
    o.description.toLowerCase().includes(query)
  )
})

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString()
}

function viewOrg(id: string) {
  router.push(`/admin/orgs/${id}`)
}
</script>

<template>
  <div>
    <div class="mb-6 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <h2 class="text-xl font-semibold text-gray-900">Organizations ({{ orgs.length }})</h2>
      
      <input
        v-model="searchQuery"
        type="text"
        placeholder="Search organizations..."
        class="border rounded-lg px-4 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
      />
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-4">
      <p class="text-red-600">{{ error }}</p>
      <button @click="loadOrgs" class="mt-2 text-red-700 underline">Retry</button>
    </div>

    <!-- Empty State -->
    <div v-else-if="filteredOrgs.length === 0" class="text-center py-12 bg-gray-50 rounded-lg">
      <p class="text-gray-500">{{ orgs.length === 0 ? 'No organizations yet' : 'No organizations match your search' }}</p>
    </div>

    <!-- Organizations Grid -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="org in filteredOrgs"
        :key="org.id"
        @click="viewOrg(org.id)"
        class="bg-white rounded-xl shadow-sm border p-6 hover:shadow-md transition cursor-pointer"
      >
        <h3 class="text-lg font-semibold text-gray-900 mb-2">{{ org.name }}</h3>
        <p class="text-sm text-gray-500 mb-4 line-clamp-2">{{ org.description || 'No description' }}</p>
        
        <div class="grid grid-cols-3 gap-4 text-center border-t pt-4">
          <div>
            <p class="text-2xl font-bold text-indigo-600">{{ org.familyCount }}</p>
            <p class="text-xs text-gray-500">Families</p>
          </div>
          <div>
            <p class="text-2xl font-bold text-emerald-600">{{ org.studentCount }}</p>
            <p class="text-xs text-gray-500">Students</p>
          </div>
          <div>
            <p class="text-2xl font-bold text-amber-600">{{ org.logCount }}</p>
            <p class="text-xs text-gray-500">Logs</p>
          </div>
        </div>
        
        <div class="mt-4 text-sm text-gray-400">
          Created {{ formatDate(org.createdAt) }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getOrganization, type OrgDetail } from '../../api/admin'

const route = useRoute()
const router = useRouter()
const org = ref<OrgDetail | null>(null)
const loading = ref(true)
const error = ref('')

const orgId = route.params.id as string

async function loadOrg() {
  loading.value = true
  error.value = ''
  try {
    org.value = await getOrganization(orgId)
  } catch (e: any) {
    error.value = e.response?.data?.error || 'Failed to load organization'
  } finally {
    loading.value = false
  }
}

onMounted(loadOrg)

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleString()
}
</script>

<template>
  <div>
    <!-- Back Button -->
    <button
      @click="router.push('/admin/orgs')"
      class="mb-6 text-indigo-600 hover:text-indigo-800 text-sm"
    >
      ← Back to Organizations
    </button>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-4">
      <p class="text-red-600">{{ error }}</p>
      <button @click="loadOrg" class="mt-2 text-red-700 underline">Retry</button>
    </div>

    <!-- Org Detail -->
    <div v-else-if="org">
      <!-- Header -->
      <div class="bg-white rounded-xl shadow-sm border p-6 mb-6">
        <div class="flex items-start justify-between">
          <div>
            <h2 class="text-2xl font-bold text-gray-900">🏢 {{ org.name }}</h2>
            <p class="text-gray-500 mt-1">{{ org.description || 'No description' }}</p>
            <p class="text-sm text-gray-400 mt-2">ID: {{ org.id }}</p>
          </div>
          <div class="text-right">
            <p class="text-sm text-gray-500">Created</p>
            <p class="text-gray-900">{{ formatDate(org.createdAt) }}</p>
          </div>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Families</p>
          <p class="text-3xl font-bold text-indigo-600">{{ org.familyCount }}</p>
        </div>
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Students</p>
          <p class="text-3xl font-bold text-emerald-600">{{ org.studentCount }}</p>
        </div>
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Log Entries</p>
          <p class="text-3xl font-bold text-amber-600">{{ org.logCount.toLocaleString() }}</p>
        </div>
      </div>

      <!-- Families List -->
      <div class="bg-white rounded-xl shadow-sm border p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">👨‍👩‍👧‍👦 Member Families</h3>
        <div v-if="org.families.length === 0" class="text-gray-500 text-sm">
          No families in this organization yet
        </div>
        <div v-else class="space-y-2">
          <router-link
            v-for="family in org.families"
            :key="family.id"
            :to="`/admin/families/${family.id}`"
            class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
          >
            <div>
              <p class="font-medium text-gray-900">{{ family.name }}</p>
              <p class="text-sm text-gray-500">{{ family.studentCount }} student(s)</p>
            </div>
            <span class="text-indigo-600">View →</span>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

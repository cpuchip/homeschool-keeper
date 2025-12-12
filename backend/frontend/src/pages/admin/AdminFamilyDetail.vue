<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getFamily, updateFamilyPremium, type FamilyDetail } from '../../api/admin'

const route = useRoute()
const router = useRouter()
const family = ref<FamilyDetail | null>(null)
const loading = ref(true)
const error = ref('')
const saving = ref(false)

const familyId = route.params.id as string

async function loadFamily() {
  loading.value = true
  error.value = ''
  try {
    family.value = await getFamily(familyId)
  } catch (e: any) {
    error.value = e.response?.data?.error || 'Failed to load family'
  } finally {
    loading.value = false
  }
}

async function toggleSync() {
  if (!family.value) return
  saving.value = true
  try {
    await updateFamilyPremium(familyId, { syncEnabled: !family.value.premium.syncEnabled })
    await loadFamily()
  } catch (e: any) {
    error.value = e.response?.data?.error || 'Failed to update'
  } finally {
    saving.value = false
  }
}

async function toggleUploads() {
  if (!family.value) return
  saving.value = true
  try {
    await updateFamilyPremium(familyId, { uploadsEnabled: !family.value.premium.uploadsEnabled })
    await loadFamily()
  } catch (e: any) {
    error.value = e.response?.data?.error || 'Failed to update'
  } finally {
    saving.value = false
  }
}

onMounted(loadFamily)

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
    <!-- Back Button -->
    <button
      @click="router.push('/admin/families')"
      class="mb-6 text-indigo-600 hover:text-indigo-800 text-sm"
    >
      ← Back to Families
    </button>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-4">
      <p class="text-red-600">{{ error }}</p>
      <button @click="loadFamily" class="mt-2 text-red-700 underline">Retry</button>
    </div>

    <!-- Family Detail -->
    <div v-else-if="family">
      <!-- Header -->
      <div class="bg-white rounded-xl shadow-sm border p-6 mb-6">
        <div class="flex items-start justify-between">
          <div>
            <h2 class="text-2xl font-bold text-gray-900">{{ family.name }}</h2>
            <p class="text-gray-500">{{ family.state }} • Hour increment: {{ family.hourIncrement }}h</p>
            <p class="text-sm text-gray-400 mt-1">ID: {{ family.id }}</p>
          </div>
          <div class="text-right">
            <p class="text-sm text-gray-500">Created</p>
            <p class="text-gray-900">{{ formatDate(family.createdAt) }}</p>
          </div>
        </div>
      </div>

      <!-- Premium Settings -->
      <div class="bg-white rounded-xl shadow-sm border p-6 mb-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">🔐 Premium Settings</h3>
        <p class="text-sm text-gray-500 mb-4">Toggle features for this family during beta testing.</p>
        
        <div class="space-y-4">
          <!-- Sync Toggle -->
          <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
            <div>
              <p class="font-medium text-gray-900">Sync Enabled</p>
              <p class="text-sm text-gray-500">Allows syncing data across devices</p>
            </div>
            <button
              @click="toggleSync"
              :disabled="saving"
              :class="[
                'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none',
                family.premium.syncEnabled ? 'bg-indigo-600' : 'bg-gray-200'
              ]"
            >
              <span
                :class="[
                  'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
                  family.premium.syncEnabled ? 'translate-x-5' : 'translate-x-0'
                ]"
              ></span>
            </button>
          </div>

          <!-- Uploads Toggle -->
          <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
            <div>
              <p class="font-medium text-gray-900">File Uploads Enabled</p>
              <p class="text-sm text-gray-500">Allows uploading work samples to R2</p>
            </div>
            <button
              @click="toggleUploads"
              :disabled="saving"
              :class="[
                'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none',
                family.premium.uploadsEnabled ? 'bg-green-600' : 'bg-gray-200'
              ]"
            >
              <span
                :class="[
                  'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
                  family.premium.uploadsEnabled ? 'translate-x-5' : 'translate-x-0'
                ]"
              ></span>
            </button>
          </div>

          <!-- Storage Info -->
          <div class="p-4 bg-gray-50 rounded-lg">
            <div class="flex justify-between items-center">
              <div>
                <p class="font-medium text-gray-900">Storage Used</p>
                <p class="text-sm text-gray-500">{{ formatBytes(family.storageUsedBytes) }} of {{ formatBytes(family.premium.storageLimitBytes) }}</p>
              </div>
              <div class="text-right">
                <p class="text-2xl font-bold text-gray-900">{{ family.workSampleCount }}</p>
                <p class="text-sm text-gray-500">files</p>
              </div>
            </div>
            <div class="mt-3 bg-gray-200 rounded-full h-2">
              <div
                class="bg-emerald-500 rounded-full h-2"
                :style="{ width: `${Math.min((family.storageUsedBytes / family.premium.storageLimitBytes) * 100, 100)}%` }"
              ></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Students</p>
          <p class="text-3xl font-bold text-gray-900">{{ family.students.length }}</p>
        </div>
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Log Entries</p>
          <p class="text-3xl font-bold text-gray-900">{{ family.logCount.toLocaleString() }}</p>
        </div>
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Work Samples</p>
          <p class="text-3xl font-bold text-gray-900">{{ family.workSampleCount }}</p>
        </div>
      </div>

      <!-- Students List -->
      <div class="bg-white rounded-xl shadow-sm border p-6 mb-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">👨‍👩‍👧‍👦 Students</h3>
        <div v-if="family.students.length === 0" class="text-gray-500 text-sm">
          No students yet
        </div>
        <div v-else class="space-y-2">
          <div
            v-for="student in family.students"
            :key="student.id"
            class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
          >
            <div class="flex items-center gap-3">
              <span v-if="student.active" class="text-green-500">●</span>
              <span v-else class="text-gray-300">●</span>
              <span class="font-medium">{{ student.name }}</span>
            </div>
            <span class="text-sm text-gray-500">{{ student.logCount }} logs</span>
          </div>
        </div>
      </div>

      <!-- Organizations -->
      <div v-if="family.organizations.length > 0" class="bg-white rounded-xl shadow-sm border p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">🏢 Organizations</h3>
        <div class="space-y-2">
          <router-link
            v-for="org in family.organizations"
            :key="org.id"
            :to="`/admin/orgs/${org.id}`"
            class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
          >
            <span class="font-medium">{{ org.name }}</span>
            <span class="text-indigo-600">View →</span>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useLocationsStore } from '@/stores/locations'
import { BaseModal } from '@/components/common'
import { telemetry } from '@/api/telemetry'
import type { Location } from '@/types'

const authStore = useAuthStore()
const locationsStore = useLocationsStore()

// Family settings
const hourIncrement = ref(0.25)
const schoolYearStart = ref('')
const schoolYearEnd = ref('')
const timezone = ref('America/Chicago')

// User settings
const userName = ref('')
const userEmail = ref('')

// Telemetry settings
const telemetryEnabled = ref(true)

// Password change
const showPasswordModal = ref(false)
const currentPassword = ref('')
const newPassword = ref('')
const confirmPassword = ref('')

// Locations
const showLocationModal = ref(false)
const editingLocation = ref<Location | null>(null)
const locationName = ref('')
const locationType = ref('field_trip')
const locationAddress = ref('')
const savingLocation = ref(false)
const locationError = ref('')

const locations = computed(() => locationsStore.locations)

// UI state
const saving = ref(false)
const savingPassword = ref(false)
const successMessage = ref('')
const errorMessage = ref('')
const passwordError = ref('')

const user = computed(() => authStore.user)
const family = computed(() => authStore.family)

// Common timezones
const timezones = [
  { value: 'America/New_York', label: 'Eastern Time (New York)' },
  { value: 'America/Chicago', label: 'Central Time (Chicago)' },
  { value: 'America/Denver', label: 'Mountain Time (Denver)' },
  { value: 'America/Phoenix', label: 'Arizona (Phoenix)' },
  { value: 'America/Los_Angeles', label: 'Pacific Time (Los Angeles)' },
  { value: 'America/Anchorage', label: 'Alaska (Anchorage)' },
  { value: 'Pacific/Honolulu', label: 'Hawaii (Honolulu)' },
]

async function saveSettings() {
  saving.value = true
  successMessage.value = ''
  errorMessage.value = ''

  try {
    // TODO: API call to update family settings
    // await familyApi.update({
    //   hourIncrement: hourIncrement.value,
    //   schoolYearStart: schoolYearStart.value,
    //   schoolYearEnd: schoolYearEnd.value,
    //   timezone: timezone.value
    // })
    
    // For now, just simulate success
    await new Promise(resolve => setTimeout(resolve, 500))
    
    successMessage.value = 'Settings saved successfully!'
    setTimeout(() => {
      successMessage.value = ''
    }, 3000)
  } catch (err: unknown) {
    errorMessage.value = err instanceof Error ? err.message : 'Failed to save settings'
  } finally {
    saving.value = false
  }
}

async function changePassword() {
  passwordError.value = ''
  
  if (newPassword.value.length < 8) {
    passwordError.value = 'Password must be at least 8 characters'
    return
  }
  
  if (newPassword.value !== confirmPassword.value) {
    passwordError.value = 'Passwords do not match'
    return
  }

  savingPassword.value = true

  try {
    // TODO: API call to change password
    // await authApi.changePassword({
    //   currentPassword: currentPassword.value,
    //   newPassword: newPassword.value
    // })
    
    await new Promise(resolve => setTimeout(resolve, 500))
    
    showPasswordModal.value = false
    currentPassword.value = ''
    newPassword.value = ''
    confirmPassword.value = ''
    successMessage.value = 'Password changed successfully!'
    setTimeout(() => {
      successMessage.value = ''
    }, 3000)
  } catch (err: unknown) {
    passwordError.value = err instanceof Error ? err.message : 'Failed to change password'
  } finally {
    savingPassword.value = false
  }
}

// Helper function to extract YYYY-MM-DD from ISO date string
function formatDateForInput(isoDate: string): string {
  if (!isoDate) return ''
  // Handle both ISO format "2025-08-01T00:00:00Z" and simple "2025-08-01"
  return isoDate.split('T')[0]
}

// Location type display names
const locationTypeLabels: Record<string, string> = {
  field_trip: 'Field Trip',
  co_op: 'Co-op',
  other: 'Other',
}

function openAddLocation() {
  editingLocation.value = null
  locationName.value = ''
  locationType.value = 'field_trip'
  locationAddress.value = ''
  locationError.value = ''
  showLocationModal.value = true
}

function openEditLocation(location: Location) {
  editingLocation.value = location
  locationName.value = location.name
  locationType.value = location.type
  locationAddress.value = location.address || ''
  locationError.value = ''
  showLocationModal.value = true
}

async function saveLocation() {
  if (!locationName.value.trim()) {
    locationError.value = 'Name is required'
    return
  }

  savingLocation.value = true
  locationError.value = ''

  try {
    if (editingLocation.value) {
      // Update existing
      await locationsStore.updateLocation(editingLocation.value.id, {
        name: locationName.value.trim(),
        type: locationType.value,
        address: locationAddress.value.trim() || undefined,
      })
    } else {
      // Create new
      await locationsStore.createLocation({
        name: locationName.value.trim(),
        type: locationType.value,
        address: locationAddress.value.trim() || undefined,
      })
    }
    showLocationModal.value = false
  } catch (e: unknown) {
    locationError.value = e instanceof Error ? e.message : 'Failed to save location'
  } finally {
    savingLocation.value = false
  }
}

async function deleteLocation(location: Location) {
  if (!confirm(`Delete location "${location.name}"?`)) return
  
  try {
    await locationsStore.deleteLocation(location.id)
  } catch (e) {
    errorMessage.value = 'Failed to delete location'
  }
}

onMounted(() => {
  // Load current settings
  if (user.value) {
    userName.value = user.value.name
    userEmail.value = user.value.email
  }
  
  if (family.value) {
    hourIncrement.value = family.value.hourIncrement ?? 0.25
    schoolYearStart.value = formatDateForInput(family.value.schoolYearStart)
    schoolYearEnd.value = formatDateForInput(family.value.schoolYearEnd)
    timezone.value = family.value.timezone ?? 'America/Chicago'
  }

  // Load telemetry preference
  telemetryEnabled.value = telemetry.isEnabled

  // Load saved locations
  locationsStore.fetchLocations()
})

function toggleTelemetry() {
  telemetryEnabled.value = !telemetryEnabled.value
  telemetry.setEnabled(telemetryEnabled.value)
}
</script>

<template>
  <div class="space-y-6 max-w-2xl">
    <h1 class="text-2xl font-bold text-gray-900">Settings</h1>

    <!-- Success/Error messages -->
    <div v-if="successMessage" class="p-3 bg-green-100 border border-green-200 text-green-700 rounded-lg">
      {{ successMessage }}
    </div>
    <div v-if="errorMessage" class="p-3 bg-red-100 border border-red-200 text-red-700 rounded-lg">
      {{ errorMessage }}
    </div>

    <!-- Family Settings -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Family Settings</h2>
      
      <div class="space-y-4">
        <div>
          <label class="label">Family Name</label>
          <p class="mt-1 text-gray-900">{{ family?.name || 'Not set' }}</p>
        </div>
        
        <div>
          <label class="label">Hour Increment</label>
          <p class="text-xs text-gray-500 mb-2">How should hours be rounded when logging?</p>
          <div class="mt-2 flex flex-wrap gap-4">
            <label class="flex items-center cursor-pointer">
              <input 
                v-model.number="hourIncrement" 
                type="radio" 
                name="increment" 
                :value="0.25" 
                class="h-4 w-4 text-primary-600"
              />
              <span class="ml-2 text-sm">15 min (0.25)</span>
            </label>
            <label class="flex items-center cursor-pointer">
              <input 
                v-model.number="hourIncrement" 
                type="radio" 
                name="increment" 
                :value="0.5" 
                class="h-4 w-4 text-primary-600"
              />
              <span class="ml-2 text-sm">30 min (0.5)</span>
            </label>
            <label class="flex items-center cursor-pointer">
              <input 
                v-model.number="hourIncrement" 
                type="radio" 
                name="increment" 
                :value="1" 
                class="h-4 w-4 text-primary-600"
              />
              <span class="ml-2 text-sm">1 hour (1.0)</span>
            </label>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label class="label">School Year Start</label>
            <input v-model="schoolYearStart" type="date" class="mt-1 input" />
          </div>
          <div>
            <label class="label">School Year End</label>
            <input v-model="schoolYearEnd" type="date" class="mt-1 input" />
          </div>
        </div>

        <div>
          <label class="label">Timezone</label>
          <select v-model="timezone" class="mt-1 input">
            <option v-for="tz in timezones" :key="tz.value" :value="tz.value">
              {{ tz.label }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <!-- Account Settings -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Account Settings</h2>
      
      <div class="space-y-4">
        <div>
          <label class="label">Name</label>
          <p class="mt-1 text-gray-900">{{ userName || 'Not set' }}</p>
        </div>
        <div>
          <label class="label">Email</label>
          <p class="mt-1 text-gray-900">{{ userEmail || 'Not set' }}</p>
        </div>
        <div>
          <label class="label">Role</label>
          <p class="mt-1 text-gray-900 capitalize">{{ user?.role || 'Unknown' }}</p>
        </div>
        <div>
          <button 
            type="button"
            class="btn-secondary"
            @click="showPasswordModal = true"
          >
            Change Password
          </button>
        </div>
      </div>
    </div>

    <!-- Saved Locations -->
    <div class="card">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-medium text-gray-900">Saved Locations</h2>
        <button 
          type="button"
          class="btn-secondary text-sm"
          @click="openAddLocation"
        >
          + Add Location
        </button>
      </div>
      <p class="text-sm text-gray-600 mb-4">
        Save frequently-used locations like field trip destinations, co-op meeting places, and more for quick selection when logging hours.
      </p>
      
      <!-- Locations list -->
      <div v-if="locations.length > 0" class="space-y-2">
        <div 
          v-for="location in locations" 
          :key="location.id"
          class="flex items-center justify-between p-3 bg-gray-50 rounded-lg border border-gray-200"
        >
          <div>
            <div class="font-medium text-gray-900">{{ location.name }}</div>
            <div class="text-sm text-gray-500">
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                {{ locationTypeLabels[location.type] || location.type }}
              </span>
              <span v-if="location.address" class="ml-2">{{ location.address }}</span>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <button 
              type="button"
              class="text-gray-500 hover:text-gray-700"
              @click="openEditLocation(location)"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
            </button>
            <button 
              type="button"
              class="text-red-500 hover:text-red-700"
              @click="deleteLocation(location)"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </div>
      </div>
      <div v-else class="text-center py-8 text-gray-500">
        <p>No saved locations yet.</p>
        <p class="text-sm mt-1">Add locations like "Science Museum" or "Co-op Meeting Room".</p>
      </div>
    </div>

    <!-- State Requirements Info -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">State Requirements</h2>
      <p class="text-sm text-gray-600 mb-4">
        Your homeschool is set up for <strong>Missouri</strong> requirements.
      </p>
      <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <h3 class="text-sm font-medium text-blue-800 mb-2">Missouri Requirements:</h3>
        <ul class="text-sm text-blue-700 list-disc list-inside space-y-1">
          <li>1,000 hours per year minimum</li>
          <li>600 hours in core subjects (Reading, Math, Social Studies, Language Arts, Science)</li>
          <li>At least 400 hours at regular home location</li>
        </ul>
      </div>
    </div>

    <!-- Data Management -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Data Management</h2>
      <div class="space-y-4">
        <router-link 
          to="/export" 
          class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100"
        >
          <div>
            <h3 class="font-medium text-gray-900">Export Data</h3>
            <p class="text-sm text-gray-500">Download PDF reports or CSV exports for state compliance</p>
          </div>
          <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </router-link>
        <router-link 
          to="/trash" 
          class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100"
        >
          <div>
            <h3 class="font-medium text-gray-900">Trash</h3>
            <p class="text-sm text-gray-500">View and restore deleted students and subjects</p>
          </div>
          <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </router-link>
      </div>
    </div>

    <!-- Privacy & Analytics -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Privacy & Analytics</h2>
      <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
        <div>
          <h3 class="font-medium text-gray-900">Share Anonymous Usage Data</h3>
          <p class="text-sm text-gray-500">
            Help improve the app by sharing anonymous usage statistics.
            We never collect personal information about you or your students.
          </p>
        </div>
        <button
          @click="toggleTelemetry"
          :class="[
            'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none',
            telemetryEnabled ? 'bg-primary-600' : 'bg-gray-200'
          ]"
        >
          <span
            :class="[
              'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
              telemetryEnabled ? 'translate-x-5' : 'translate-x-0'
            ]"
          ></span>
        </button>
      </div>
    </div>

    <!-- Save Button -->
    <div class="flex justify-end">
      <button 
        type="button"
        class="btn-primary disabled:opacity-50"
        :disabled="saving"
        @click="saveSettings"
      >
        {{ saving ? 'Saving...' : 'Save Changes' }}
      </button>
    </div>

    <!-- Password Change Modal -->
    <BaseModal v-model:open="showPasswordModal" title="Change Password">
      <div class="space-y-4">
        <div v-if="passwordError" class="p-3 bg-red-100 border border-red-200 text-red-700 rounded-lg text-sm">
          {{ passwordError }}
        </div>
        
        <div>
          <label class="label">Current Password</label>
          <input 
            v-model="currentPassword" 
            type="password" 
            class="mt-1 input"
            autocomplete="current-password"
          />
        </div>
        <div>
          <label class="label">New Password</label>
          <input 
            v-model="newPassword" 
            type="password" 
            class="mt-1 input"
            autocomplete="new-password"
          />
          <p class="mt-1 text-xs text-gray-500">Minimum 8 characters</p>
        </div>
        <div>
          <label class="label">Confirm New Password</label>
          <input 
            v-model="confirmPassword" 
            type="password" 
            class="mt-1 input"
            autocomplete="new-password"
          />
        </div>
      </div>
      <template #footer>
        <button type="button" class="btn-secondary" @click="showPasswordModal = false">
          Cancel
        </button>
        <button 
          type="button" 
          class="btn-primary"
          :disabled="savingPassword"
          @click="changePassword"
        >
          {{ savingPassword ? 'Changing...' : 'Change Password' }}
        </button>
      </template>
    </BaseModal>

    <!-- Location Modal -->
    <BaseModal v-model:open="showLocationModal" :title="editingLocation ? 'Edit Location' : 'Add Location'">
      <div class="space-y-4">
        <div v-if="locationError" class="p-3 bg-red-100 border border-red-200 text-red-700 rounded-lg text-sm">
          {{ locationError }}
        </div>
        
        <div>
          <label class="label">Location Name <span class="text-red-500">*</span></label>
          <input 
            v-model="locationName" 
            type="text" 
            class="mt-1 input"
            placeholder="e.g., Science Museum, Library"
          />
        </div>
        <div>
          <label class="label">Location Type <span class="text-red-500">*</span></label>
          <select v-model="locationType" class="mt-1 input">
            <option value="field_trip">Field Trip</option>
            <option value="co_op">Co-op</option>
            <option value="other">Other</option>
          </select>
        </div>
        <div>
          <label class="label">Address (optional)</label>
          <input 
            v-model="locationAddress" 
            type="text" 
            class="mt-1 input"
            placeholder="e.g., 123 Main St, City, State"
          />
        </div>
      </div>
      <template #footer>
        <button type="button" class="btn-secondary" @click="showLocationModal = false">
          Cancel
        </button>
        <button 
          type="button" 
          class="btn-primary"
          :disabled="savingLocation"
          @click="saveLocation"
        >
          {{ savingLocation ? 'Saving...' : (editingLocation ? 'Update' : 'Add Location') }}
        </button>
      </template>
    </BaseModal>
  </div>
</template>

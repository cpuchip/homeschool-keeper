<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { BaseModal } from '@/components/common'

const authStore = useAuthStore()

// Family settings
const hourIncrement = ref(0.25)
const schoolYearStart = ref('')
const schoolYearEnd = ref('')
const timezone = ref('America/Chicago')

// User settings
const userName = ref('')
const userEmail = ref('')

// Password change
const showPasswordModal = ref(false)
const currentPassword = ref('')
const newPassword = ref('')
const confirmPassword = ref('')

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
})
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
  </div>
</template>

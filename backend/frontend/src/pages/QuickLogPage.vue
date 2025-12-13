<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useStudentsStore } from '@/stores/students'
import { useSubjectsStore } from '@/stores/subjects'
import { useLogsStore } from '@/stores/logs'
import { useAuthStore } from '@/stores/auth'
import { telemetry, TelemetryEvents } from '@/api/telemetry'

const router = useRouter()
const studentsStore = useStudentsStore()
const subjectsStore = useSubjectsStore()
const logsStore = useLogsStore()
const authStore = useAuthStore()

const studentId = ref('')
const selectedStudentIds = ref<string[]>([])
const subjectId = ref('')
const hours = ref(1)
const description = ref('')
const date = ref(new Date().toISOString().split('T')[0])
const location = ref<'home' | 'other'>('home')
const saving = ref(false)
const error = ref('')
const success = ref('')

// Get hour increment from family settings (default 0.25)
const hourIncrement = computed(() => authStore.family?.hourIncrement ?? 0.25)

// Active students and subjects for dropdowns
const activeStudents = computed(() => studentsStore.activeStudents)
const activeSubjects = computed(() => subjectsStore.activeSubjects)

// Group subjects by type for better UX
const coreSubjects = computed(() => 
  activeSubjects.value.filter(s => s.type === 'core')
)
const electiveSubjects = computed(() => 
  activeSubjects.value.filter(s => s.type === 'elective')
)

function incrementHours() {
  hours.value = Math.min(24, Math.round((hours.value + hourIncrement.value) * 100) / 100)
}

function decrementHours() {
  hours.value = Math.max(hourIncrement.value, Math.round((hours.value - hourIncrement.value) * 100) / 100)
}

function setHours(value: number) {
  hours.value = value
}

function resetForm() {
  studentId.value = ''
  selectedStudentIds.value = []
  subjectId.value = ''
  hours.value = 1
  description.value = ''
  date.value = new Date().toISOString().split('T')[0]
  location.value = 'home'
  success.value = ''
  error.value = ''
}

function toggleStudent(id: string) {
  const index = selectedStudentIds.value.indexOf(id)
  if (index === -1) {
    selectedStudentIds.value.push(id)
  } else {
    selectedStudentIds.value.splice(index, 1)
  }
}

function selectAllStudents() {
  selectedStudentIds.value = activeStudents.value.map(s => s.id)
}

function clearAllStudents() {
  selectedStudentIds.value = []
}

async function handleSubmit(addAnother = false) {
  if (selectedStudentIds.value.length === 0 || !subjectId.value) {
    error.value = 'Please select at least one student and a subject'
    return
  }

  saving.value = true
  error.value = ''
  success.value = ''

  try {
    const result = await logsStore.createMultiStudentLog({
      studentIds: selectedStudentIds.value,
      subjectId: subjectId.value,
      hours: hours.value,
      description: description.value,
      date: date.value,
      locationType: location.value === 'home' ? 'home' : 'other'
    })

    // Track log creation
    telemetry.trackEvent(TelemetryEvents.LOG_CREATED, { count: result.length })

    if (addAnother) {
      // Reset form but keep students/date for convenience
      const currentStudents = [...selectedStudentIds.value]
      const currentDate = date.value
      resetForm()
      selectedStudentIds.value = currentStudents
      date.value = currentDate
      success.value = result.length === 1 
        ? 'Log saved! Add another entry.'
        : `${result.length} logs saved! Add another entry.`
    } else {
      // Go to logs page
      router.push('/logs')
    }
  } catch (err: unknown) {
    error.value = err instanceof Error ? err.message : 'Failed to save log'
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  // Load students and subjects if not already loaded
  if (studentsStore.students.length === 0) {
    await studentsStore.fetchStudents()
  }
  if (subjectsStore.subjects.length === 0) {
    await subjectsStore.fetchSubjects()
  }
  
  // Auto-select if only one student
  if (activeStudents.value.length === 1) {
    selectedStudentIds.value = [activeStudents.value[0].id]
  }
})
</script>

<template>
  <div class="max-w-2xl mx-auto">
    <h1 class="text-2xl font-bold text-gray-900 mb-6">Quick Log</h1>

    <!-- Past year warning -->
    <div v-if="authStore.isViewingPastYear" class="mb-4 p-4 bg-amber-50 border border-amber-200 text-amber-800 rounded-lg flex items-center gap-3">
      <span class="text-xl">📁</span>
      <div>
        <p class="font-medium">Viewing archived year: {{ authStore.effectiveSchoolYear }}</p>
        <p class="text-sm">New entries will still be added to this year. Switch to the current year for regular logging.</p>
      </div>
    </div>

    <!-- Success/Error messages -->
    <div v-if="success" class="mb-4 p-3 bg-green-100 border border-green-200 text-green-700 rounded-lg">
      {{ success }}
    </div>
    <div v-if="error" class="mb-4 p-3 bg-red-100 border border-red-200 text-red-700 rounded-lg">
      {{ error }}
    </div>

    <form class="card space-y-6" @submit.prevent="handleSubmit(false)">
      <!-- Students (multi-select with chips) -->
      <div>
        <div class="flex items-center justify-between mb-2">
          <label class="label">Students</label>
          <div v-if="activeStudents.length > 1" class="flex gap-2">
            <button
              type="button"
              class="text-sm text-blue-600 hover:text-blue-800"
              @click="selectedStudentIds.length === activeStudents.length ? clearAllStudents() : selectAllStudents()"
            >
              {{ selectedStudentIds.length === activeStudents.length ? 'Clear All' : 'Select All' }}
            </button>
          </div>
        </div>
        <div class="flex flex-wrap gap-2">
          <button
            v-for="student in activeStudents"
            :key="student.id"
            type="button"
            :class="[
              'px-3 py-2 rounded-full text-sm font-medium transition-colors',
              selectedStudentIds.includes(student.id)
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
            @click="toggleStudent(student.id)"
          >
            {{ student.name }}
            <span v-if="selectedStudentIds.includes(student.id)" class="ml-1">✓</span>
          </button>
        </div>
        <p v-if="selectedStudentIds.length > 1" class="mt-2 text-sm text-blue-600">
          {{ selectedStudentIds.length }} students selected — will create {{ selectedStudentIds.length }} log entries
        </p>
      </div>

      <!-- Subject -->
      <div>
        <label for="subject" class="label">Subject</label>
        <select id="subject" v-model="subjectId" class="mt-1 input" required>
          <option value="">Select a subject</option>
          <optgroup v-if="coreSubjects.length > 0" label="Core Subjects">
            <option v-for="subject in coreSubjects" :key="subject.id" :value="subject.id">
              {{ subject.name }}
            </option>
          </optgroup>
          <optgroup v-if="electiveSubjects.length > 0" label="Electives">
            <option v-for="subject in electiveSubjects" :key="subject.id" :value="subject.id">
              {{ subject.name }}
            </option>
          </optgroup>
        </select>
      </div>

      <!-- Hours -->
      <div>
        <label class="label">Hours</label>
        <div class="mt-2 flex items-center justify-center space-x-4">
          <button
            type="button"
            class="w-12 h-12 rounded-full bg-gray-200 hover:bg-gray-300 text-2xl font-bold disabled:opacity-50"
            :disabled="hours <= hourIncrement"
            @click="decrementHours"
          >
            −
          </button>
          <div class="text-4xl font-bold w-24 text-center">
            {{ hours }}
          </div>
          <button
            type="button"
            class="w-12 h-12 rounded-full bg-gray-200 hover:bg-gray-300 text-2xl font-bold disabled:opacity-50"
            :disabled="hours >= 24"
            @click="incrementHours"
          >
            +
          </button>
        </div>
        <!-- Quick presets -->
        <div class="mt-4 flex justify-center space-x-2">
          <button
            v-for="preset in [0.5, 1, 1.5, 2, 3]"
            :key="preset"
            type="button"
            :class="[
              'px-3 py-1 rounded-full text-sm transition-colors',
              hours === preset
                ? 'bg-primary-600 text-white'
                : 'bg-gray-100 hover:bg-gray-200 text-gray-700'
            ]"
            @click="setHours(preset)"
          >
            {{ preset }}h
          </button>
        </div>
      </div>

      <!-- Date -->
      <div>
        <label for="date" class="label">Date</label>
        <input
          id="date"
          v-model="date"
          type="date"
          class="mt-1 input"
          required
        />
      </div>

      <!-- Location -->
      <div>
        <label class="label">Location</label>
        <div class="mt-2 flex space-x-4">
          <label class="flex items-center cursor-pointer">
            <input
              v-model="location"
              type="radio"
              value="home"
              class="h-4 w-4 text-primary-600 focus:ring-primary-500"
            />
            <span class="ml-2 text-sm text-gray-700">At Home</span>
          </label>
          <label class="flex items-center cursor-pointer">
            <input
              v-model="location"
              type="radio"
              value="other"
              class="h-4 w-4 text-primary-600 focus:ring-primary-500"
            />
            <span class="ml-2 text-sm text-gray-700">Other Location</span>
          </label>
        </div>
      </div>

      <!-- Description -->
      <div>
        <label for="description" class="label">Description</label>
        <textarea
          id="description"
          v-model="description"
          rows="3"
          class="mt-1 input"
          placeholder="What did they learn today?"
        ></textarea>
      </div>

      <!-- Submit -->
      <div class="flex space-x-4">
        <button 
          type="submit" 
          class="flex-1 btn-primary disabled:opacity-50"
          :disabled="saving"
        >
          {{ saving ? 'Saving...' : 'Save Log' }}
        </button>
        <button 
          type="button" 
          class="flex-1 btn-secondary disabled:opacity-50"
          :disabled="saving"
          @click="handleSubmit(true)"
        >
          Save & Add Another
        </button>
      </div>
    </form>
  </div>
</template>

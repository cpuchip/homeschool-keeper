<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { onboardingApi, type SubjectOption } from '@/api/onboarding'

const router = useRouter()
const authStore = useAuthStore()

// Onboarding steps
const currentStep = ref(1)
const totalSteps = 4

// Step 1: State & Timezone
const state = ref('MO') // Default to Missouri
const timezone = ref(Intl.DateTimeFormat().resolvedOptions().timeZone)

// Step 2: School Year
const schoolYearStart = ref('')
const schoolYearEnd = ref('')

// Step 3: Subjects - SubjectOption type imported from @/api/onboarding
const availableSubjects = ref<SubjectOption[]>([])
const selectedSubjects = ref<string[]>([])  // Store just the names for selection

// Step 4: First Student
const students = ref<Array<{ name: string; gradeLevel: string }>>([
  { name: '', gradeLevel: '' }
])

const loading = ref(false)
const error = ref('')

// US States
const usStates = [
  { value: 'MO', label: 'Missouri' },
  { value: 'KS', label: 'Kansas' },
  { value: 'IL', label: 'Illinois' },
  { value: 'TX', label: 'Texas' },
  { value: 'FL', label: 'Florida' },
  { value: 'CA', label: 'California' },
  // Add more as needed
]

// Grade levels
const gradeLevels = [
  'Pre-K', 'Kindergarten',
  '1st Grade', '2nd Grade', '3rd Grade', '4th Grade', '5th Grade',
  '6th Grade', '7th Grade', '8th Grade',
  '9th Grade', '10th Grade', '11th Grade', '12th Grade'
]

// Hour increment options
const hourIncrement = ref(0.25)
const hourIncrementOptions = [
  { value: 0.25, label: '15 minutes (0.25 hours)' },
  { value: 0.5, label: '30 minutes (0.5 hours)' },
  { value: 1.0, label: '1 hour' }
]

onMounted(async () => {
  // Set default school year dates
  const now = new Date()
  const year = now.getMonth() >= 7 ? now.getFullYear() : now.getFullYear() - 1
  schoolYearStart.value = `${year}-08-01`
  schoolYearEnd.value = `${year + 1}-05-31`

  // Load default subjects for state
  await loadSubjects()
})

async function loadSubjects() {
  try {
    const subjects = await onboardingApi.getDefaultSubjects(state.value)
    availableSubjects.value = subjects
    // Select all by default
    selectedSubjects.value = subjects.map(s => s.name)
  } catch {
    // Use fallback subjects
    availableSubjects.value = [
      { name: 'Math', type: 'core', color: '#10B981' },
      { name: 'Language Arts', type: 'core', color: '#F59E0B' },
      { name: 'Reading', type: 'core', color: '#3B82F6' },
      { name: 'Science', type: 'core', color: '#8B5CF6' },
      { name: 'Social Studies', type: 'core', color: '#EC4899' },
      { name: 'Art', type: 'elective', color: '#06B6D4' },
      { name: 'Music', type: 'elective', color: '#F97316' },
      { name: 'Physical Education', type: 'elective', color: '#84CC16' },
      { name: 'Health', type: 'elective', color: '#14B8A6' }
    ]
    selectedSubjects.value = ['Math', 'Language Arts', 'Reading', 'Science', 'Social Studies']
  }
}

function nextStep() {
  if (currentStep.value < totalSteps) {
    currentStep.value++
  }
}

function prevStep() {
  if (currentStep.value > 1) {
    currentStep.value--
  }
}

// Custom subject
const newSubjectName = ref('')
const newSubjectType = ref<'core' | 'elective'>('elective')

// Available colors for custom subjects
const subjectColors = [
  '#10B981', '#F59E0B', '#3B82F6', '#8B5CF6', '#EC4899',
  '#06B6D4', '#F97316', '#84CC16', '#14B8A6', '#EF4444'
]

function addCustomSubject() {
  const name = newSubjectName.value.trim()
  if (!name) return
  
  // Check if subject already exists
  if (availableSubjects.value.some(s => s.name.toLowerCase() === name.toLowerCase())) {
    return
  }
  
  // Pick a random color from available colors
  const usedColors = availableSubjects.value.map(s => s.color)
  const availableColors = subjectColors.filter(c => !usedColors.includes(c))
  const color = availableColors.length > 0 
    ? availableColors[Math.floor(Math.random() * availableColors.length)]
    : subjectColors[Math.floor(Math.random() * subjectColors.length)]
  
  // Add new subject
  const newSubject = {
    name,
    type: newSubjectType.value,
    color
  }
  availableSubjects.value.push(newSubject)
  selectedSubjects.value.push(name)
  
  // Clear input
  newSubjectName.value = ''
}

function removeCustomSubject(subjectName: string) {
  // Remove from available subjects
  const index = availableSubjects.value.findIndex(s => s.name === subjectName)
  if (index !== -1) {
    availableSubjects.value.splice(index, 1)
  }
  // Remove from selected subjects
  const selectedIndex = selectedSubjects.value.indexOf(subjectName)
  if (selectedIndex !== -1) {
    selectedSubjects.value.splice(selectedIndex, 1)
  }
}

function addStudent() {
  students.value.push({ name: '', gradeLevel: '' })
}

function removeStudent(index: number) {
  if (students.value.length > 1) {
    students.value.splice(index, 1)
  }
}

function toggleSubject(subject: string) {
  const index = selectedSubjects.value.indexOf(subject)
  if (index === -1) {
    selectedSubjects.value.push(subject)
  } else {
    selectedSubjects.value.splice(index, 1)
  }
}

async function completeOnboarding() {
  loading.value = true
  error.value = ''

  try {
    // Filter out empty students
    const validStudents = students.value.filter(s => s.name.trim())

    const response = await onboardingApi.complete({
      familyName: authStore.family?.name || '',
      state: state.value,
      timezone: timezone.value,
      schoolYearStart: schoolYearStart.value,
      schoolYearEnd: schoolYearEnd.value,
      hourIncrement: hourIncrement.value,
      subjects: selectedSubjects.value,
      students: validStudents
    })

    // Update family in store
    authStore.updateFamily(response.family)

    // Navigate to dashboard
    router.push('/')
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    error.value = err.response?.data?.error || 'Failed to complete setup'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 py-12 px-4">
    <div class="max-w-2xl mx-auto">
      <!-- Header -->
      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Welcome to Home School Logs! 📚</h1>
        <p class="mt-2 text-gray-600">Let's set up your family's homeschool tracking.</p>
      </div>

      <!-- Progress -->
      <div class="mb-8">
        <div class="flex justify-between text-sm text-gray-600 mb-2">
          <span>Step {{ currentStep }} of {{ totalSteps }}</span>
          <span>{{ Math.round((currentStep / totalSteps) * 100) }}% complete</span>
        </div>
        <div class="h-2 bg-gray-200 rounded-full">
          <div 
            class="h-2 bg-primary-600 rounded-full transition-all duration-300"
            :style="{ width: `${(currentStep / totalSteps) * 100}%` }"
          ></div>
        </div>
      </div>

      <!-- Error -->
      <div v-if="error" class="mb-6 rounded-md bg-red-50 p-4">
        <p class="text-sm text-red-700">{{ error }}</p>
      </div>

      <!-- Step 1: Location -->
      <div v-if="currentStep === 1" class="bg-white rounded-lg shadow p-6">
        <h2 class="text-xl font-semibold mb-4">Where are you located?</h2>
        <p class="text-gray-600 mb-6">This helps us show you state-specific requirements.</p>

        <div class="space-y-4">
          <div>
            <label for="state" class="block text-sm font-medium text-gray-700">State</label>
            <select id="state" v-model="state" @change="loadSubjects" class="mt-1 input">
              <option v-for="s in usStates" :key="s.value" :value="s.value">
                {{ s.label }}
              </option>
            </select>
          </div>

          <div>
            <label for="timezone" class="block text-sm font-medium text-gray-700">Timezone</label>
            <input 
              id="timezone" 
              v-model="timezone" 
              type="text" 
              readonly
              class="mt-1 input bg-gray-50"
            />
            <p class="mt-1 text-xs text-gray-500">Detected from your browser</p>
          </div>
        </div>
      </div>

      <!-- Step 2: School Year -->
      <div v-if="currentStep === 2" class="bg-white rounded-lg shadow p-6">
        <h2 class="text-xl font-semibold mb-4">Define your school year</h2>
        <p class="text-gray-600 mb-6">When does your school year start and end?</p>

        <div class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label for="yearStart" class="block text-sm font-medium text-gray-700">Start Date</label>
              <input 
                id="yearStart" 
                v-model="schoolYearStart" 
                type="date" 
                class="mt-1 input"
              />
            </div>
            <div>
              <label for="yearEnd" class="block text-sm font-medium text-gray-700">End Date</label>
              <input 
                id="yearEnd" 
                v-model="schoolYearEnd" 
                type="date" 
                class="mt-1 input"
              />
            </div>
          </div>

          <div>
            <label for="hourIncrement" class="block text-sm font-medium text-gray-700">
              Hour Increment
            </label>
            <select id="hourIncrement" v-model="hourIncrement" class="mt-1 input">
              <option v-for="opt in hourIncrementOptions" :key="opt.value" :value="opt.value">
                {{ opt.label }}
              </option>
            </select>
            <p class="mt-1 text-xs text-gray-500">
              How precisely do you want to track time?
            </p>
          </div>
        </div>
      </div>

      <!-- Step 3: Subjects -->
      <div v-if="currentStep === 3" class="bg-white rounded-lg shadow p-6">
        <h2 class="text-xl font-semibold mb-4">Choose your subjects</h2>
        <p class="text-gray-600 mb-6">Select the subjects you'll be teaching, or add your own custom subjects.</p>

        <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
          <button
            v-for="subject in availableSubjects"
            :key="subject.name"
            type="button"
            @click="toggleSubject(subject.name)"
            :class="[
              'px-4 py-3 rounded-lg text-sm font-medium transition-all relative group',
              selectedSubjects.includes(subject.name)
                ? 'ring-2 ring-offset-2 shadow-md'
                : 'hover:shadow-md border-2 border-transparent'
            ]"
            :style="{
              backgroundColor: selectedSubjects.includes(subject.name) ? subject.color + '20' : '#f3f4f6',
              color: selectedSubjects.includes(subject.name) ? subject.color : '#374151',
              '--tw-ring-color': subject.color
            }"
          >
            <span class="flex items-center justify-center gap-2">
              <span 
                class="w-3 h-3 rounded-full" 
                :style="{ backgroundColor: subject.color }"
              ></span>
              {{ subject.name }}
            </span>
            <span class="text-xs opacity-75 mt-1 block">{{ subject.type }}</span>
            <!-- Remove button for custom subjects (not default ones) -->
            <button
              v-if="!['Math', 'Language Arts', 'Reading', 'Science', 'Social Studies', 'Art', 'Music', 'Physical Education', 'Health'].includes(subject.name)"
              type="button"
              @click.stop="removeCustomSubject(subject.name)"
              class="absolute -top-2 -right-2 w-5 h-5 bg-red-500 text-white rounded-full text-xs opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center"
            >
              ✕
            </button>
          </button>
        </div>

        <!-- Add Custom Subject -->
        <div class="mt-6 p-4 bg-gray-50 rounded-lg">
          <h3 class="text-sm font-medium text-gray-700 mb-3">Add Custom Subject</h3>
          <div class="flex gap-3">
            <input
              v-model="newSubjectName"
              type="text"
              placeholder="Subject name (e.g., Spanish, Coding)"
              class="input flex-1"
              @keyup.enter="addCustomSubject"
            />
            <select v-model="newSubjectType" class="input w-32">
              <option value="core">Core</option>
              <option value="elective">Elective</option>
            </select>
            <button
              type="button"
              @click="addCustomSubject"
              :disabled="!newSubjectName.trim()"
              class="btn-primary px-4"
            >
              Add
            </button>
          </div>
        </div>

        <p class="mt-4 text-sm text-gray-500">
          {{ selectedSubjects.length }} subjects selected
        </p>
      </div>

      <!-- Step 4: Students -->
      <div v-if="currentStep === 4" class="bg-white rounded-lg shadow p-6">
        <h2 class="text-xl font-semibold mb-4">Add your students</h2>
        <p class="text-gray-600 mb-6">Who will you be teaching?</p>

        <div class="space-y-4">
          <div 
            v-for="(student, index) in students" 
            :key="index"
            class="flex gap-3 items-start"
          >
            <div class="flex-1">
              <input
                v-model="student.name"
                type="text"
                placeholder="Student name"
                class="input"
              />
            </div>
            <div class="w-40">
              <select v-model="student.gradeLevel" class="input">
                <option value="">Grade</option>
                <option v-for="grade in gradeLevels" :key="grade" :value="grade">
                  {{ grade }}
                </option>
              </select>
            </div>
            <button
              v-if="students.length > 1"
              type="button"
              @click="removeStudent(index)"
              class="p-2 text-red-500 hover:text-red-700"
            >
              ✕
            </button>
          </div>

          <button
            type="button"
            @click="addStudent"
            class="text-primary-600 hover:text-primary-700 text-sm font-medium"
          >
            + Add another student
          </button>
        </div>
      </div>

      <!-- Navigation -->
      <div class="mt-8 flex justify-between">
        <button
          v-if="currentStep > 1"
          type="button"
          @click="prevStep"
          class="btn-secondary"
        >
          Back
        </button>
        <div v-else></div>

        <button
          v-if="currentStep < totalSteps"
          type="button"
          @click="nextStep"
          class="btn-primary"
        >
          Continue
        </button>
        <button
          v-else
          type="button"
          @click="completeOnboarding"
          :disabled="loading"
          class="btn-primary"
        >
          {{ loading ? 'Setting up...' : 'Complete Setup' }}
        </button>
      </div>
    </div>
  </div>
</template>

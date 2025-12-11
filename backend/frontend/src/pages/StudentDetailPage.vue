<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useStudentsStore } from '@/stores/students'
import { useStatsStore } from '@/stores/stats'
import { useLogsStore } from '@/stores/logs'
import { useSubjectsStore } from '@/stores/subjects'
import { useAuthStore } from '@/stores/auth'
import { ProgressBar, LogEntryRow, BaseModal, SchoolYearSelector } from '@/components/common'

const route = useRoute()
const router = useRouter()
const studentsStore = useStudentsStore()
const statsStore = useStatsStore()
const logsStore = useLogsStore()
const subjectsStore = useSubjectsStore()
const authStore = useAuthStore()

const studentId = computed(() => route.params.id as string)
const loading = ref(true)

// Edit modal
const showEditModal = ref(false)
const editName = ref('')
const editGradeLevel = ref('')
const editActive = ref(true)
const saving = ref(false)

// Current student
const student = computed(() => 
  studentsStore.students.find(s => s.id === studentId.value)
)

// Student stats - use getter from store
const currentStudentStats = computed(() => 
  statsStore.getStudentStats(studentId.value)
)

// Computed stats with safe access
const totalHours = computed(() => currentStudentStats.value?.totalHours ?? 0)
const coreHours = computed(() => {
  // Calculate from bySubject, filtering core subjects
  if (!currentStudentStats.value?.bySubject) return 0
  const coreSubjectIds = subjectsStore.subjects
    .filter(s => s.type === 'core')
    .map(s => s.id)
  return currentStudentStats.value.bySubject
    .filter(sh => coreSubjectIds.includes(sh.subjectId))
    .reduce((sum, sh) => sum + sh.hours, 0)
})
const homeHours = computed(() => {
  // For now approximate as 40% of total (need proper tracking from backend)
  return totalHours.value * 0.4
})

// Student logs (recent)
const studentLogs = computed(() => 
  logsStore.logs.filter(l => l.studentId === studentId.value).slice(0, 10)
)

// Subjects by ID for display
const subjectsById = computed(() => {
  const map: Record<string, { name: string; color: string }> = {}
  subjectsStore.subjects.forEach(s => {
    map[s.id] = { name: s.name, color: s.color }
  })
  return map
})

// Missouri requirements
const totalHoursRequired = 1000
const coreHoursRequired = 600
const homeHoursRequired = 400

const gradeLevels = ['K', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12']

function openEditModal() {
  if (!student.value) return
  editName.value = student.value.name
  editGradeLevel.value = student.value.gradeLevel || ''
  editActive.value = student.value.active
  showEditModal.value = true
}

async function saveStudent() {
  if (!student.value) return
  
  saving.value = true
  try {
    await studentsStore.updateStudent(student.value.id, {
      name: editName.value,
      gradeLevel: editGradeLevel.value,
      active: editActive.value
    })
    showEditModal.value = false
  } catch (err) {
    console.error('Failed to update student:', err)
  } finally {
    saving.value = false
  }
}

function goToLogs() {
  router.push({ path: '/logs', query: { studentId: studentId.value } })
}

function goToQuickLog() {
  router.push({ path: '/log', query: { studentId: studentId.value } })
}

async function loadData() {
  loading.value = true
  try {
    // Ensure we have data
    if (studentsStore.students.length === 0) {
      await studentsStore.fetchStudents()
    }
    if (subjectsStore.subjects.length === 0) {
      await subjectsStore.fetchSubjects()
    }
    
    // Fetch stats for this student
    await statsStore.fetchStudentStats(studentId.value, authStore.effectiveSchoolYear)
    
    // Fetch recent logs for this student
    await logsStore.fetchLogs({ studentId: studentId.value, schoolYear: authStore.effectiveSchoolYear })
  } finally {
    loading.value = false
  }
}

// Refresh data when school year changes
async function onSchoolYearChange(year: string) {
  loading.value = true
  try {
    await statsStore.fetchStudentStats(studentId.value, year)
    await logsStore.fetchLogs({ studentId: studentId.value, schoolYear: year })
  } finally {
    loading.value = false
  }
}

// Reload when student ID changes
watch(studentId, () => {
  loadData()
})

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-start flex-wrap gap-4">
      <div>
        <button 
          type="button"
          class="text-sm text-gray-500 hover:text-gray-700 mb-2"
          @click="router.push('/students')"
        >
          ← Back to Students
        </button>
        <h1 class="text-2xl font-bold text-gray-900">
          {{ student?.name }}
        </h1>
        <p v-if="student?.gradeLevel" class="text-gray-600">Grade {{ student.gradeLevel }}</p>
        <span 
          v-if="student && !student.active" 
          class="inline-block mt-1 px-2 py-0.5 text-xs rounded bg-gray-200 text-gray-600"
        >
          Inactive
        </span>
      </div>
      <div class="flex items-center gap-4">
        <SchoolYearSelector @change="onSchoolYearChange" />
        <button type="button" class="btn-secondary" @click="openEditModal">
          Edit Student
        </button>
        <button type="button" class="btn-primary" @click="goToQuickLog">
          + Log Hours
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="card">
      <p class="text-gray-500">Loading...</p>
    </div>

    <!-- Student not found -->
    <div v-else-if="!student" class="card">
      <p class="text-gray-500">Student not found</p>
    </div>

    <template v-else>
      <!-- Progress Cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="card">
          <h3 class="text-sm font-medium text-gray-500 mb-2">Total Hours</h3>
          <p class="text-2xl font-bold text-gray-900 mb-2">
            {{ totalHours.toFixed(1) }}
            <span class="text-sm font-normal text-gray-500">/ {{ totalHoursRequired }}</span>
          </p>
          <ProgressBar :current="totalHours" :target="totalHoursRequired" color="blue" />
        </div>
        
        <div class="card">
          <h3 class="text-sm font-medium text-gray-500 mb-2">Core Subject Hours</h3>
          <p class="text-2xl font-bold text-gray-900 mb-2">
            {{ coreHours.toFixed(1) }}
            <span class="text-sm font-normal text-gray-500">/ {{ coreHoursRequired }}</span>
          </p>
          <ProgressBar :current="coreHours" :target="coreHoursRequired" color="green" />
        </div>
        
        <div class="card">
          <h3 class="text-sm font-medium text-gray-500 mb-2">At-Home Hours</h3>
          <p class="text-2xl font-bold text-gray-900 mb-2">
            {{ homeHours.toFixed(1) }}
            <span class="text-sm font-normal text-gray-500">/ {{ homeHoursRequired }}</span>
          </p>
          <ProgressBar :current="homeHours" :target="homeHoursRequired" color="purple" />
        </div>
      </div>

      <!-- Hours by Subject -->
      <div class="card">
        <h2 class="text-lg font-medium text-gray-900 mb-4">Hours by Subject</h2>
        <div v-if="currentStudentStats?.bySubject && currentStudentStats.bySubject.length > 0" class="space-y-3">
          <div 
            v-for="sh in currentStudentStats.bySubject" 
            :key="sh.subjectId"
            class="flex items-center justify-between"
          >
            <div class="flex items-center space-x-3">
              <div 
                class="w-3 h-3 rounded-full"
                :style="{ backgroundColor: subjectsById[sh.subjectId]?.color || '#6B7280' }"
              ></div>
              <span class="text-gray-700">{{ sh.subjectName || subjectsById[sh.subjectId]?.name || 'Unknown' }}</span>
            </div>
            <span class="font-medium text-gray-900">{{ sh.hours.toFixed(1) }} hrs</span>
          </div>
        </div>
        <p v-else class="text-gray-500">No hours logged yet</p>
      </div>

      <!-- Recent Activity -->
      <div class="card">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-lg font-medium text-gray-900">Recent Activity</h2>
          <button 
            v-if="studentLogs.length > 0"
            type="button"
            class="text-sm text-primary-600 hover:text-primary-700"
            @click="goToLogs"
          >
            View All →
          </button>
        </div>
        
        <div v-if="studentLogs.length > 0" class="space-y-2">
          <LogEntryRow 
            v-for="log in studentLogs" 
            :key="log.id"
            :log="log"
            :student-name="student.name"
            :subject-name="subjectsById[log.subjectId]?.name || 'Unknown'"
            :subject-color="subjectsById[log.subjectId]?.color || '#6B7280'"
          />
        </div>
        <div v-else class="text-center py-8">
          <p class="text-gray-500 mb-4">No log entries yet</p>
          <button type="button" class="btn-primary" @click="goToQuickLog">
            Log First Hours
          </button>
        </div>
      </div>
    </template>

    <!-- Edit Modal -->
    <BaseModal v-model:open="showEditModal" title="Edit Student">
      <div class="space-y-4">
        <div>
          <label class="label">Name</label>
          <input v-model="editName" type="text" class="input mt-1" required />
        </div>
        <div>
          <label class="label">Grade Level</label>
          <select v-model="editGradeLevel" class="input mt-1">
            <option value="">Select grade</option>
            <option v-for="grade in gradeLevels" :key="grade" :value="grade">
              {{ grade }}
            </option>
          </select>
        </div>
        <div class="flex items-center">
          <input 
            v-model="editActive" 
            type="checkbox" 
            id="edit-active"
            class="h-4 w-4 text-primary-600 rounded"
          />
          <label for="edit-active" class="ml-2 text-sm text-gray-700">
            Active student
          </label>
        </div>
      </div>
      <template #footer>
        <button type="button" class="btn-secondary" @click="showEditModal = false">
          Cancel
        </button>
        <button 
          type="button" 
          class="btn-primary"
          :disabled="saving || !editName"
          @click="saveStudent"
        >
          {{ saving ? 'Saving...' : 'Save Changes' }}
        </button>
      </template>
    </BaseModal>
  </div>
</template>

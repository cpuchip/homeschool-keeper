<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useLogsStore } from '@/stores/logs'
import { useStudentsStore } from '@/stores/students'
import { useSubjectsStore } from '@/stores/subjects'
import { useAuthStore } from '@/stores/auth'
import { LogEntryRow, BaseModal, SchoolYearSelector } from '@/components/common'
import { toast } from '@/composables/useToast'
import type { LogEntry } from '@/types'

const logsStore = useLogsStore()
const studentsStore = useStudentsStore()
const subjectsStore = useSubjectsStore()
const authStore = useAuthStore()

// Filters
const studentFilter = ref('')
const subjectFilter = ref('')
const startDate = ref('')
const endDate = ref('')

// Edit modal
const showEditModal = ref(false)
const editingLog = ref<LogEntry | null>(null)
const editHours = ref(1)
const editDescription = ref('')
const saving = ref(false)

// Delete confirmation
const showDeleteModal = ref(false)
const deletingLog = ref<LogEntry | null>(null)

const loading = computed(() => logsStore.loading)

// Filtered logs
const filteredLogs = computed(() => {
  let logs = [...logsStore.logs]
  
  if (studentFilter.value) {
    logs = logs.filter(l => l.studentId === studentFilter.value)
  }
  if (subjectFilter.value) {
    logs = logs.filter(l => l.subjectId === subjectFilter.value)
  }
  if (startDate.value) {
    logs = logs.filter(l => l.date >= startDate.value)
  }
  if (endDate.value) {
    logs = logs.filter(l => l.date <= endDate.value)
  }
  
  // Sort by date descending
  logs.sort((a, b) => b.date.localeCompare(a.date))
  
  return logs
})

// Extract date-only string from ISO timestamp
function getDateOnly(dateStr: string): string {
  // Handle both ISO timestamps and date-only strings
  return dateStr.split('T')[0]
}

// Group logs by date
const logsByDate = computed(() => {
  const groups: Record<string, LogEntry[]> = {}
  filteredLogs.value.forEach(log => {
    const dateKey = getDateOnly(log.date)
    if (!groups[dateKey]) {
      groups[dateKey] = []
    }
    groups[dateKey].push(log)
  })
  return groups
})

const sortedDates = computed(() => 
  Object.keys(logsByDate.value).sort((a, b) => b.localeCompare(a))
)

function formatDate(dateStr: string): string {
  const date = new Date(dateStr + 'T00:00:00')
  const today = new Date()
  const yesterday = new Date(today)
  yesterday.setDate(yesterday.getDate() - 1)
  
  if (dateStr === today.toISOString().split('T')[0]) {
    return 'Today'
  }
  if (dateStr === yesterday.toISOString().split('T')[0]) {
    return 'Yesterday'
  }
  
  return date.toLocaleDateString('en-US', { 
    weekday: 'long', 
    month: 'long', 
    day: 'numeric' 
  })
}

function openEditModal(log: LogEntry) {
  editingLog.value = log
  editHours.value = log.hours
  editDescription.value = log.description || ''
  showEditModal.value = true
}

async function saveEdit() {
  if (!editingLog.value) return
  
  saving.value = true
  try {
    await logsStore.updateLog(editingLog.value.id, {
      hours: editHours.value,
      description: editDescription.value
    })
    showEditModal.value = false
    editingLog.value = null
    toast.success('Log entry updated')
  } catch (err) {
    toast.error('Failed to update log entry')
  } finally {
    saving.value = false
  }
}

function openDeleteModal(log: LogEntry) {
  deletingLog.value = log
  showDeleteModal.value = true
}

async function confirmDelete() {
  if (!deletingLog.value) return
  
  saving.value = true
  try {
    await logsStore.deleteLog(deletingLog.value.id)
    showDeleteModal.value = false
    deletingLog.value = null
    toast.success('Log entry deleted')
  } catch (err) {
    toast.error('Failed to delete log entry')
  } finally {
    saving.value = false
  }
}

function clearFilters() {
  studentFilter.value = ''
  subjectFilter.value = ''
  startDate.value = ''
  endDate.value = ''
}

// Refresh logs when school year changes
async function onSchoolYearChange(year: string) {
  const filters: { studentId?: string; subjectId?: string; startDate?: string; endDate?: string; schoolYear?: string } = {}
  if (studentFilter.value) filters.studentId = studentFilter.value
  if (subjectFilter.value) filters.subjectId = subjectFilter.value
  if (startDate.value) filters.startDate = startDate.value
  if (endDate.value) filters.endDate = endDate.value
  filters.schoolYear = year
  
  await logsStore.fetchLogs(filters)
}

// Fetch logs when filters change
watch([studentFilter, subjectFilter, startDate, endDate], async () => {
  const filters: { studentId?: string; subjectId?: string; startDate?: string; endDate?: string; schoolYear?: string } = {}
  if (studentFilter.value) filters.studentId = studentFilter.value
  if (subjectFilter.value) filters.subjectId = subjectFilter.value
  if (startDate.value) filters.startDate = startDate.value
  if (endDate.value) filters.endDate = endDate.value
  filters.schoolYear = authStore.effectiveSchoolYear
  
  await logsStore.fetchLogs(filters)
})

onMounted(async () => {
  // Load data
  if (studentsStore.students.length === 0) {
    await studentsStore.fetchStudents()
  }
  if (subjectsStore.subjects.length === 0) {
    await subjectsStore.fetchSubjects()
  }
  await logsStore.fetchLogs({ schoolYear: authStore.effectiveSchoolYear })
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center flex-wrap gap-4">
      <h1 class="text-2xl font-bold text-gray-900">Log History</h1>
      <div class="flex items-center gap-4">
        <SchoolYearSelector @change="onSchoolYearChange" />
        <router-link to="/log" class="btn-primary">+ New Log</router-link>
      </div>
    </div>

    <!-- Filters -->
    <div class="card">
      <div class="flex flex-wrap gap-4 items-end">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Student</label>
          <select v-model="studentFilter" class="input w-auto">
            <option value="">All Students</option>
            <option 
              v-for="student in studentsStore.activeStudents" 
              :key="student.id" 
              :value="student.id"
            >
              {{ student.name }}
            </option>
          </select>
        </div>
        
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Subject</label>
          <select v-model="subjectFilter" class="input w-auto">
            <option value="">All Subjects</option>
            <option 
              v-for="subject in subjectsStore.activeSubjects" 
              :key="subject.id" 
              :value="subject.id"
            >
              {{ subject.name }}
            </option>
          </select>
        </div>
        
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
          <input v-model="startDate" type="date" class="input w-auto" />
        </div>
        
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">End Date</label>
          <input v-model="endDate" type="date" class="input w-auto" />
        </div>
        
        <button 
          v-if="studentFilter || subjectFilter || startDate || endDate"
          type="button"
          class="text-sm text-primary-600 hover:text-primary-700"
          @click="clearFilters"
        >
          Clear filters
        </button>
      </div>
    </div>

    <!-- Loading state -->
    <div v-if="loading" class="card">
      <p class="text-gray-500">Loading logs...</p>
    </div>

    <!-- Empty state -->
    <div v-else-if="filteredLogs.length === 0" class="card text-center py-12">
      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
      </svg>
      <h3 class="mt-2 text-sm font-medium text-gray-900">No log entries</h3>
      <p class="mt-1 text-sm text-gray-500">Get started by creating a new log entry.</p>
      <div class="mt-6">
        <router-link to="/log" class="btn-primary">+ New Log</router-link>
      </div>
    </div>

    <!-- Logs grouped by date -->
    <div v-else class="space-y-6">
      <div v-for="date in sortedDates" :key="date" class="card">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">{{ formatDate(date) }}</h3>
        <div class="space-y-2">
          <LogEntryRow 
            v-for="log in logsByDate[date]" 
            :key="log.id"
            :log="log"
            :student="studentsStore.students.find(s => s.id === log.studentId)"
            :subject="subjectsStore.subjects.find(s => s.id === log.subjectId)"
            :show-actions="true"
            @edit="openEditModal(log)"
            @delete="openDeleteModal(log)"
          />
        </div>
      </div>
    </div>

    <!-- Edit Modal -->
    <BaseModal v-model:open="showEditModal" title="Edit Log Entry">
      <div class="space-y-4">
        <div>
          <label class="label">Hours</label>
          <input 
            v-model.number="editHours" 
            type="number" 
            step="0.25" 
            min="0.25" 
            max="24" 
            class="input mt-1"
          />
        </div>
        <div>
          <label class="label">Description</label>
          <textarea 
            v-model="editDescription" 
            rows="3" 
            class="input mt-1"
            placeholder="What was learned?"
          ></textarea>
        </div>
      </div>
      <template #footer>
        <button type="button" class="btn-secondary" @click="showEditModal = false">
          Cancel
        </button>
        <button 
          type="button" 
          class="btn-primary" 
          :disabled="saving"
          @click="saveEdit"
        >
          {{ saving ? 'Saving...' : 'Save Changes' }}
        </button>
      </template>
    </BaseModal>

    <!-- Delete Confirmation Modal -->
    <BaseModal v-model:open="showDeleteModal" title="Delete Log Entry">
      <p class="text-gray-600">
        Are you sure you want to delete this log entry? This action cannot be undone.
      </p>
      <template #footer>
        <button type="button" class="btn-secondary" @click="showDeleteModal = false">
          Cancel
        </button>
        <button 
          type="button" 
          class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
          :disabled="saving"
          @click="confirmDelete"
        >
          {{ saving ? 'Deleting...' : 'Delete' }}
        </button>
      </template>
    </BaseModal>
  </div>
</template>

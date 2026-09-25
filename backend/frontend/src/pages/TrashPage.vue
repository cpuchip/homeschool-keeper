<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { studentsApi } from '@/api/students'
import { subjectsApi } from '@/api/subjects'
import { toast } from '@/composables/useToast'
import { BaseModal } from '@/components/common'
import type { Student, Subject } from '@/types'

const activeTab = ref<'students' | 'subjects'>('students')
const loading = ref(false)
const deletedStudents = ref<Student[]>([])
const deletedSubjects = ref<Subject[]>([])

// Delete confirmation modal
const showDeleteModal = ref(false)
const deleteType = ref<'student' | 'subject'>('student')
const deleteId = ref('')
const deleteName = ref('')

const isEmpty = computed(() => 
  deletedStudents.value.length === 0 && deletedSubjects.value.length === 0
)

async function loadDeleted() {
  loading.value = true
  try {
    const [students, subjects] = await Promise.all([
      studentsApi.listDeleted(),
      subjectsApi.listDeleted()
    ])
    deletedStudents.value = students
    deletedSubjects.value = subjects
  } catch (e) {
    toast.error('Failed to load trash')
  } finally {
    loading.value = false
  }
}

async function restoreStudent(id: string) {
  try {
    await studentsApi.restore(id)
    deletedStudents.value = deletedStudents.value.filter(s => s.id !== id)
    toast.success('Student restored')
  } catch (e) {
    toast.error('Failed to restore student')
  }
}

async function restoreSubject(id: string) {
  try {
    await subjectsApi.restore(id)
    deletedSubjects.value = deletedSubjects.value.filter(s => s.id !== id)
    toast.success('Subject restored')
  } catch (e) {
    toast.error('Failed to restore subject')
  }
}

function confirmDelete(type: 'student' | 'subject', id: string, name: string) {
  deleteType.value = type
  deleteId.value = id
  deleteName.value = name
  showDeleteModal.value = true
}

async function handlePermanentDelete() {
  try {
    if (deleteType.value === 'student') {
      await studentsApi.hardDelete(deleteId.value)
      deletedStudents.value = deletedStudents.value.filter(s => s.id !== deleteId.value)
    } else {
      await subjectsApi.hardDelete(deleteId.value)
      deletedSubjects.value = deletedSubjects.value.filter(s => s.id !== deleteId.value)
    }
    toast.success('Permanently deleted')
    showDeleteModal.value = false
  } catch (e) {
    toast.error('Failed to delete')
  }
}

onMounted(loadDeleted)
</script>

<template>
  <div class="max-w-4xl mx-auto">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Trash</h1>
        <p class="text-gray-600 mt-1">View and restore deleted items</p>
      </div>
      <router-link to="/settings" class="text-primary-600 hover:text-primary-700">
        ← Back to Settings
      </router-link>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="card text-center py-12">
      <p class="text-gray-500">Loading...</p>
    </div>

    <!-- Empty state -->
    <div v-else-if="isEmpty" class="card text-center py-12">
      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
      </svg>
      <h3 class="mt-2 text-sm font-medium text-gray-900">Trash is empty</h3>
      <p class="mt-1 text-sm text-gray-500">Deleted items will appear here.</p>
    </div>

    <!-- Tabs and content -->
    <div v-else>
      <!-- Tabs -->
      <div class="border-b border-gray-200 mb-6">
        <nav class="-mb-px flex space-x-8">
          <button
            :class="[
              'py-4 px-1 border-b-2 font-medium text-sm',
              activeTab === 'students'
                ? 'border-primary-500 text-primary-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            ]"
            @click="activeTab = 'students'"
          >
            Students
            <span 
              v-if="deletedStudents.length > 0"
              class="ml-2 bg-gray-100 text-gray-600 py-0.5 px-2 rounded-full text-xs"
            >
              {{ deletedStudents.length }}
            </span>
          </button>
          <button
            :class="[
              'py-4 px-1 border-b-2 font-medium text-sm',
              activeTab === 'subjects'
                ? 'border-primary-500 text-primary-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            ]"
            @click="activeTab = 'subjects'"
          >
            Subjects
            <span 
              v-if="deletedSubjects.length > 0"
              class="ml-2 bg-gray-100 text-gray-600 py-0.5 px-2 rounded-full text-xs"
            >
              {{ deletedSubjects.length }}
            </span>
          </button>
        </nav>
      </div>

      <!-- Students tab -->
      <div v-if="activeTab === 'students'" class="space-y-4">
        <div v-if="deletedStudents.length === 0" class="card text-center py-8">
          <p class="text-gray-500">No deleted students</p>
        </div>
        <div 
          v-for="student in deletedStudents" 
          :key="student.id"
          class="card flex items-center justify-between"
        >
          <div>
            <h3 class="font-medium text-gray-900">{{ student.name }}</h3>
            <p class="text-sm text-gray-500">{{ student.gradeLevel || 'No grade' }}</p>
          </div>
          <div class="flex gap-2">
            <button
              class="btn-secondary text-sm"
              @click="restoreStudent(student.id)"
            >
              Restore
            </button>
            <button
              class="text-red-600 hover:text-red-700 text-sm font-medium"
              @click="confirmDelete('student', student.id, student.name)"
            >
              Delete Permanently
            </button>
          </div>
        </div>
      </div>

      <!-- Subjects tab -->
      <div v-if="activeTab === 'subjects'" class="space-y-4">
        <div v-if="deletedSubjects.length === 0" class="card text-center py-8">
          <p class="text-gray-500">No deleted subjects</p>
        </div>
        <div 
          v-for="subject in deletedSubjects" 
          :key="subject.id"
          class="card flex items-center justify-between"
        >
          <div class="flex items-center gap-3">
            <div 
              class="w-4 h-4 rounded-full"
              :style="{ backgroundColor: subject.color || '#3B82F6' }"
            ></div>
            <div>
              <h3 class="font-medium text-gray-900">{{ subject.name }}</h3>
              <p class="text-sm text-gray-500 capitalize">{{ subject.type }}</p>
            </div>
          </div>
          <div class="flex gap-2">
            <button
              class="btn-secondary text-sm"
              @click="restoreSubject(subject.id)"
            >
              Restore
            </button>
            <button
              class="text-red-600 hover:text-red-700 text-sm font-medium"
              @click="confirmDelete('subject', subject.id, subject.name)"
            >
              Delete Permanently
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <BaseModal v-model:open="showDeleteModal" title="Permanently Delete?">
      <div class="space-y-4">
        <p>
          Are you sure you want to permanently delete 
          <strong>{{ deleteName }}</strong>?
        </p>
        <p class="text-red-600 text-sm">
          ⚠️ This action cannot be undone. All associated log entries will become orphaned.
        </p>
      </div>
      <template #footer>
        <div class="flex justify-end gap-3">
          <button class="btn-secondary" @click="showDeleteModal = false">
            Cancel
          </button>
          <button 
            class="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700"
            @click="handlePermanentDelete"
          >
            Delete Permanently
          </button>
        </div>
      </template>
    </BaseModal>
  </div>
</template>

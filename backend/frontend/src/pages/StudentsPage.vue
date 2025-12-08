<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useStudentsStore } from '@/stores/students'
import { BaseModal, BaseInput, BaseSelect, BaseButton } from '@/components/common'
import type { Student } from '@/types'

const studentsStore = useStudentsStore()

// Modal state
const showModal = ref(false)
const editingStudent = ref<Student | null>(null)

// Form state
const formName = ref('')
const formGradeLevel = ref('')
const formError = ref('')
const formLoading = ref(false)

const gradeLevelOptions = [
  { value: 'Pre-K', label: 'Pre-K' },
  { value: 'Kindergarten', label: 'Kindergarten' },
  { value: '1st Grade', label: '1st Grade' },
  { value: '2nd Grade', label: '2nd Grade' },
  { value: '3rd Grade', label: '3rd Grade' },
  { value: '4th Grade', label: '4th Grade' },
  { value: '5th Grade', label: '5th Grade' },
  { value: '6th Grade', label: '6th Grade' },
  { value: '7th Grade', label: '7th Grade' },
  { value: '8th Grade', label: '8th Grade' },
  { value: '9th Grade', label: '9th Grade' },
  { value: '10th Grade', label: '10th Grade' },
  { value: '11th Grade', label: '11th Grade' },
  { value: '12th Grade', label: '12th Grade' }
]

onMounted(() => {
  studentsStore.fetchStudents()
})

const students = computed(() => studentsStore.students)
const activeStudents = computed(() => studentsStore.activeStudents)
const inactiveStudents = computed(() => students.value.filter(s => !s.active))

function openAddModal() {
  editingStudent.value = null
  formName.value = ''
  formGradeLevel.value = ''
  formError.value = ''
  showModal.value = true
}

function openEditModal(student: Student) {
  editingStudent.value = student
  formName.value = student.name
  formGradeLevel.value = student.gradeLevel
  formError.value = ''
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  editingStudent.value = null
}

async function handleSubmit() {
  if (!formName.value.trim()) {
    formError.value = 'Name is required'
    return
  }
  if (!formGradeLevel.value) {
    formError.value = 'Grade level is required'
    return
  }

  formLoading.value = true
  formError.value = ''

  try {
    if (editingStudent.value) {
      await studentsStore.updateStudent(editingStudent.value.id, {
        name: formName.value.trim(),
        gradeLevel: formGradeLevel.value
      })
    } else {
      await studentsStore.createStudent({
        name: formName.value.trim(),
        gradeLevel: formGradeLevel.value
      })
    }
    closeModal()
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    formError.value = err.response?.data?.error || 'Failed to save student'
  } finally {
    formLoading.value = false
  }
}

async function handleDelete(student: Student) {
  if (!confirm(`Are you sure you want to remove ${student.name}? This will mark them as inactive.`)) {
    return
  }

  try {
    await studentsStore.deleteStudent(student.id)
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    alert(err.response?.data?.error || 'Failed to delete student')
  }
}

async function handleReactivate(student: Student) {
  try {
    await studentsStore.updateStudent(student.id, { active: true })
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    alert(err.response?.data?.error || 'Failed to reactivate student')
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-900">Students</h1>
      <BaseButton @click="openAddModal">+ Add Student</BaseButton>
    </div>

    <!-- Loading -->
    <div v-if="studentsStore.loading" class="text-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600 mx-auto"></div>
    </div>

    <!-- Active Students -->
    <div v-else-if="activeStudents.length > 0" class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Active Students</h2>
      <div class="divide-y divide-gray-200">
        <div
          v-for="student in activeStudents"
          :key="student.id"
          class="py-4 flex items-center justify-between"
        >
          <div>
            <router-link
              :to="`/students/${student.id}`"
              class="font-medium text-gray-900 hover:text-primary-600"
            >
              {{ student.name }}
            </router-link>
            <p class="text-sm text-gray-500">{{ student.gradeLevel }}</p>
          </div>
          <div class="flex gap-2">
            <button
              @click="openEditModal(student)"
              class="text-gray-400 hover:text-primary-600"
              title="Edit"
            >
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
            </button>
            <button
              @click="handleDelete(student)"
              class="text-gray-400 hover:text-red-600"
              title="Remove"
            >
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="card">
      <div class="text-center py-8">
        <p class="text-gray-500 mb-4">No students yet. Add your first student to get started.</p>
        <BaseButton @click="openAddModal">+ Add Student</BaseButton>
      </div>
    </div>

    <!-- Inactive Students -->
    <div v-if="inactiveStudents.length > 0" class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Inactive Students</h2>
      <div class="divide-y divide-gray-200">
        <div
          v-for="student in inactiveStudents"
          :key="student.id"
          class="py-4 flex items-center justify-between opacity-60"
        >
          <div>
            <span class="font-medium text-gray-900">{{ student.name }}</span>
            <p class="text-sm text-gray-500">{{ student.gradeLevel }}</p>
          </div>
          <button
            @click="handleReactivate(student)"
            class="text-sm text-primary-600 hover:text-primary-700"
          >
            Reactivate
          </button>
        </div>
      </div>
    </div>

    <!-- Add/Edit Modal -->
    <BaseModal
      v-model:open="showModal"
      :title="editingStudent ? 'Edit Student' : 'Add Student'"
    >
      <form @submit.prevent="handleSubmit" class="space-y-4">
        <div v-if="formError" class="rounded-md bg-red-50 p-3">
          <p class="text-sm text-red-700">{{ formError }}</p>
        </div>

        <BaseInput
          v-model="formName"
          label="Name"
          placeholder="Student name"
          required
        />

        <BaseSelect
          v-model="formGradeLevel"
          :options="gradeLevelOptions"
          label="Grade Level"
          placeholder="Select grade"
          required
        />

        <div class="flex justify-end gap-3 pt-4">
          <BaseButton variant="secondary" @click="closeModal">
            Cancel
          </BaseButton>
          <BaseButton type="submit" :loading="formLoading">
            {{ editingStudent ? 'Save' : 'Add Student' }}
          </BaseButton>
        </div>
      </form>
    </BaseModal>
  </div>
</template>

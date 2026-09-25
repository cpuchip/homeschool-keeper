<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useSubjectsStore } from '@/stores/subjects'
import { BaseModal, BaseInput, BaseSelect, BaseButton } from '@/components/common'
import { toast } from '@/composables/useToast'
import type { Subject } from '@/types'

const subjectsStore = useSubjectsStore()

// Modal state
const showModal = ref(false)
const editingSubject = ref<Subject | null>(null)

// Form state
const formName = ref('')
const formType = ref<'core' | 'elective'>('core')
const formColor = ref('#3B82F6')
const formError = ref('')
const formLoading = ref(false)

const typeOptions = [
  { value: 'core', label: 'Core Subject' },
  { value: 'elective', label: 'Elective' }
]

const colorOptions = [
  { value: '#3B82F6', label: 'Blue' },
  { value: '#10B981', label: 'Green' },
  { value: '#F59E0B', label: 'Yellow' },
  { value: '#EF4444', label: 'Red' },
  { value: '#8B5CF6', label: 'Purple' },
  { value: '#EC4899', label: 'Pink' },
  { value: '#F97316', label: 'Orange' },
  { value: '#6B7280', label: 'Gray' }
]

onMounted(() => {
  subjectsStore.fetchSubjects()
})

const coreSubjects = computed(() => subjectsStore.coreSubjects)
const electiveSubjects = computed(() => subjectsStore.electiveSubjects)

function openAddModal() {
  editingSubject.value = null
  formName.value = ''
  formType.value = 'core'
  formColor.value = '#3B82F6'
  formError.value = ''
  showModal.value = true
}

function openEditModal(subject: Subject) {
  editingSubject.value = subject
  formName.value = subject.name
  formType.value = subject.type
  formColor.value = subject.color || '#3B82F6'
  formError.value = ''
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  editingSubject.value = null
}

async function handleSubmit() {
  if (!formName.value.trim()) {
    formError.value = 'Name is required'
    return
  }

  formLoading.value = true
  formError.value = ''

  try {
    if (editingSubject.value) {
      await subjectsStore.updateSubject(editingSubject.value.id, {
        name: formName.value.trim(),
        type: formType.value,
        color: formColor.value
      })
    } else {
      await subjectsStore.createSubject({
        name: formName.value.trim(),
        type: formType.value,
        color: formColor.value
      })
    }
    closeModal()
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    formError.value = err.response?.data?.error || 'Failed to save subject'
  } finally {
    formLoading.value = false
  }
}

async function handleDelete(subject: Subject) {
  if (!confirm(`Are you sure you want to remove "${subject.name}"?`)) {
    return
  }

  try {
    await subjectsStore.deleteSubject(subject.id)
    toast.success(`${subject.name} has been removed`)
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    toast.error(err.response?.data?.error || 'Failed to delete subject')
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-900">Subjects</h1>
      <BaseButton @click="openAddModal">+ Add Subject</BaseButton>
    </div>

    <!-- Loading -->
    <div v-if="subjectsStore.loading" class="text-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600 mx-auto"></div>
    </div>

    <template v-else>
      <!-- Core Subjects -->
      <div class="card">
        <h2 class="text-lg font-medium text-gray-900 mb-4">Core Subjects</h2>
        <div v-if="coreSubjects.length > 0" class="space-y-2">
          <div
            v-for="subject in coreSubjects"
            :key="subject.id"
            class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100"
          >
            <div class="flex items-center">
              <div
                class="w-3 h-3 rounded-full mr-3"
                :style="{ backgroundColor: subject.color || '#3B82F6' }"
              ></div>
              <span class="font-medium">{{ subject.name }}</span>
            </div>
            <div class="flex gap-2">
              <button
                @click="openEditModal(subject)"
                class="text-gray-400 hover:text-primary-600"
                title="Edit"
              >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
              </button>
              <button
                v-if="!subject.isDefault"
                @click="handleDelete(subject)"
                class="text-gray-400 hover:text-red-600"
                title="Delete"
              >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </button>
            </div>
          </div>
        </div>
        <p v-else class="text-gray-500">No core subjects added yet.</p>
      </div>

      <!-- Electives -->
      <div class="card">
        <h2 class="text-lg font-medium text-gray-900 mb-4">Electives</h2>
        <div v-if="electiveSubjects.length > 0" class="space-y-2">
          <div
            v-for="subject in electiveSubjects"
            :key="subject.id"
            class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100"
          >
            <div class="flex items-center">
              <div
                class="w-3 h-3 rounded-full mr-3"
                :style="{ backgroundColor: subject.color || '#10B981' }"
              ></div>
              <span class="font-medium">{{ subject.name }}</span>
            </div>
            <div class="flex gap-2">
              <button
                @click="openEditModal(subject)"
                class="text-gray-400 hover:text-primary-600"
                title="Edit"
              >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
              </button>
              <button
                @click="handleDelete(subject)"
                class="text-gray-400 hover:text-red-600"
                title="Delete"
              >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </button>
            </div>
          </div>
        </div>
        <p v-else class="text-gray-500">No electives added yet.</p>
      </div>
    </template>

    <!-- Add/Edit Modal -->
    <BaseModal
      v-model:open="showModal"
      :title="editingSubject ? 'Edit Subject' : 'Add Subject'"
    >
      <form @submit.prevent="handleSubmit" class="space-y-4">
        <div v-if="formError" class="rounded-md bg-red-50 p-3">
          <p class="text-sm text-red-700">{{ formError }}</p>
        </div>

        <BaseInput
          v-model="formName"
          label="Name"
          placeholder="Subject name"
          required
        />

        <BaseSelect
          v-model="formType"
          :options="typeOptions"
          label="Type"
        />

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Color</label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="color in colorOptions"
              :key="color.value"
              type="button"
              @click="formColor = color.value"
              :class="[
                'w-8 h-8 rounded-full border-2 transition-all',
                formColor === color.value ? 'border-gray-900 scale-110' : 'border-transparent'
              ]"
              :style="{ backgroundColor: color.value }"
              :title="color.label"
            ></button>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <BaseButton variant="secondary" @click="closeModal">
            Cancel
          </BaseButton>
          <BaseButton type="submit" :loading="formLoading">
            {{ editingSubject ? 'Save' : 'Add Subject' }}
          </BaseButton>
        </div>
      </form>
    </BaseModal>
  </div>
</template>

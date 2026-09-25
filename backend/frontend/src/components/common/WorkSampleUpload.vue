<script setup lang="ts">
import { ref, computed } from 'vue'
import { uploadsApi } from '@/api/uploads'
import { useAuthStore } from '@/stores/auth'
import type { WorkSample } from '@/types'

interface Props {
  logEntryId: string
  workSamples: WorkSample[]
}

const props = defineProps<Props>()

const emit = defineEmits<{
  uploaded: [sample: WorkSample]
  deleted: [sampleId: string]
}>()

const authStore = useAuthStore()
const uploading = ref(false)
const uploadProgress = ref(0)
const error = ref('')
const selectedFiles = ref<File[]>([])

const uploadsEnabled = computed(() => authStore.family?.premium?.uploadsEnabled ?? false)

const allowedTypes = [
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
  'image/heic',
  'image/heif',
  'application/pdf',
  'video/mp4',
  'video/quicktime',
]

const maxFileSize = 10 * 1024 * 1024 // 10MB

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / 1024 / 1024).toFixed(1) + ' MB'
}

function handleFileSelect(event: Event) {
  const input = event.target as HTMLInputElement
  if (!input.files) return

  error.value = ''
  const files = Array.from(input.files)
  
  // Validate files
  for (const file of files) {
    if (!allowedTypes.includes(file.type)) {
      error.value = `File type not allowed: ${file.name}. Allowed: images, PDF, MP4`
      return
    }
    if (file.size > maxFileSize) {
      error.value = `File too large: ${file.name}. Max size is 10MB`
      return
    }
  }

  selectedFiles.value = files
}

async function uploadFiles() {
  if (selectedFiles.value.length === 0) return
  if (!uploadsEnabled.value) {
    error.value = 'File uploads require a premium subscription'
    return
  }

  uploading.value = true
  error.value = ''

  try {
    for (const file of selectedFiles.value) {
      uploadProgress.value = 0
      const sample = await uploadsApi.uploadFile(
        props.logEntryId,
        file,
        undefined,
        (percent) => { uploadProgress.value = percent }
      )
      emit('uploaded', sample)
    }
    selectedFiles.value = []
    // Clear the file input
    const input = document.querySelector('input[type="file"]') as HTMLInputElement
    if (input) input.value = ''
  } catch (e) {
    error.value = e instanceof Error ? e.message : 'Upload failed'
  } finally {
    uploading.value = false
    uploadProgress.value = 0
  }
}

async function deleteSample(sample: WorkSample) {
  if (!confirm(`Delete ${sample.fileName}?`)) return
  
  try {
    await uploadsApi.delete(sample.id)
    emit('deleted', sample.id)
  } catch (e) {
    error.value = e instanceof Error ? e.message : 'Delete failed'
  }
}

function getFileIcon(contentType: string): string {
  if (contentType.startsWith('image/')) return '🖼️'
  if (contentType === 'application/pdf') return '📄'
  if (contentType.startsWith('video/')) return '🎬'
  return '📎'
}
</script>

<template>
  <div class="space-y-4">
    <!-- Existing work samples -->
    <div v-if="workSamples.length > 0" class="space-y-2">
      <h4 class="text-sm font-medium text-gray-700">Attached Files</h4>
      <div class="flex flex-wrap gap-2">
        <div 
          v-for="sample in workSamples" 
          :key="sample.id"
          class="flex items-center gap-2 px-3 py-2 bg-gray-100 rounded-lg group"
        >
          <span>{{ getFileIcon(sample.contentType) }}</span>
          <a 
            v-if="sample.downloadUrl"
            :href="sample.downloadUrl"
            target="_blank"
            class="text-sm text-blue-600 hover:text-blue-800 truncate max-w-[150px]"
            :title="sample.fileName"
          >
            {{ sample.fileName }}
          </a>
          <span v-else class="text-sm text-gray-600 truncate max-w-[150px]">
            {{ sample.fileName }}
          </span>
          <span class="text-xs text-gray-500">
            ({{ formatFileSize(sample.sizeBytes) }})
          </span>
          <button 
            class="text-red-500 hover:text-red-700 opacity-0 group-hover:opacity-100 transition-opacity"
            title="Delete"
            @click="deleteSample(sample)"
          >
            ✕
          </button>
        </div>
      </div>
    </div>

    <!-- Upload section -->
    <div v-if="uploadsEnabled" class="space-y-2">
      <div class="flex items-center gap-2">
        <label class="cursor-pointer">
          <input
            type="file"
            multiple
            accept="image/*,.pdf,video/mp4,video/quicktime"
            class="hidden"
            @change="handleFileSelect"
          />
          <span class="inline-flex items-center gap-1 px-3 py-1.5 text-sm bg-gray-100 hover:bg-gray-200 rounded-lg">
            📎 Attach Files
          </span>
        </label>
        
        <span v-if="selectedFiles.length > 0" class="text-sm text-gray-600">
          {{ selectedFiles.length }} file(s) selected
        </span>
        
        <button
          v-if="selectedFiles.length > 0"
          :disabled="uploading"
          class="px-3 py-1.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
          @click="uploadFiles"
        >
          {{ uploading ? 'Uploading...' : 'Upload' }}
        </button>
      </div>

      <!-- Progress bar -->
      <div v-if="uploading" class="w-full bg-gray-200 rounded-full h-2">
        <div 
          class="bg-blue-600 h-2 rounded-full transition-all duration-300"
          :style="{ width: `${uploadProgress}%` }"
        ></div>
      </div>

      <!-- Error message -->
      <p v-if="error" class="text-sm text-red-600">{{ error }}</p>
    </div>

    <!-- Premium upsell -->
    <div v-else class="text-sm text-gray-500 bg-amber-50 border border-amber-200 rounded-lg p-3">
      <p class="font-medium text-amber-800">📎 Work Sample Attachments</p>
      <p class="text-amber-700">Upgrade to attach photos and documents to your log entries.</p>
    </div>
  </div>
</template>

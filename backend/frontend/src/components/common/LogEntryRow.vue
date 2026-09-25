<script setup lang="ts">
import { computed } from 'vue'
import type { LogEntry, Student, Subject } from '@/types'

interface Props {
  log: LogEntry
  student?: Student
  subject?: Subject
  showStudent?: boolean
  showActions?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  showStudent: true,
  showActions: false
})

const emit = defineEmits<{
  edit: [log: LogEntry]
  delete: [log: LogEntry]
}>()

const formattedDate = computed(() => {
  const date = new Date(props.log.date)
  return date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric'
  })
})

const locationLabel = computed(() => {
  const labels: Record<string, string> = {
    home: '🏠 Home',
    field_trip: '🚌 Field Trip',
    co_op: '👥 Co-op',
    online: '💻 Online',
    other: '📍 Other'
  }
  return labels[props.log.locationType] || props.log.locationType
})
</script>

<template>
  <div class="flex items-center gap-4 py-3 px-4 bg-white border-b border-gray-100 hover:bg-gray-50">
    <!-- Date -->
    <div class="w-24 flex-shrink-0">
      <span class="text-sm font-medium text-gray-900">{{ formattedDate }}</span>
    </div>

    <!-- Student (optional) -->
    <div v-if="showStudent && student" class="w-28 flex-shrink-0">
      <span class="text-sm text-gray-600">{{ student.name }}</span>
    </div>

    <!-- Subject -->
    <div class="w-32 flex-shrink-0">
      <span
        v-if="subject"
        :class="[
          'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium',
          subject.type === 'core' ? 'bg-blue-100 text-blue-800' : 'bg-green-100 text-green-800'
        ]"
      >
        {{ subject.name }}
      </span>
      <span v-else class="text-sm text-gray-500">Unknown</span>
    </div>

    <!-- Hours -->
    <div class="w-16 flex-shrink-0 text-right">
      <span class="text-sm font-semibold text-gray-900">{{ log.hours.toFixed(2) }}h</span>
    </div>

    <!-- Description -->
    <div class="flex-1 min-w-0">
      <p class="text-sm text-gray-600 truncate">{{ log.description || '—' }}</p>
    </div>

    <!-- Location -->
    <div class="w-24 flex-shrink-0 text-right">
      <span class="text-xs text-gray-500">{{ locationLabel }}</span>
    </div>

    <!-- Status -->
    <div class="w-20 flex-shrink-0 text-right">
      <span
        :class="[
          'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium',
          log.status === 'approved' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
        ]"
      >
        {{ log.status }}
      </span>
    </div>

    <!-- Actions -->
    <div v-if="showActions" class="flex items-center gap-2 flex-shrink-0">
      <button
        type="button"
        @click.stop="emit('edit', log)"
        class="p-1 text-gray-400 hover:text-primary-600"
        title="Edit"
      >
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
        </svg>
      </button>
      <button
        type="button"
        @click.stop="emit('delete', log)"
        class="p-1 text-gray-400 hover:text-red-600"
        title="Delete"
      >
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
        </svg>
      </button>
    </div>
  </div>
</template>

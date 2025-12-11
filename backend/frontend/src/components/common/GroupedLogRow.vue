<script setup lang="ts">
import { ref, computed } from 'vue'
import type { LogEntry, Student, Subject } from '@/types'

interface LogGroup {
  logs: LogEntry[]
  isGroup: boolean
  primaryLog: LogEntry
  totalHours: number
  studentIds: string[]
}

interface Props {
  group: LogGroup
  students: Student[]
  subjects: Subject[]
  showActions?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  showActions: false
})

const emit = defineEmits<{
  edit: [log: LogEntry]
  delete: [log: LogEntry]
}>()

const isExpanded = ref(false)

const subject = computed(() => 
  props.subjects.find(s => s.id === props.group.primaryLog.subjectId)
)

const studentNames = computed(() => 
  props.group.logs.map(log => {
    const student = props.students.find(s => s.id === log.studentId)
    return student?.name || 'Unknown'
  })
)

const formattedDate = computed(() => {
  const date = new Date(props.group.primaryLog.date)
  return date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric'
  })
})
</script>

<template>
  <div 
    class="bg-white border-b border-gray-100 hover:bg-gray-50 cursor-pointer"
    @click="isExpanded = !isExpanded"
  >
    <!-- Main Row -->
    <div class="flex items-center gap-4 py-3 px-4">
      <!-- Date -->
      <div class="w-24 flex-shrink-0">
        <span class="text-sm font-medium text-gray-900">{{ formattedDate }}</span>
      </div>

      <!-- Students (with badge for multi) -->
      <div class="w-36 flex-shrink-0">
        <div class="flex items-center gap-2">
          <span class="text-sm text-gray-600 truncate">{{ studentNames.join(', ') }}</span>
          <span 
            v-if="group.isGroup"
            class="inline-flex items-center px-1.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
          >
            👥 {{ group.logs.length }}
          </span>
        </div>
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
      <div class="w-24 flex-shrink-0 text-right">
        <span class="text-sm font-semibold text-gray-900">
          {{ group.primaryLog.hours }}h
          <span v-if="group.isGroup" class="text-gray-500 font-normal">each</span>
        </span>
      </div>

      <!-- Description -->
      <div class="flex-1 min-w-0">
        <p class="text-sm text-gray-600 truncate">{{ group.primaryLog.description || '—' }}</p>
      </div>

      <!-- Expand indicator for groups -->
      <div v-if="group.isGroup" class="w-6 flex-shrink-0 text-gray-400">
        <svg 
          :class="['w-5 h-5 transition-transform', { 'rotate-180': isExpanded }]"
          fill="none" 
          stroke="currentColor" 
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </div>

      <!-- Actions for single logs -->
      <div v-if="!group.isGroup && showActions" class="flex gap-1">
        <button
          class="p-1 text-gray-400 hover:text-primary-600"
          title="Edit"
          @click.stop="emit('edit', group.primaryLog)"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
          </svg>
        </button>
        <button
          class="p-1 text-gray-400 hover:text-red-600"
          title="Delete"
          @click.stop="emit('delete', group.primaryLog)"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Expanded Details for Groups -->
    <div v-if="group.isGroup && isExpanded" class="bg-gray-50 px-4 py-3 border-t border-gray-100">
      <div class="text-xs font-medium text-gray-500 mb-2">Individual entries:</div>
      <div class="space-y-2">
        <div 
          v-for="log in group.logs" 
          :key="log.id"
          class="flex items-center justify-between py-1 px-2 bg-white rounded"
        >
          <div class="flex items-center gap-3">
            <span class="text-sm">{{ students.find(s => s.id === log.studentId)?.name || 'Unknown' }}</span>
            <span class="text-sm font-medium text-blue-600">{{ log.hours }}h</span>
          </div>
          <div v-if="showActions" class="flex gap-1">
            <button
              class="p-1 text-gray-400 hover:text-primary-600"
              title="Edit"
              @click.stop="emit('edit', log)"
            >
              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
              </svg>
            </button>
            <button
              class="p-1 text-gray-400 hover:text-red-600"
              title="Delete"
              @click.stop="emit('delete', log)"
            >
              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </div>
      </div>
      <div class="mt-3 pt-2 border-t border-gray-200 flex justify-between text-sm">
        <span class="text-gray-500">Total:</span>
        <span class="font-semibold text-blue-600">{{ group.totalHours }}h</span>
      </div>
    </div>
  </div>
</template>

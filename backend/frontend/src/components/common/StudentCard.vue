<script setup lang="ts">
import type { Student, StudentStats } from '@/types'
import ProgressBar from './ProgressBar.vue'

interface Props {
  student: Student
  stats?: StudentStats
  clickable?: boolean
}

defineProps<Props>()

const emit = defineEmits<{
  click: [student: Student]
}>()
</script>

<template>
  <div
    :class="[
      'bg-white rounded-lg shadow p-4 border border-gray-200',
      clickable ? 'cursor-pointer hover:shadow-md hover:border-primary-300 transition-all' : ''
    ]"
    @click="clickable && emit('click', student)"
  >
    <div class="flex items-start justify-between">
      <div>
        <h3 class="text-lg font-medium text-gray-900">{{ student.name }}</h3>
        <p class="text-sm text-gray-500">{{ student.gradeLevel }}</p>
      </div>
      <span
        v-if="!student.active"
        class="px-2 py-1 text-xs font-medium bg-gray-100 text-gray-600 rounded"
      >
        Inactive
      </span>
    </div>

    <div v-if="stats" class="mt-4">
      <ProgressBar
        :current="stats.totalHours"
        label="Total Hours"
        size="sm"
      />
      
      <div v-if="stats.bySubject.length > 0" class="mt-3 space-y-2">
        <div
          v-for="subject in stats.bySubject.slice(0, 3)"
          :key="subject.subjectId"
          class="flex items-center justify-between text-sm"
        >
          <span class="text-gray-600">{{ subject.subjectName }}</span>
          <span class="font-medium text-gray-900">{{ subject.hours.toFixed(1) }}h</span>
        </div>
        <div v-if="stats.bySubject.length > 3" class="text-xs text-gray-400">
          +{{ stats.bySubject.length - 3 }} more subjects
        </div>
      </div>
    </div>

    <div v-else class="mt-4 text-sm text-gray-400">
      No hours logged yet
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useStudentsStore } from '@/stores/students'
import { useStatsStore } from '@/stores/stats'
import { useLogsStore } from '@/stores/logs'
import { StudentCard, ProgressBar } from '@/components/common'

const authStore = useAuthStore()
const studentsStore = useStudentsStore()
const statsStore = useStatsStore()
const logsStore = useLogsStore()

// Load data on mount
onMounted(async () => {
  await Promise.all([
    studentsStore.fetchStudents(),
    statsStore.fetchFamilyStats(authStore.currentSchoolYear),
    logsStore.fetchLogs({ limit: 5 })
  ])
})

const students = computed(() => studentsStore.activeStudents)
const familyStats = computed(() => statsStore.familyStats)
const recentLogs = computed(() => logsStore.logs.slice(0, 5))
const loading = computed(() => studentsStore.loading || statsStore.loading)

// Get stats for a specific student
function getStudentStats(studentId: string) {
  return familyStats.value?.students.find(s => s.studentId === studentId)
}

// Calculate today's hours from recent logs
const todayHours = computed(() => {
  const today = new Date().toISOString().split('T')[0]
  return logsStore.logs
    .filter(log => log.date.startsWith(today))
    .reduce((sum, log) => sum + log.hours, 0)
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p v-if="authStore.family" class="text-sm text-gray-500">
          {{ authStore.family.name }} • {{ authStore.currentSchoolYear }}
        </p>
      </div>
      <router-link to="/log" class="btn-primary">
        + Quick Log
      </router-link>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="text-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600 mx-auto"></div>
      <p class="mt-2 text-sm text-gray-500">Loading...</p>
    </div>

    <template v-else>
      <!-- Today's Summary -->
      <div class="card">
        <h2 class="text-lg font-medium text-gray-900 mb-4">Today's Activity</h2>
        <div v-if="todayHours > 0" class="flex items-center gap-4">
          <div class="text-4xl font-bold text-primary-600">{{ todayHours.toFixed(1) }}</div>
          <div class="text-gray-500">hours logged today</div>
        </div>
        <p v-else class="text-gray-500">No logs recorded today. Start logging!</p>
      </div>

      <!-- Students Overview -->
      <div v-if="students.length > 0">
        <h2 class="text-lg font-medium text-gray-900 mb-4">Students</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <StudentCard
            v-for="student in students"
            :key="student.id"
            :student="student"
            :stats="getStudentStats(student.id)"
            clickable
            @click="$router.push(`/students/${student.id}`)"
          />
        </div>
      </div>
      <div v-else class="card">
        <h2 class="text-lg font-medium text-gray-900 mb-4">Students</h2>
        <p class="text-gray-500">
          No students added yet.
          <router-link to="/students" class="text-primary-600 hover:text-primary-700">
            Add your first student
          </router-link>
        </p>
      </div>

      <!-- Year Progress -->
      <div class="card">
        <h2 class="text-lg font-medium text-gray-900 mb-4">Year Progress</h2>
        <div v-if="familyStats" class="space-y-4">
          <ProgressBar
            :current="familyStats.totalHours"
            :target="1000"
            label="Total Hours"
            color="primary"
          />
          <!-- Show per-student breakdown -->
          <div v-if="familyStats.students.length > 0" class="mt-4 pt-4 border-t border-gray-200">
            <h3 class="text-sm font-medium text-gray-700 mb-3">By Student</h3>
            <div class="space-y-3">
              <div v-for="stat in familyStats.students" :key="stat.studentId">
                <ProgressBar
                  :current="stat.totalHours"
                  :target="1000"
                  :label="stat.studentName"
                  color="blue"
                  size="sm"
                />
              </div>
            </div>
          </div>
        </div>
        <div v-else class="text-gray-500">
          Add students and start logging to track progress.
        </div>
      </div>

      <!-- Recent Logs -->
      <div class="card">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-lg font-medium text-gray-900">Recent Logs</h2>
          <router-link
            v-if="recentLogs.length > 0"
            to="/logs"
            class="text-sm text-primary-600 hover:text-primary-700"
          >
            View all →
          </router-link>
        </div>
        <div v-if="recentLogs.length > 0" class="space-y-2">
          <div
            v-for="log in recentLogs"
            :key="log.id"
            class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
          >
            <div>
              <span class="font-medium">{{ log.hours.toFixed(2) }}h</span>
              <span class="text-gray-500 ml-2">{{ log.description || 'No description' }}</span>
            </div>
            <span class="text-sm text-gray-400">
              {{ new Date(log.date).toLocaleDateString() }}
            </span>
          </div>
        </div>
        <p v-else class="text-gray-500">No recent activity.</p>
      </div>
    </template>
  </div>
</template>

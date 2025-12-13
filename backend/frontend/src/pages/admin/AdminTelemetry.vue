<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { getTelemetryStats, getTelemetryDAU, type TelemetryStats, type DailyCount } from '../../api/admin'

const stats = ref<TelemetryStats | null>(null)
const dau = ref<DailyCount[]>([])
const loading = ref(true)
const error = ref('')

async function loadStats() {
  loading.value = true
  error.value = ''
  try {
    const [statsData, dauData] = await Promise.all([
      getTelemetryStats(),
      getTelemetryDAU()
    ])
    stats.value = statsData
    dau.value = dauData
  } catch (e: any) {
    error.value = e.response?.data?.error || 'Failed to load telemetry stats'
  } finally {
    loading.value = false
  }
}

onMounted(loadStats)

const topEvents = computed(() => {
  if (!stats.value) return []
  return Object.entries(stats.value.eventBreakdown)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
})

const topVersions = computed(() => {
  if (!stats.value) return []
  return Object.entries(stats.value.versionBreakdown)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
})

function formatEventName(name: string): string {
  return name.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
}
</script>

<template>
  <div>
    <div class="mb-6">
      <h2 class="text-xl font-semibold text-gray-900">📊 Telemetry & Analytics</h2>
      <p class="text-sm text-gray-500">Anonymous usage data (no PII)</p>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-4">
      <p class="text-red-600">{{ error }}</p>
      <button @click="loadStats" class="mt-2 text-red-700 underline">Retry</button>
    </div>

    <!-- Stats -->
    <div v-else-if="stats">
      <!-- Key Metrics -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Total Events</p>
          <p class="text-3xl font-bold text-gray-900">{{ stats.totalEvents.toLocaleString() }}</p>
        </div>
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Unique Installs</p>
          <p class="text-3xl font-bold text-indigo-600">{{ stats.uniqueInstalls.toLocaleString() }}</p>
        </div>
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Active Today</p>
          <p class="text-3xl font-bold text-emerald-600">{{ stats.activeToday.toLocaleString() }}</p>
        </div>
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <p class="text-sm text-gray-500">Active This Month</p>
          <p class="text-3xl font-bold text-amber-600">{{ stats.activeThisMonth.toLocaleString() }}</p>
        </div>
      </div>

      <!-- DAU Chart (simple bars) -->
      <div class="bg-white rounded-xl shadow-sm border p-6 mb-8">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Daily Active Users (Last 30 Days)</h3>
        <div v-if="dau.length === 0" class="text-gray-500 text-sm">No data yet</div>
        <div v-else class="flex items-end gap-1 h-40">
          <div
            v-for="day in dau"
            :key="day.date"
            class="flex-1 bg-indigo-500 rounded-t min-h-[4px] transition-all hover:bg-indigo-600"
            :style="{ height: `${Math.max((day.count / Math.max(...dau.map(d => d.count))) * 100, 4)}%` }"
            :title="`${day.date}: ${day.count} users`"
          ></div>
        </div>
        <div class="flex justify-between text-xs text-gray-400 mt-2">
          <span>{{ dau[0]?.date }}</span>
          <span>{{ dau[dau.length - 1]?.date }}</span>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <!-- Platform Breakdown -->
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Platform Breakdown</h3>
          <div class="space-y-3">
            <div
              v-for="(count, platform) in stats.platformBreakdown"
              :key="platform"
              class="flex items-center justify-between"
            >
              <div class="flex items-center gap-2">
                <span v-if="platform === 'ios'">🍎</span>
                <span v-else-if="platform === 'android'">🤖</span>
                <span v-else-if="platform === 'windows'">🪟</span>
                <span v-else-if="platform === 'web'">🌐</span>
                <span v-else-if="platform === 'macos'">💻</span>
                <span v-else>❓</span>
                <span class="capitalize">{{ platform }}</span>
              </div>
              <span class="font-semibold">{{ count.toLocaleString() }}</span>
            </div>
          </div>
        </div>

        <!-- Top Versions -->
        <div class="bg-white rounded-xl shadow-sm border p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">App Versions (Last 30 Days)</h3>
          <div v-if="topVersions.length === 0" class="text-gray-500 text-sm">No data yet</div>
          <div v-else class="space-y-3">
            <div
              v-for="[version, count] in topVersions"
              :key="version"
              class="flex items-center justify-between"
            >
              <span class="font-mono text-sm">v{{ version || 'unknown' }}</span>
              <span class="font-semibold">{{ count.toLocaleString() }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Top Events -->
      <div class="bg-white rounded-xl shadow-sm border p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Top Events</h3>
        <div v-if="topEvents.length === 0" class="text-gray-500 text-sm">No events yet</div>
        <div v-else class="grid grid-cols-2 md:grid-cols-5 gap-4">
          <div
            v-for="[event, count] in topEvents"
            :key="event"
            class="bg-gray-50 rounded-lg p-4"
          >
            <p class="text-xs text-gray-500 truncate">{{ formatEventName(event) }}</p>
            <p class="text-lg font-bold text-gray-900">{{ count.toLocaleString() }}</p>
          </div>
        </div>
      </div>

      <!-- Privacy Notice -->
      <div class="mt-6 bg-green-50 border border-green-200 rounded-lg p-4">
        <p class="text-green-800 text-sm">
          <strong>🔒 Privacy:</strong> All data is anonymous. Install IDs are random UUIDs not linked to any identity.
          Users can opt out in settings. No PII is collected.
        </p>
      </div>
    </div>
  </div>
</template>

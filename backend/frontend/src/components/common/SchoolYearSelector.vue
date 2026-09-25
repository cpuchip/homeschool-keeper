<script setup lang="ts">
import { computed, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const selectedYear = computed({
  get: () => authStore.effectiveSchoolYear,
  set: (value: string) => authStore.setSelectedSchoolYear(value)
})

const years = computed(() => authStore.availableSchoolYears)
const currentYear = computed(() => authStore.currentSchoolYear)

// Emit event when year changes so parent can refresh data
const emit = defineEmits<{
  change: [year: string]
}>()

watch(selectedYear, (newYear) => {
  emit('change', newYear)
})
</script>

<template>
  <div class="inline-flex items-center gap-2">
    <label class="text-sm text-gray-500">Year:</label>
    <select 
      v-model="selectedYear"
      class="text-sm border border-gray-300 rounded-md px-2 py-1 bg-white focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
    >
      <option 
        v-for="year in years" 
        :key="year" 
        :value="year"
      >
        {{ year }}{{ year === currentYear ? ' (current)' : '' }}
      </option>
    </select>
  </div>
</template>

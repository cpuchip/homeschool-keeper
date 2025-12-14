<script setup lang="ts">
import { computed, ref, watch } from 'vue'

interface Props {
  startDate?: string
  endDate?: string
  label?: string
  presets?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  presets: true
})

const emit = defineEmits<{
  'update:startDate': [value: string]
  'update:endDate': [value: string]
  change: [start: string, end: string]
}>()

const localStart = ref(props.startDate || '')
const localEnd = ref(props.endDate || '')

watch(() => props.startDate, (val) => { localStart.value = val || '' })
watch(() => props.endDate, (val) => { localEnd.value = val || '' })

function updateStart(event: Event) {
  const value = (event.target as HTMLInputElement).value
  localStart.value = value
  emit('update:startDate', value)
  emit('change', value, localEnd.value)
}

function updateEnd(event: Event) {
  const value = (event.target as HTMLInputElement).value
  localEnd.value = value
  emit('update:endDate', value)
  emit('change', localStart.value, value)
}

// Preset ranges
const presetRanges = computed(() => {
  const today = new Date()
  const thisWeekStart = new Date(today)
  thisWeekStart.setDate(today.getDate() - today.getDay())
  
  const thisMonthStart = new Date(today.getFullYear(), today.getMonth(), 1)
  
  const lastMonthStart = new Date(today.getFullYear(), today.getMonth() - 1, 1)
  const lastMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0)
  
  return [
    {
      label: 'This Week',
      start: thisWeekStart.toISOString().split('T')[0],
      end: today.toISOString().split('T')[0]
    },
    {
      label: 'This Month',
      start: thisMonthStart.toISOString().split('T')[0],
      end: today.toISOString().split('T')[0]
    },
    {
      label: 'Last Month',
      start: lastMonthStart.toISOString().split('T')[0],
      end: lastMonthEnd.toISOString().split('T')[0]
    },
    {
      label: 'Last 30 Days',
      start: new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      end: today.toISOString().split('T')[0]
    }
  ]
})

function applyPreset(preset: { start: string; end: string }) {
  localStart.value = preset.start
  localEnd.value = preset.end
  emit('update:startDate', preset.start)
  emit('update:endDate', preset.end)
  emit('change', preset.start, preset.end)
}

function clear() {
  localStart.value = ''
  localEnd.value = ''
  emit('update:startDate', '')
  emit('update:endDate', '')
  emit('change', '', '')
}
</script>

<template>
  <div class="w-full">
    <label v-if="label" class="block text-sm font-medium text-gray-700 mb-2">
      {{ label }}
    </label>

    <div class="flex flex-wrap gap-2 mb-2" v-if="presets">
      <button
        v-for="preset in presetRanges"
        :key="preset.label"
        type="button"
        @click="applyPreset(preset)"
        class="px-2 py-1 text-xs font-medium text-gray-600 bg-gray-100 rounded hover:bg-gray-200"
      >
        {{ preset.label }}
      </button>
      <button
        v-if="localStart || localEnd"
        type="button"
        @click="clear"
        class="px-2 py-1 text-xs font-medium text-red-600 bg-red-50 rounded hover:bg-red-100"
      >
        Clear
      </button>
    </div>

    <div class="flex gap-2 items-center">
      <div class="flex-1">
        <label class="sr-only">Start date</label>
        <input
          type="date"
          :value="localStart"
          @input="updateStart"
          class="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm"
          placeholder="Start date"
        />
      </div>
      <span class="text-gray-500">to</span>
      <div class="flex-1">
        <label class="sr-only">End date</label>
        <input
          type="date"
          :value="localEnd"
          @input="updateEnd"
          class="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm"
          placeholder="End date"
        />
      </div>
    </div>
  </div>
</template>

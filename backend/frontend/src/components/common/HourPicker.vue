<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  modelValue: number
  increment?: number // 0.25, 0.5, 1.0
  min?: number
  max?: number
  label?: string
  error?: string
  disabled?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  increment: 0.25,
  min: 0,
  max: 24,
  disabled: false
})

const emit = defineEmits<{
  'update:modelValue': [value: number]
}>()

// Generate options based on increment
const options = computed(() => {
  const result: number[] = []
  for (let i = props.min; i <= props.max; i += props.increment) {
    result.push(Math.round(i * 100) / 100) // Avoid floating point issues
  }
  return result
})

// Format hours for display
function formatHours(hours: number): string {
  if (hours === 0) return '0 hours'
  if (hours === 1) return '1 hour'
  if (hours < 1) {
    const minutes = Math.round(hours * 60)
    return `${minutes} min`
  }
  // For mixed hours and minutes
  const wholeHours = Math.floor(hours)
  const minutes = Math.round((hours - wholeHours) * 60)
  if (minutes === 0) {
    return `${wholeHours} hour${wholeHours !== 1 ? 's' : ''}`
  }
  return `${wholeHours}h ${minutes}m`
}

function increment() {
  const newValue = Math.min(props.modelValue + props.increment, props.max)
  emit('update:modelValue', Math.round(newValue * 100) / 100)
}

function decrement() {
  const newValue = Math.max(props.modelValue - props.increment, props.min)
  emit('update:modelValue', Math.round(newValue * 100) / 100)
}

function handleSelectChange(event: Event) {
  const target = event.target as HTMLSelectElement
  emit('update:modelValue', parseFloat(target.value))
}
</script>

<template>
  <div class="w-full">
    <label v-if="label" class="block text-sm font-medium text-gray-700 mb-1">
      {{ label }}
    </label>
    
    <div class="flex items-center gap-2">
      <!-- Decrement button -->
      <button
        type="button"
        @click="decrement"
        :disabled="disabled || modelValue <= min"
        class="p-2 rounded-md bg-gray-100 hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4" />
        </svg>
      </button>

      <!-- Select dropdown -->
      <select
        :value="modelValue"
        @change="handleSelectChange"
        :disabled="disabled"
        :class="[
          'flex-1 rounded-md border-gray-300 shadow-sm text-center',
          'focus:border-primary-500 focus:ring-primary-500 sm:text-sm',
          disabled ? 'bg-gray-50 text-gray-500' : 'bg-white'
        ]"
      >
        <option v-for="opt in options" :key="opt" :value="opt">
          {{ formatHours(opt) }}
        </option>
      </select>

      <!-- Increment button -->
      <button
        type="button"
        @click="increment"
        :disabled="disabled || modelValue >= max"
        class="p-2 rounded-md bg-gray-100 hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
      </button>
    </div>

    <p v-if="error" class="mt-1 text-sm text-red-600">{{ error }}</p>
  </div>
</template>

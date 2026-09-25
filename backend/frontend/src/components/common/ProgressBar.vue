<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  current: number
  target?: number
  label?: string
  color?: string
  showNumbers?: boolean
  size?: 'sm' | 'md' | 'lg'
}

const props = withDefaults(defineProps<Props>(), {
  color: 'primary',
  showNumbers: true,
  size: 'md'
})

const percentage = computed(() => {
  if (!props.target || props.target === 0) return 0
  return Math.min(Math.round((props.current / props.target) * 100), 100)
})

const colorClasses = computed(() => {
  const colors: Record<string, string> = {
    primary: 'bg-primary-600',
    green: 'bg-green-500',
    blue: 'bg-blue-500',
    yellow: 'bg-yellow-500',
    red: 'bg-red-500',
    purple: 'bg-purple-500',
    pink: 'bg-pink-500',
    orange: 'bg-orange-500'
  }
  return colors[props.color] || colors.primary
})

const sizeClasses = computed(() => {
  return {
    sm: 'h-1.5',
    md: 'h-2',
    lg: 'h-3'
  }[props.size]
})
</script>

<template>
  <div class="w-full">
    <div v-if="label || showNumbers" class="flex justify-between items-center mb-1">
      <span v-if="label" class="text-sm font-medium text-gray-700">{{ label }}</span>
      <span v-if="showNumbers" class="text-sm text-gray-500">
        {{ current.toFixed(1) }}<span v-if="target"> / {{ target.toFixed(1) }}</span> hours
      </span>
    </div>
    
    <div :class="['w-full bg-gray-200 rounded-full overflow-hidden', sizeClasses]">
      <div
        :class="['rounded-full transition-all duration-300', colorClasses, sizeClasses]"
        :style="{ width: `${percentage}%` }"
      ></div>
    </div>

    <div v-if="target" class="mt-1 text-xs text-gray-500 text-right">
      {{ percentage }}% complete
    </div>
  </div>
</template>

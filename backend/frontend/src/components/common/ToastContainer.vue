<script setup lang="ts">
import { toast, type ToastType } from '@/composables/useToast'

function getToastClasses(type: ToastType): string {
  const base = 'px-4 py-3 rounded-lg shadow-lg flex items-center gap-3 min-w-[300px] max-w-md'
  switch (type) {
    case 'success':
      return `${base} bg-green-600 text-white`
    case 'error':
      return `${base} bg-red-600 text-white`
    case 'warning':
      return `${base} bg-amber-500 text-white`
    case 'info':
    default:
      return `${base} bg-blue-600 text-white`
  }
}

function getIcon(type: ToastType): string {
  switch (type) {
    case 'success':
      return '✓'
    case 'error':
      return '✕'
    case 'warning':
      return '⚠'
    case 'info':
    default:
      return 'ℹ'
  }
}
</script>

<template>
  <Teleport to="body">
    <div class="fixed top-4 right-4 z-50 flex flex-col gap-2">
      <TransitionGroup name="toast">
        <div
          v-for="t in toast.toasts"
          :key="t.id"
          :class="getToastClasses(t.type)"
        >
          <span class="text-lg font-bold">{{ getIcon(t.type) }}</span>
          <span class="flex-1">{{ t.message }}</span>
          <button
            @click="toast.remove(t.id)"
            class="text-white/80 hover:text-white font-bold text-lg"
          >
            ×
          </button>
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<style scoped>
.toast-enter-active {
  transition: all 0.3s ease-out;
}
.toast-leave-active {
  transition: all 0.2s ease-in;
}
.toast-enter-from {
  transform: translateX(100%);
  opacity: 0;
}
.toast-leave-to {
  transform: translateX(100%);
  opacity: 0;
}
.toast-move {
  transition: transform 0.3s ease;
}
</style>

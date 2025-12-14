import { reactive } from 'vue'

export type ToastType = 'success' | 'error' | 'warning' | 'info'

export interface Toast {
  id: number
  message: string
  type: ToastType
  duration: number
}

const toasts = reactive<Toast[]>([])
let toastId = 0

export function useToast() {
  function show(message: string, type: ToastType = 'info', duration: number = 4000) {
    const id = ++toastId
    const toast: Toast = { id, message, type, duration }
    toasts.push(toast)

    if (duration > 0) {
      setTimeout(() => {
        remove(id)
      }, duration)
    }

    return id
  }

  function remove(id: number) {
    const index = toasts.findIndex(t => t.id === id)
    if (index !== -1) {
      toasts.splice(index, 1)
    }
  }

  function success(message: string, duration?: number) {
    return show(message, 'success', duration)
  }

  function error(message: string, duration?: number) {
    return show(message, 'error', duration ?? 6000) // errors show longer
  }

  function warning(message: string, duration?: number) {
    return show(message, 'warning', duration)
  }

  function info(message: string, duration?: number) {
    return show(message, 'info', duration)
  }

  return {
    toasts,
    show,
    remove,
    success,
    error,
    warning,
    info,
  }
}

// Export a singleton for use across the app
export const toast = useToast()

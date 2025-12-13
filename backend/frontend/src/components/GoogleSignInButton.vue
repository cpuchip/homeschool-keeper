<script setup lang="ts">
import { onMounted, onUnmounted, ref, watch } from 'vue'

const props = defineProps<{
  disabled?: boolean
}>()

// Watch for disabled prop changes
watch(() => props.disabled, (newVal) => {
  if (buttonRef.value) {
    buttonRef.value.style.pointerEvents = newVal ? 'none' : 'auto'
    buttonRef.value.style.opacity = newVal ? '0.5' : '1'
  }
})

const emit = defineEmits<{
  (e: 'success', idToken: string): void
  (e: 'error', error: string): void
}>()

// Google Client ID from environment
const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID || ''

const buttonRef = ref<HTMLDivElement | null>(null)
const scriptLoaded = ref(false)

declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (config: {
            client_id: string
            callback: (response: { credential: string }) => void
            auto_select?: boolean
            cancel_on_tap_outside?: boolean
          }) => void
          renderButton: (
            element: HTMLElement,
            config: {
              theme?: 'outline' | 'filled_blue' | 'filled_black'
              size?: 'large' | 'medium' | 'small'
              text?: 'signin_with' | 'signup_with' | 'continue_with' | 'signin'
              shape?: 'rectangular' | 'pill' | 'circle' | 'square'
              width?: number
            }
          ) => void
          prompt: () => void
          disableAutoSelect: () => void
        }
      }
    }
  }
}

function handleCredentialResponse(response: { credential: string }) {
  if (response.credential) {
    emit('success', response.credential)
  } else {
    emit('error', 'No credential returned from Google')
  }
}

function initializeGoogleSignIn() {
  if (!window.google?.accounts?.id) {
    console.error('Google Identity Services not loaded')
    return
  }

  if (!GOOGLE_CLIENT_ID) {
    console.error('Google Client ID not configured')
    return
  }

  window.google.accounts.id.initialize({
    client_id: GOOGLE_CLIENT_ID,
    callback: handleCredentialResponse,
    auto_select: false,
    cancel_on_tap_outside: true
  })

  if (buttonRef.value) {
    window.google.accounts.id.renderButton(buttonRef.value, {
      theme: 'outline',
      size: 'large',
      text: 'signin_with',
      shape: 'rectangular',
      width: 300
    })
  }
}

function loadGoogleScript() {
  // Check if already loaded
  if (window.google?.accounts?.id) {
    scriptLoaded.value = true
    initializeGoogleSignIn()
    return
  }

  // Check if script is already in DOM
  if (document.getElementById('google-gsi-script')) {
    return
  }

  const script = document.createElement('script')
  script.id = 'google-gsi-script'
  script.src = 'https://accounts.google.com/gsi/client'
  script.async = true
  script.defer = true
  script.onload = () => {
    scriptLoaded.value = true
    initializeGoogleSignIn()
  }
  script.onerror = () => {
    emit('error', 'Failed to load Google Sign-In')
  }
  document.head.appendChild(script)
}

onMounted(() => {
  if (GOOGLE_CLIENT_ID) {
    loadGoogleScript()
  }
})

onUnmounted(() => {
  // Cleanup if needed
  if (window.google?.accounts?.id) {
    window.google.accounts.id.disableAutoSelect()
  }
})
</script>

<template>
  <div class="google-signin-wrapper">
    <div v-if="!GOOGLE_CLIENT_ID" class="text-sm text-gray-400 text-center py-2">
      Google Sign-In not configured
    </div>
    <div
      v-else
      ref="buttonRef"
      :class="{ 'opacity-50 pointer-events-none': disabled }"
    />
  </div>
</template>

<style scoped>
.google-signin-wrapper {
  display: flex;
  justify-content: center;
}
</style>

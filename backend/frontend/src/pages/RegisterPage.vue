<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import GoogleSignInButton from '@/components/GoogleSignInButton.vue'

const router = useRouter()
const authStore = useAuthStore()

const name = ref('')
const familyName = ref('')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const error = ref('')
const loading = ref(false)

async function handleSubmit() {
  error.value = ''

  if (password.value !== confirmPassword.value) {
    error.value = 'Passwords do not match'
    return
  }

  if (password.value.length < 12) {
    error.value = 'Password must be at least 12 characters'
    return
  }

  loading.value = true

  try {
    await authStore.register({
      name: name.value,
      email: email.value,
      password: password.value,
      familyName: familyName.value || `${name.value}'s Family`
    })
    // Redirect to onboarding to complete setup
    router.push('/onboarding')
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    error.value = err.response?.data?.error || 'Registration failed'
  } finally {
    loading.value = false
  }
}

async function handleGoogleSuccess(idToken: string) {
  error.value = ''
  loading.value = true

  try {
    await authStore.loginWithGoogle(idToken, familyName.value)
    // New users from Google always need onboarding
    router.push('/onboarding')
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    error.value = err.response?.data?.error || 'Google sign-up failed'
  } finally {
    loading.value = false
  }
}

function handleGoogleError(errorMessage: string) {
  error.value = errorMessage
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <div>
        <h1 class="text-center text-4xl font-bold text-primary-600">📚</h1>
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Create your account
        </h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Start tracking your homeschool journey
        </p>
      </div>

      <div v-if="error" class="rounded-md bg-red-50 p-4">
        <p class="text-sm text-red-700">{{ error }}</p>
      </div>

      <!-- Google Sign-In -->
      <div class="mt-6">
        <GoogleSignInButton
          :disabled="loading"
          @success="handleGoogleSuccess"
          @error="handleGoogleError"
        />
      </div>

      <!-- Divider -->
      <div class="relative">
        <div class="absolute inset-0 flex items-center">
          <div class="w-full border-t border-gray-300" />
        </div>
        <div class="relative flex justify-center text-sm">
          <span class="px-2 bg-gray-50 text-gray-500">Or register with email</span>
        </div>
      </div>

      <form class="space-y-6" @submit.prevent="handleSubmit">
        <div class="space-y-4">
          <div>
            <label for="name" class="label">Your Name</label>
            <input
              id="name"
              v-model="name"
              name="name"
              type="text"
              required
              class="mt-1 input"
              placeholder="Your name"
            />
          </div>

          <div>
            <label for="familyName" class="label">Family Name</label>
            <input
              id="familyName"
              v-model="familyName"
              name="familyName"
              type="text"
              class="mt-1 input"
              placeholder="The Smith Family (optional)"
            />
            <p class="mt-1 text-xs text-gray-500">Leave blank to use "Your Name's Family"</p>
          </div>

          <div>
            <label for="email" class="label">Email address</label>
            <input
              id="email"
              v-model="email"
              name="email"
              type="email"
              autocomplete="email"
              required
              class="mt-1 input"
              placeholder="you@example.com"
            />
          </div>

          <div>
            <label for="password" class="label">Password</label>
            <input
              id="password"
              v-model="password"
              name="password"
              type="password"
              required
              class="mt-1 input"
              placeholder="At least 12 characters"
            />
          </div>

          <div>
            <label for="confirmPassword" class="label">Confirm Password</label>
            <input
              id="confirmPassword"
              v-model="confirmPassword"
              name="confirmPassword"
              type="password"
              required
              class="mt-1 input"
              placeholder="Confirm your password"
            />
          </div>
        </div>

        <div>
          <button
            type="submit"
            :disabled="loading"
            class="w-full btn-primary"
          >
            {{ loading ? 'Creating account...' : 'Create account' }}
          </button>
        </div>

        <div class="text-center">
          <router-link to="/login" class="font-medium text-primary-600 hover:text-primary-500">
            Already have an account? Sign in
          </router-link>
        </div>
      </form>
    </div>
  </div>
</template>

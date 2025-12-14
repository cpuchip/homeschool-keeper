<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import GoogleSignInButton from '@/components/GoogleSignInButton.vue'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

async function handleSubmit() {
  error.value = ''
  loading.value = true

  try {
    await authStore.login(email.value, password.value)
    const redirect = route.query.redirect as string || '/'
    router.push(redirect)
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    error.value = err.response?.data?.error || 'Invalid email or password'
  } finally {
    loading.value = false
  }
}

async function handleGoogleSuccess(idToken: string) {
  error.value = ''
  loading.value = true

  try {
    const response = await authStore.loginWithGoogle(idToken)
    
    // If new user, redirect to onboarding
    if (response.isNewUser) {
      router.push('/onboarding')
    } else {
      const redirect = route.query.redirect as string || '/'
      router.push(redirect)
    }
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    error.value = err.response?.data?.error || 'Google sign-in failed'
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
          Homeschool Keeper
        </h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Sign in to manage your homeschool records
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
          <span class="px-2 bg-gray-50 text-gray-500">Or continue with email</span>
        </div>
      </div>

      <form class="space-y-6" @submit.prevent="handleSubmit">
        <div class="rounded-md shadow-sm -space-y-px">
          <div>
            <label for="email" class="sr-only">Email address</label>
            <input
              id="email"
              v-model="email"
              name="email"
              type="email"
              autocomplete="email"
              required
              class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm"
              placeholder="Email address"
            />
          </div>
          <div>
            <label for="password" class="sr-only">Password</label>
            <input
              id="password"
              v-model="password"
              name="password"
              type="password"
              autocomplete="current-password"
              required
              class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm"
              placeholder="Password"
            />
          </div>
        </div>

        <div>
          <button
            type="submit"
            :disabled="loading"
            class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50"
          >
            {{ loading ? 'Signing in...' : 'Sign in' }}
          </button>
        </div>

        <div class="text-center">
          <router-link to="/register" class="font-medium text-primary-600 hover:text-primary-500">
            Don't have an account? Register
          </router-link>
        </div>
      </form>
    </div>
  </div>
</template>

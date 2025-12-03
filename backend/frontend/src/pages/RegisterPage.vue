<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const name = ref('')
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
    await authStore.register(name.value, email.value, password.value)
    router.push('/')
  } catch (e: any) {
    error.value = e.response?.data?.error?.message || 'Registration failed'
  } finally {
    loading.value = false
  }
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

      <form class="mt-8 space-y-6" @submit.prevent="handleSubmit">
        <div v-if="error" class="rounded-md bg-red-50 p-4">
          <p class="text-sm text-red-700">{{ error }}</p>
        </div>

        <div class="space-y-4">
          <div>
            <label for="name" class="label">Name</label>
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

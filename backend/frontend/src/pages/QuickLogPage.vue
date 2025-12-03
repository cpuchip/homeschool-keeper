<script setup lang="ts">
import { ref } from 'vue'

const studentId = ref('')
const subjectId = ref('')
const hours = ref(1)
const description = ref('')
const date = ref(new Date().toISOString().split('T')[0])
const location = ref<'home' | 'other'>('home')

const hourIncrement = 0.25 // TODO: Get from org settings

function incrementHours() {
  hours.value = Math.min(24, hours.value + hourIncrement)
}

function decrementHours() {
  hours.value = Math.max(hourIncrement, hours.value - hourIncrement)
}

function setHours(value: number) {
  hours.value = value
}

async function handleSubmit() {
  // TODO: Submit log entry
  console.log({
    studentId: studentId.value,
    subjectId: subjectId.value,
    hours: hours.value,
    description: description.value,
    date: date.value,
    location: location.value
  })
}
</script>

<template>
  <div class="max-w-2xl mx-auto">
    <h1 class="text-2xl font-bold text-gray-900 mb-6">Quick Log</h1>

    <form @submit.prevent="handleSubmit" class="card space-y-6">
      <!-- Student -->
      <div>
        <label for="student" class="label">Student</label>
        <select id="student" v-model="studentId" class="mt-1 input" required>
          <option value="">Select a student</option>
          <!-- TODO: Populate from store -->
        </select>
      </div>

      <!-- Subject -->
      <div>
        <label for="subject" class="label">Subject</label>
        <select id="subject" v-model="subjectId" class="mt-1 input" required>
          <option value="">Select a subject</option>
          <!-- TODO: Populate from store -->
        </select>
      </div>

      <!-- Hours -->
      <div>
        <label class="label">Hours</label>
        <div class="mt-2 flex items-center justify-center space-x-4">
          <button
            type="button"
            @click="decrementHours"
            class="w-12 h-12 rounded-full bg-gray-200 hover:bg-gray-300 text-2xl font-bold"
          >
            −
          </button>
          <div class="text-4xl font-bold w-24 text-center">
            {{ hours }}
          </div>
          <button
            type="button"
            @click="incrementHours"
            class="w-12 h-12 rounded-full bg-gray-200 hover:bg-gray-300 text-2xl font-bold"
          >
            +
          </button>
        </div>
        <!-- Quick presets -->
        <div class="mt-4 flex justify-center space-x-2">
          <button
            v-for="preset in [0.5, 1, 1.5, 2, 3]"
            :key="preset"
            type="button"
            @click="setHours(preset)"
            :class="[
              'px-3 py-1 rounded-full text-sm',
              hours === preset
                ? 'bg-primary-600 text-white'
                : 'bg-gray-100 hover:bg-gray-200 text-gray-700'
            ]"
          >
            {{ preset }}h
          </button>
        </div>
      </div>

      <!-- Date -->
      <div>
        <label for="date" class="label">Date</label>
        <input
          id="date"
          v-model="date"
          type="date"
          class="mt-1 input"
          required
        />
      </div>

      <!-- Location -->
      <div>
        <label class="label">Location</label>
        <div class="mt-2 flex space-x-4">
          <label class="flex items-center">
            <input
              type="radio"
              v-model="location"
              value="home"
              class="h-4 w-4 text-primary-600 focus:ring-primary-500"
            />
            <span class="ml-2 text-sm text-gray-700">At Home</span>
          </label>
          <label class="flex items-center">
            <input
              type="radio"
              v-model="location"
              value="other"
              class="h-4 w-4 text-primary-600 focus:ring-primary-500"
            />
            <span class="ml-2 text-sm text-gray-700">Other Location</span>
          </label>
        </div>
      </div>

      <!-- Description -->
      <div>
        <label for="description" class="label">Description</label>
        <textarea
          id="description"
          v-model="description"
          rows="3"
          class="mt-1 input"
          placeholder="What did they learn today?"
        ></textarea>
      </div>

      <!-- Submit -->
      <div class="flex space-x-4">
        <button type="submit" class="flex-1 btn-primary">
          Save Log
        </button>
        <button type="button" class="flex-1 btn-secondary">
          Save & Add Another
        </button>
      </div>
    </form>
  </div>
</template>

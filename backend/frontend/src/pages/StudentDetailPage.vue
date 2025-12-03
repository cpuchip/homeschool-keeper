<script setup lang="ts">
import { useRoute } from 'vue-router'

const route = useRoute()
const studentId = route.params.id
</script>

<template>
  <div class="space-y-6">
    <h1 class="text-2xl font-bold text-gray-900">Student Details</h1>
    <p class="text-gray-500">Student ID: {{ studentId }}</p>
    <!-- TODO: Implement student detail view -->
  </div>
</template>

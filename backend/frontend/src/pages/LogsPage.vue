<script setup lang="ts">
// Logs history page
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-900">Log History</h1>
      <router-link to="/log" class="btn-primary">+ New Log</router-link>
    </div>

    <!-- Filters -->
    <div class="card">
      <div class="flex flex-wrap gap-4">
        <select class="input w-auto">
          <option value="">All Students</option>
        </select>
        <select class="input w-auto">
          <option value="">All Subjects</option>
        </select>
        <input type="date" class="input w-auto" placeholder="Start Date" />
        <input type="date" class="input w-auto" placeholder="End Date" />
      </div>
    </div>

    <!-- Logs List -->
    <div class="card">
      <p class="text-gray-500">No log entries yet.</p>
    </div>
  </div>
</template>

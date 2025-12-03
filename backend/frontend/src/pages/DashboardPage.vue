<script setup lang="ts">
// Dashboard page - shows overview and quick actions
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-900">Dashboard</h1>
      <router-link to="/log" class="btn-primary">
        + Quick Log
      </router-link>
    </div>

    <!-- Today's Summary -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Today's Activity</h2>
      <p class="text-gray-500">No logs recorded today. Start logging!</p>
    </div>

    <!-- Week Progress -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">This Week</h2>
      <p class="text-gray-500">Add students to see progress.</p>
    </div>

    <!-- Year Progress -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Year Progress</h2>
      <div class="space-y-4">
        <div>
          <div class="flex justify-between text-sm mb-1">
            <span>Total Hours</span>
            <span>0 / 1,000</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2.5">
            <div class="bg-primary-600 h-2.5 rounded-full" style="width: 0%"></div>
          </div>
        </div>
        <div>
          <div class="flex justify-between text-sm mb-1">
            <span>Core Hours</span>
            <span>0 / 600</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2.5">
            <div class="bg-green-600 h-2.5 rounded-full" style="width: 0%"></div>
          </div>
        </div>
        <div>
          <div class="flex justify-between text-sm mb-1">
            <span>At Home</span>
            <span>0 / 400</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2.5">
            <div class="bg-blue-600 h-2.5 rounded-full" style="width: 0%"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Logs -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Recent Logs</h2>
      <p class="text-gray-500">No recent activity.</p>
    </div>
  </div>
</template>

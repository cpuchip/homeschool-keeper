<script setup lang="ts">
// Settings page
</script>

<template>
  <div class="space-y-6 max-w-2xl">
    <h1 class="text-2xl font-bold text-gray-900">Settings</h1>

    <!-- Organization Settings -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Organization Settings</h2>
      
      <div class="space-y-4">
        <div>
          <label class="label">Hour Increment</label>
          <div class="mt-2 flex space-x-4">
            <label class="flex items-center">
              <input type="radio" name="increment" value="0.25" class="h-4 w-4 text-primary-600" checked />
              <span class="ml-2 text-sm">15 min (0.25)</span>
            </label>
            <label class="flex items-center">
              <input type="radio" name="increment" value="0.5" class="h-4 w-4 text-primary-600" />
              <span class="ml-2 text-sm">30 min (0.5)</span>
            </label>
            <label class="flex items-center">
              <input type="radio" name="increment" value="1" class="h-4 w-4 text-primary-600" />
              <span class="ml-2 text-sm">1 hour (1.0)</span>
            </label>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="label">School Year Start</label>
            <input type="date" class="mt-1 input" />
          </div>
          <div>
            <label class="label">School Year End</label>
            <input type="date" class="mt-1 input" />
          </div>
        </div>

        <div>
          <label class="label">Timezone</label>
          <select class="mt-1 input">
            <option value="America/Chicago">Central Time (Chicago)</option>
            <option value="America/New_York">Eastern Time (New York)</option>
            <option value="America/Denver">Mountain Time (Denver)</option>
            <option value="America/Los_Angeles">Pacific Time (Los Angeles)</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Account Settings -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Account Settings</h2>
      
      <div class="space-y-4">
        <div>
          <label class="label">Name</label>
          <input type="text" class="mt-1 input" placeholder="Your name" />
        </div>
        <div>
          <label class="label">Email</label>
          <input type="email" class="mt-1 input" placeholder="your@email.com" />
        </div>
        <div>
          <button class="btn-secondary">Change Password</button>
        </div>
      </div>
    </div>

    <!-- Save Button -->
    <div class="flex justify-end">
      <button class="btn-primary">Save Changes</button>
    </div>
  </div>
</template>

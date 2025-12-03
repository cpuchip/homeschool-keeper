<script setup lang="ts">
// Subjects management page
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-900">Subjects</h1>
      <button class="btn-primary">+ Add Subject</button>
    </div>

    <!-- Core Subjects -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Core Subjects</h2>
      <div class="space-y-2">
        <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
          <div class="flex items-center">
            <div class="w-3 h-3 rounded-full bg-reading mr-3"></div>
            <span>Reading</span>
          </div>
          <span class="text-sm text-gray-500">0 hours</span>
        </div>
        <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
          <div class="flex items-center">
            <div class="w-3 h-3 rounded-full bg-math mr-3"></div>
            <span>Math</span>
          </div>
          <span class="text-sm text-gray-500">0 hours</span>
        </div>
        <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
          <div class="flex items-center">
            <div class="w-3 h-3 rounded-full bg-science mr-3"></div>
            <span>Science</span>
          </div>
          <span class="text-sm text-gray-500">0 hours</span>
        </div>
        <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
          <div class="flex items-center">
            <div class="w-3 h-3 rounded-full bg-social-studies mr-3"></div>
            <span>Social Studies</span>
          </div>
          <span class="text-sm text-gray-500">0 hours</span>
        </div>
        <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
          <div class="flex items-center">
            <div class="w-3 h-3 rounded-full bg-language-arts mr-3"></div>
            <span>Language Arts</span>
          </div>
          <span class="text-sm text-gray-500">0 hours</span>
        </div>
      </div>
    </div>

    <!-- Electives -->
    <div class="card">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Electives</h2>
      <p class="text-gray-500">No electives added yet.</p>
    </div>
  </div>
</template>

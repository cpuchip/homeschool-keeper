import { beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'

// Create a fresh pinia before each test
beforeEach(() => {
  setActivePinia(createPinia())
})

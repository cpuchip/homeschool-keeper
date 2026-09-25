import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Location } from '@/types'
import { locationsApi, type CreateLocationRequest, type UpdateLocationRequest } from '@/api/locations'

export const useLocationsStore = defineStore('locations', () => {
  // State
  const locations = ref<Location[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const locationById = computed(() => (id: string) => locations.value.find(l => l.id === id))
  const locationsByType = computed(() => (type: string) => locations.value.filter(l => l.type === type))
  const fieldTripLocations = computed(() => locations.value.filter(l => l.type === 'field_trip'))
  const coOpLocations = computed(() => locations.value.filter(l => l.type === 'co_op'))
  const otherLocations = computed(() => locations.value.filter(l => l.type === 'other'))

  // Actions
  async function fetchLocations() {
    loading.value = true
    error.value = null
    try {
      locations.value = await locationsApi.list()
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to load locations'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function createLocation(data: CreateLocationRequest) {
    loading.value = true
    error.value = null
    try {
      const location = await locationsApi.create(data)
      locations.value.push(location)
      return location
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to create location'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function updateLocation(id: string, data: UpdateLocationRequest) {
    loading.value = true
    error.value = null
    try {
      const updated = await locationsApi.update(id, data)
      const index = locations.value.findIndex(l => l.id === id)
      if (index !== -1) {
        locations.value[index] = updated
      }
      return updated
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to update location'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function deleteLocation(id: string) {
    loading.value = true
    error.value = null
    try {
      await locationsApi.delete(id)
      locations.value = locations.value.filter(l => l.id !== id)
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to delete location'
      throw e
    } finally {
      loading.value = false
    }
  }

  function clearError() {
    error.value = null
  }

  return {
    // State
    locations,
    loading,
    error,
    // Getters
    locationById,
    locationsByType,
    fieldTripLocations,
    coOpLocations,
    otherLocations,
    // Actions
    fetchLocations,
    createLocation,
    updateLocation,
    deleteLocation,
    clearError,
  }
})

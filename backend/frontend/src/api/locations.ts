import api from './client'
import type { Location } from '@/types'

export interface CreateLocationRequest {
  type: string // field_trip, co_op, other
  name: string
  address?: string
}

export interface UpdateLocationRequest {
  type?: string
  name?: string
  address?: string
}

export interface LocationsResponse {
  locations: Location[]
}

export const locationsApi = {
  /**
   * Get all locations for the current family
   */
  async list(): Promise<Location[]> {
    const response = await api.get<LocationsResponse>('/v1/locations')
    return response.data.locations
  },

  /**
   * Get a single location by ID
   */
  async get(id: string): Promise<Location> {
    const response = await api.get<Location>(`/v1/locations/${id}`)
    return response.data
  },

  /**
   * Create a new location
   */
  async create(data: CreateLocationRequest): Promise<Location> {
    const response = await api.post<Location>('/v1/locations', data)
    return response.data
  },

  /**
   * Update a location
   */
  async update(id: string, data: UpdateLocationRequest): Promise<Location> {
    const response = await api.patch<Location>(`/v1/locations/${id}`, data)
    return response.data
  },

  /**
   * Delete a location (soft delete)
   */
  async delete(id: string): Promise<void> {
    await api.delete(`/v1/locations/${id}`)
  }
}

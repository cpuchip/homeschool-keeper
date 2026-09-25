import api from './client'
import type { WorkSample, StorageUsage, UploadURLResponse } from '@/types'

export interface GetUploadURLRequest {
  logEntryId: string
  fileName: string
  contentType: string
  sizeBytes: number
  description?: string
}

export const uploadsApi = {
  /**
   * Get a pre-signed URL for uploading a file
   */
  async getUploadURL(data: GetUploadURLRequest): Promise<UploadURLResponse> {
    const response = await api.post('/v1/uploads/url', data)
    return response.data
  },

  /**
   * Confirm a file was uploaded successfully
   */
  async confirmUpload(workSampleId: string): Promise<WorkSample> {
    const response = await api.post('/v1/uploads/confirm', { workSampleId })
    return response.data
  },

  /**
   * Get current storage usage for the family
   */
  async getStorageUsage(): Promise<StorageUsage> {
    const response = await api.get('/v1/uploads/usage')
    return response.data
  },

  /**
   * Get work samples for a log entry
   */
  async getByLogEntry(logEntryId: string): Promise<WorkSample[]> {
    const response = await api.get(`/v1/logs/${logEntryId}/work-samples`)
    return response.data
  },

  /**
   * Delete a work sample
   */
  async delete(workSampleId: string): Promise<void> {
    await api.delete(`/v1/work-samples/${workSampleId}`)
  },

  /**
   * Upload a file to R2 using pre-signed URL
   * This is called from the client directly to R2
   */
  async uploadToR2(uploadUrl: string, file: File): Promise<void> {
    const response = await fetch(uploadUrl, {
      method: 'PUT',
      body: file,
      headers: {
        'Content-Type': file.type,
        'Content-Length': file.size.toString(),
      },
    })
    if (!response.ok) {
      throw new Error(`Upload failed: ${response.statusText}`)
    }
  },

  /**
   * Full upload flow: get URL, upload, confirm
   */
  async uploadFile(
    logEntryId: string,
    file: File,
    description?: string,
    onProgress?: (percent: number) => void
  ): Promise<WorkSample> {
    // Step 1: Get pre-signed upload URL
    const urlResponse = await this.getUploadURL({
      logEntryId,
      fileName: file.name,
      contentType: file.type,
      sizeBytes: file.size,
      description,
    })

    // Step 2: Upload to R2
    // Using XMLHttpRequest for progress tracking
    await new Promise<void>((resolve, reject) => {
      const xhr = new XMLHttpRequest()
      xhr.open('PUT', urlResponse.uploadUrl)
      xhr.setRequestHeader('Content-Type', file.type)
      
      xhr.upload.onprogress = (event) => {
        if (event.lengthComputable && onProgress) {
          const percent = Math.round((event.loaded / event.total) * 100)
          onProgress(percent)
        }
      }

      xhr.onload = () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          resolve()
        } else {
          reject(new Error(`Upload failed: ${xhr.statusText}`))
        }
      }

      xhr.onerror = () => reject(new Error('Upload failed'))
      xhr.send(file)
    })

    // Step 3: Confirm upload
    return this.confirmUpload(urlResponse.workSampleId)
  }
}

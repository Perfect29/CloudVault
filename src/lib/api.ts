// API configuration and utilities
import { mockApiClient } from './mockApi'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api'

// Check if we should use mock API (when backend is not available)
let USE_MOCK_API = (import.meta.env.VITE_USE_MOCK_API === 'true')

// Test backend availability
const testBackendAvailability = async (): Promise<boolean> => {
  try {
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 3000) // 3 second timeout
    
    const response = await fetch(`${API_BASE_URL}/health`, {
      method: 'GET',
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
      },
    })
    
    clearTimeout(timeoutId)
    return response.ok
  } catch (error) {
    return false
  }
}

// Initialize backend availability check (only when not forced)
if (!USE_MOCK_API) {
  testBackendAvailability().then(isAvailable => {
    USE_MOCK_API = !isAvailable
  })
}

export interface ApiResponse<T> {
  data?: T
  error?: string
  message?: string
}

export interface User {
  id: string
  username: string
  email: string
  createdAt: string
  updatedAt: string
}

export interface FileMetadata {
  id: string
  userId: string
  filename: string
  originalFilename: string
  fileSize: number
  contentType: string
  filePath: string
  publicUrl?: string
  publicLinkId?: string
  publicLinkExpiresAt?: string
  isPublic: boolean
  createdAt: string
  updatedAt: string
}

export interface LoginRequest {
  email: string
  password: string
}

export interface SignupRequest {
  username: string
  email: string
  password: string
}

export interface AuthResponse {
  token: string
  user: User
}

class ApiClient {
  private baseUrl: string
  private token: string | null = null

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl
    this.token = localStorage.getItem('auth_token')
  }

  setToken(token: string | null) {
    this.token = token
    if (token) {
      localStorage.setItem('auth_token', token)
    } else {
      localStorage.removeItem('auth_token')
    }
    
    // Sync with mock API client
    mockApiClient.setToken(token)
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const url = `${this.baseUrl}${endpoint}`
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...options.headers,
    }

    if (this.token) {
      headers.Authorization = `Bearer ${this.token}`
    }

    try {
      const response = await fetch(url, {
        ...options,
        headers,
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.message || `HTTP ${response.status}`)
      }

      const data = await response.json()
      return { data }
    } catch (error) {
      console.error('API request failed:', error)
      return { error: error instanceof Error ? error.message : 'Unknown error' }
    }
  }

  // Auth endpoints
  async login(credentials: LoginRequest): Promise<ApiResponse<AuthResponse>> {
    if (USE_MOCK_API) {
      return mockApiClient.login(credentials)
    }
    return this.request<AuthResponse>('/auth/signin', {
      method: 'POST',
      body: JSON.stringify(credentials),
    })
  }

  async signup(userData: SignupRequest): Promise<ApiResponse<AuthResponse>> {
    if (USE_MOCK_API) {
      return mockApiClient.signup(userData)
    }
    return this.request<AuthResponse>('/auth/signup', {
      method: 'POST',
      body: JSON.stringify(userData),
    })
  }

  async getCurrentUser(): Promise<ApiResponse<User>> {
    if (USE_MOCK_API) {
      return mockApiClient.getCurrentUser()
    }
    return this.request<User>('/auth/me')
  }

  // File endpoints
  async uploadFile(file: File): Promise<ApiResponse<FileMetadata>> {
    if (USE_MOCK_API) {
      return mockApiClient.uploadFile(file)
    }

    const formData = new FormData()
    formData.append('file', file)

    const headers: HeadersInit = {}
    if (this.token) {
      headers.Authorization = `Bearer ${this.token}`
    }

    try {
      const response = await fetch(`${this.baseUrl}/files/upload`, {
        method: 'POST',
        headers,
        body: formData,
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.message || `HTTP ${response.status}`)
      }

      const data = await response.json()
      return { data }
    } catch (error) {
      console.error('File upload failed:', error)
      return { error: error instanceof Error ? error.message : 'Upload failed' }
    }
  }

  async getFiles(): Promise<ApiResponse<FileMetadata[]>> {
    if (USE_MOCK_API) {
      return mockApiClient.getFiles()
    }
    const res = await this.request<any>('/files')
    if (res.data) {
      const payload = res.data
      const files: FileMetadata[] = Array.isArray(payload)
        ? payload
        : Array.isArray(payload.files)
          ? payload.files
          : []
      return { data: files }
    }
    return { error: res.error || 'Failed to fetch files' }
  }

  async getFile(id: string): Promise<ApiResponse<FileMetadata>> {
    if (USE_MOCK_API) {
      return mockApiClient.getFile(id)
    }
    return this.request<FileMetadata>(`/files/${id}`)
  }

  async deleteFile(id: string): Promise<ApiResponse<void>> {
    if (USE_MOCK_API) {
      return mockApiClient.deleteFile(id)
    }
    return this.request<void>(`/files/${id}`, {
      method: 'DELETE',
    })
  }

  async createShareLink(fileId: string): Promise<ApiResponse<{ shareUrl: string }>> {
    if (USE_MOCK_API) {
      return mockApiClient.createShareLink(fileId)
    }
    return this.request<{ shareUrl: string }>(`/files/${fileId}/share`, {
      method: 'POST',
    })
  }

  getDownloadUrl(fileId: string): string {
    if (USE_MOCK_API) {
      return mockApiClient.getDownloadUrl(fileId)
    }
    return `${this.baseUrl}/files/${fileId}/download`
  }

  getSharedFileUrl(token: string): string {
    if (USE_MOCK_API) {
      return mockApiClient.getSharedFileUrl(token)
    }
    return `${this.baseUrl}/share/${token}`
  }
}

export const apiClient = new ApiClient(API_BASE_URL)
export default apiClient
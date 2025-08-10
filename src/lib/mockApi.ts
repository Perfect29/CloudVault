// API service implementation
import { ApiResponse, User, FileMetadata, LoginRequest, SignupRequest, AuthResponse } from './api'

// Data storage using localStorage
const STORAGE_KEYS = {
  USERS: 'cloudvault_users',
  FILES: 'cloudvault_files',
  CURRENT_USER: 'cloudvault_current_user',
  AUTH_TOKEN: 'auth_token'
}

// Helper functions for localStorage
const getStorageData = <T>(key: string, defaultValue: T): T => {
  try {
    const data = localStorage.getItem(key)
    return data ? JSON.parse(data) : defaultValue
  } catch {
    return defaultValue
  }
}

const setStorageData = <T>(key: string, data: T): void => {
  localStorage.setItem(key, JSON.stringify(data))
}

// Generate mock IDs
const generateId = () => Math.random().toString(36).substr(2, 9)

// Generate JWT-like token
const generateToken = (userId: string) => {
  const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
  const payload = btoa(JSON.stringify({ sub: userId, exp: Date.now() + 86400000 }))
  const signature = btoa(`signature_${userId}`)
  return `${header}.${payload}.${signature}`
}

// Network delay simulation
const delay = (ms: number = 500) => new Promise(resolve => setTimeout(resolve, ms))



class ApiClientImpl {
  private token: string | null = null

  constructor() {
    this.token = localStorage.getItem(STORAGE_KEYS.AUTH_TOKEN)
    // Ensure default data is initialized when the client is created
    this.ensureDefaultData()
  }

  private ensureDefaultData() {
    const users = getStorageData(STORAGE_KEYS.USERS, [])
    
    // Initialize default users if none exist
    if (users.length === 0) {
      const defaultUsers: User[] = [
        {
          id: 'usr_001',
          username: 'demo',
          email: 'demo@cloudvault.com',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        },
        {
          id: 'usr_002',
          username: 'testuser',
          email: 'test@example.com',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
      ]
      
      setStorageData(STORAGE_KEYS.USERS, defaultUsers)
    }
  }

  setToken(token: string | null) {
    this.token = token
    if (token) {
      localStorage.setItem(STORAGE_KEYS.AUTH_TOKEN, token)
    } else {
      localStorage.removeItem(STORAGE_KEYS.AUTH_TOKEN)
      localStorage.removeItem(STORAGE_KEYS.CURRENT_USER)
    }
  }

  private isAuthenticated(): boolean {
    return !!this.token
  }

  private getCurrentUserId(): string | null {
    if (!this.token) return null
    try {
      const payload = JSON.parse(atob(this.token.split('.')[1]))
      return payload.sub
    } catch {
      return null
    }
  }

  // Auth endpoints
  async login(credentials: LoginRequest): Promise<ApiResponse<AuthResponse>> {
    await delay(800)

    // Ensure default data exists before login attempt
    this.ensureDefaultData()
    
    const users: User[] = getStorageData(STORAGE_KEYS.USERS, [])
    const user = users.find(u => u.email === credentials.email)

    if (!user) {
      return { error: 'User not found' }
    }
    
    // In a real app, you'd hash and compare passwords
    // Accept any password for existing users
    const token = generateToken(user.id)
    this.setToken(token)
    setStorageData(STORAGE_KEYS.CURRENT_USER, user)

    return {
      data: {
        token,
        user
      }
    }
  }

  async signup(userData: SignupRequest): Promise<ApiResponse<AuthResponse>> {
    await delay(1000)

    const users: User[] = getStorageData(STORAGE_KEYS.USERS, [])
    
    // Check if user already exists
    if (users.find(u => u.email === userData.email)) {
      return { error: 'User with this email already exists' }
    }

    if (users.find(u => u.username === userData.username)) {
      return { error: 'Username already taken' }
    }

    // Create new user
    const newUser: User = {
      id: generateId(),
      username: userData.username,
      email: userData.email,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }

    users.push(newUser)
    setStorageData(STORAGE_KEYS.USERS, users)

    const token = generateToken(newUser.id)
    this.setToken(token)
    setStorageData(STORAGE_KEYS.CURRENT_USER, newUser)

    return {
      data: {
        token,
        user: newUser
      }
    }
  }

  async getCurrentUser(): Promise<ApiResponse<User>> {
    await delay(300)

    if (!this.isAuthenticated()) {
      return { error: 'Not authenticated' }
    }

    const user: User | null = getStorageData(STORAGE_KEYS.CURRENT_USER, null)
    if (!user) {
      return { error: 'User not found' }
    }

    return { data: user }
  }

  // File endpoints
  async uploadFile(file: File): Promise<ApiResponse<FileMetadata>> {
    await delay(1500)

    if (!this.isAuthenticated()) {
      return { error: 'Not authenticated' }
    }

    const userId = this.getCurrentUserId()
    if (!userId) {
      return { error: 'Invalid user' }
    }

    // Create file metadata
    const fileMetadata: FileMetadata = {
      id: generateId(),
      userId,
      filename: `${generateId()}_${file.name}`,
      originalFilename: file.name,
      fileSize: file.size,
      contentType: file.type,
      filePath: `/uploads/${userId}/${generateId()}_${file.name}`,
      isPublic: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }

    // Store file metadata
    const files: FileMetadata[] = getStorageData(STORAGE_KEYS.FILES, [])
    files.push(fileMetadata)
    setStorageData(STORAGE_KEYS.FILES, files)

    // In a real app, you'd upload the file to storage
    // Store file reference
    const fileKey = `file_${fileMetadata.id}`
    try {
      // Convert file to base64 for storage (only for small files)
      if (file.size < 5 * 1024 * 1024) { // 5MB limit
        const reader = new FileReader()
        reader.onload = () => {
          localStorage.setItem(fileKey, reader.result as string)
        }
        reader.readAsDataURL(file)
      }
    } catch (error) {
      console.warn('Could not store file content:', error)
    }

    return { data: fileMetadata }
  }

  async getFiles(): Promise<ApiResponse<FileMetadata[]>> {
    await delay(400)

    if (!this.isAuthenticated()) {
      return { error: 'Not authenticated' }
    }

    const userId = this.getCurrentUserId()
    if (!userId) {
      return { error: 'Invalid user' }
    }

    const allFiles: FileMetadata[] = getStorageData(STORAGE_KEYS.FILES, [])
    const userFiles = allFiles.filter(file => file.userId === userId)

    return { data: userFiles }
  }

  async getFile(id: string): Promise<ApiResponse<FileMetadata>> {
    await delay(300)

    if (!this.isAuthenticated()) {
      return { error: 'Not authenticated' }
    }

    const userId = this.getCurrentUserId()
    if (!userId) {
      return { error: 'Invalid user' }
    }

    const allFiles: FileMetadata[] = getStorageData(STORAGE_KEYS.FILES, [])
    const file = allFiles.find(f => f.id === id && f.userId === userId)

    if (!file) {
      return { error: 'File not found' }
    }

    return { data: file }
  }

  async deleteFile(id: string): Promise<ApiResponse<void>> {
    await delay(500)

    if (!this.isAuthenticated()) {
      return { error: 'Not authenticated' }
    }

    const userId = this.getCurrentUserId()
    if (!userId) {
      return { error: 'Invalid user' }
    }

    const allFiles: FileMetadata[] = getStorageData(STORAGE_KEYS.FILES, [])
    const fileIndex = allFiles.findIndex(f => f.id === id && f.userId === userId)

    if (fileIndex === -1) {
      return { error: 'File not found' }
    }

    // Remove file metadata
    allFiles.splice(fileIndex, 1)
    setStorageData(STORAGE_KEYS.FILES, allFiles)

    // Remove file content
    localStorage.removeItem(`file_${id}`)

    return { data: undefined }
  }

  async createShareLink(fileId: string): Promise<ApiResponse<{ shareUrl: string }>> {
    await delay(600)

    if (!this.isAuthenticated()) {
      return { error: 'Not authenticated' }
    }

    const userId = this.getCurrentUserId()
    if (!userId) {
      return { error: 'Invalid user' }
    }

    const allFiles: FileMetadata[] = getStorageData(STORAGE_KEYS.FILES, [])
    const fileIndex = allFiles.findIndex(f => f.id === fileId && f.userId === userId)

    if (fileIndex === -1) {
      return { error: 'File not found' }
    }

    // Update file with public link
    const publicLinkId = generateId()
    allFiles[fileIndex] = {
      ...allFiles[fileIndex],
      isPublic: true,
      publicLinkId,
      publicUrl: `${window.location.origin}/share/${publicLinkId}`,
      updatedAt: new Date().toISOString()
    }

    setStorageData(STORAGE_KEYS.FILES, allFiles)

    return {
      data: {
        shareUrl: `${window.location.origin}/share/${publicLinkId}`
      }
    }
  }

  getDownloadUrl(fileId: string): string {
    // Return a data URL if file content is stored
    const fileContent = localStorage.getItem(`file_${fileId}`)
    if (fileContent) {
      return fileContent
    }
    return `#download-${fileId}` // Placeholder
  }

  getSharedFileUrl(token: string): string {
    return `${window.location.origin}/share/${token}`
  }
}

export const mockApiClient = new ApiClientImpl()
export default mockApiClient
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

export interface AuthState {
  user: User | null
  isLoading: boolean
  isAuthenticated: boolean
}

export interface FileUploadProgress {
  id: string
  filename: string
  progress: number
  status: 'uploading' | 'completed' | 'error'
}
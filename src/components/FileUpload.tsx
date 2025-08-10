import { useState, useRef, useCallback } from 'react'
import { Button } from './ui/button'
import { Card, CardContent } from './ui/card'
import { Progress } from './ui/progress'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from './ui/dialog'
import { Upload, X, File, CheckCircle, AlertCircle } from 'lucide-react'
import { useAuth } from '../hooks/useAuth'
import { apiClient } from '../lib/api'
import toast from 'react-hot-toast'
import type { FileUploadProgress } from '../types'

interface FileUploadProps {
  onClose: () => void
  onUploadComplete: () => void
}

export default function FileUpload({ onClose, onUploadComplete }: FileUploadProps) {
  const { user } = useAuth()
  const [isDragOver, setIsDragOver] = useState(false)
  const [uploadProgress, setUploadProgress] = useState<FileUploadProgress[]>([])
  const [isUploading, setIsUploading] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(true)
  }, [])

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(false)
  }, [])

  const processFileUpload = useCallback(async (file: File, progressItem: FileUploadProgress) => {
    if (!user) throw new Error('User not authenticated')

    // Upload file using API client
    const response = await apiClient.uploadFile(file)
    
    if (response.error) {
      throw new Error(response.error)
    }

    return response.data?.id
  }, [user])

  const handleFiles = useCallback(async (files: File[]) => {
    if (!user) {
      toast.error('Please log in to upload files')
      return
    }

    if (files.length === 0) return

    setIsUploading(true)
    const progressItems: FileUploadProgress[] = files.map(file => ({
      id: Math.random().toString(36).substr(2, 9),
      filename: file.name,
      progress: 0,
      status: 'uploading'
    }))
    
    setUploadProgress(progressItems)

    let successCount = 0
    let errorCount = 0

    for (let i = 0; i < files.length; i++) {
      const file = files[i]
      const progressItem = progressItems[i]

      try {
        // Update progress for better UX
        setUploadProgress(prev => 
          prev.map(item => 
            item.id === progressItem.id 
              ? { ...item, progress: 50 }
              : item
          )
        )

        await processFileUpload(file, progressItem)
        
        setUploadProgress(prev => 
          prev.map(item => 
            item.id === progressItem.id 
              ? { ...item, progress: 100, status: 'completed' }
              : item
          )
        )
        
        successCount++
      } catch (error) {
        console.error(`Upload failed for ${file.name}:`, error)
        
        setUploadProgress(prev => 
          prev.map(item => 
            item.id === progressItem.id 
              ? { ...item, status: 'error' }
              : item
          )
        )
        
        errorCount++
        toast.error(`Failed to upload ${file.name}`)
      }
    }

    setIsUploading(false)

    if (successCount > 0) {
      toast.success(`Successfully uploaded ${successCount} file${successCount > 1 ? 's' : ''}`)
      onUploadComplete()
    }

    if (errorCount === 0) {
      setTimeout(() => onClose(), 1500)
    }
  }, [user, onUploadComplete, onClose, processFileUpload])

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(false)
    const files = Array.from(e.dataTransfer.files)
    handleFiles(files)
  }, [handleFiles])

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    handleFiles(files)
  }

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="h-5 w-5 text-green-500" />
      case 'error':
        return <AlertCircle className="h-5 w-5 text-red-500" />
      default:
        return <File className="h-5 w-5 text-muted-foreground" />
    }
  }

  const getStatusText = (item: FileUploadProgress) => {
    switch (item.status) {
      case 'completed':
        return 'Upload completed'
      case 'error':
        return 'Upload failed'
      case 'uploading':
        return `${item.progress}% uploaded`
      default:
        return 'Preparing...'
    }
  }

  return (
    <Dialog open onOpenChange={onClose}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle className="flex items-center space-x-2">
            <Upload className="h-5 w-5" />
            <span>Upload Files</span>
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-6">
          <Card
            className={`border-2 border-dashed transition-colors cursor-pointer ${
              isDragOver 
                ? 'border-primary bg-primary/5' 
                : 'border-muted-foreground/25 hover:border-primary/50'
            }`}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
            onClick={() => fileInputRef.current?.click()}
          >
            <CardContent className="flex flex-col items-center justify-center py-12">
              <Upload className={`h-12 w-12 mb-4 ${isDragOver ? 'text-primary' : 'text-muted-foreground'}`} />
              <h3 className="text-lg font-semibold mb-2">
                {isDragOver ? 'Drop files here' : 'Select files to upload'}
              </h3>
              <p className="text-muted-foreground mb-4">
                Drag and drop files or click to browse
              </p>
              <Button variant="outline" disabled={isUploading}>
                Browse Files
              </Button>
            </CardContent>
          </Card>

          <input
            ref={fileInputRef}
            type="file"
            multiple
            className="hidden"
            onChange={handleFileSelect}
            disabled={isUploading}
          />

          {uploadProgress.length > 0 && (
            <div className="space-y-4">
              <h4 className="font-semibold">Upload Progress</h4>
              <div className="space-y-3 max-h-60 overflow-y-auto">
                {uploadProgress.map((item) => (
                  <Card key={item.id}>
                    <CardContent className="p-4">
                      <div className="flex items-center space-x-3">
                        <div className="flex-shrink-0">
                          {getStatusIcon(item.status)}
                        </div>
                        
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium truncate">
                            {item.filename}
                          </p>
                          
                          {item.status === 'uploading' && (
                            <div className="mt-2">
                              <Progress value={item.progress} className="h-2" />
                            </div>
                          )}
                          
                          <p className={`text-xs mt-1 ${
                            item.status === 'completed' ? 'text-green-600' :
                            item.status === 'error' ? 'text-red-600' :
                            'text-muted-foreground'
                          }`}>
                            {getStatusText(item)}
                          </p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </div>
          )}

          <div className="flex justify-end space-x-2">
            <Button variant="outline" onClick={onClose} disabled={isUploading}>
              {isUploading ? 'Uploading...' : 'Close'}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
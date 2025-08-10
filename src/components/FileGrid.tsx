import { useState } from 'react'
import { Card, CardContent } from './ui/card'
import { Button } from './ui/button'
import { Badge } from './ui/badge'
import { 
  MoreVertical, 
  Download, 
  Share2, 
  Trash2, 
  File, 
  Image, 
  FileText, 
  Music, 
  Video,
  Archive
} from 'lucide-react'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from './ui/dropdown-menu'
import { apiClient } from '../lib/api'
import toast from 'react-hot-toast'
import type { FileMetadata } from '../types'

interface FileGridProps {
  files: FileMetadata[]
  onFileUpdate: () => void
}

export default function FileGrid({ files, onFileUpdate }: FileGridProps) {
  const [loadingActions, setLoadingActions] = useState<string[]>([])

  const getFileIcon = (contentType: string) => {
    if (contentType.startsWith('image/')) return Image
    if (contentType.startsWith('video/')) return Video
    if (contentType.startsWith('audio/')) return Music
    if (contentType.includes('text') || contentType.includes('document')) return FileText
    if (contentType.includes('zip') || contentType.includes('archive')) return Archive
    return File
  }

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
  }

  const handleDownload = async (file: FileMetadata) => {
    if (loadingActions.includes(file.id)) return
    
    setLoadingActions(prev => [...prev, file.id])
    try {
      // Use the API download endpoint
      const downloadUrl = apiClient.getDownloadUrl(file.id)
      
      // Create a temporary link to download the file
      const link = document.createElement('a')
      link.href = downloadUrl
      link.download = file.originalFilename
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      
      toast.success('File downloaded successfully')
    } catch (error) {
      console.error('Download failed:', error)
      toast.error('Failed to download file')
    } finally {
      setLoadingActions(prev => prev.filter(id => id !== file.id))
    }
  }

  const handleShare = async (file: FileMetadata) => {
    if (loadingActions.includes(file.id)) return
    
    setLoadingActions(prev => [...prev, file.id])
    try {
      const response = await apiClient.createShareLink(file.id)
      if (response.error) {
        throw new Error(response.error)
      }
      
      const shareUrl = response.data?.shareUrl || `${window.location.origin}/share/${file.id}`
      
      // Try to copy to clipboard with fallback
      let copySuccess = false
      try {
        if (navigator.clipboard && window.isSecureContext) {
          await navigator.clipboard.writeText(shareUrl)
          copySuccess = true
          toast.success('Share link copied to clipboard!')
        } else {
          // Fallback for non-secure contexts
          copyToClipboardFallback(shareUrl)
          // Don't show success toast here - let fallback handle user feedback
        }
      } catch (clipboardError) {
        console.warn('Clipboard access failed, using fallback:', clipboardError)
        copyToClipboardFallback(shareUrl)
        // Don't show success toast here - let fallback handle user feedback
      }
      
      // If modern clipboard API worked, we already showed success
      // If fallback was used, it handles its own user feedback
      
      onFileUpdate()
    } catch (error) {
      console.error('Share failed:', error)
      toast.error('Failed to create share link')
    } finally {
      setLoadingActions(prev => prev.filter(id => id !== file.id))
    }
  }

  const copyToClipboardFallback = (text: string) => {
    // Create a temporary textarea element
    const textArea = document.createElement('textarea')
    textArea.value = text
    textArea.style.position = 'fixed'
    textArea.style.left = '-999999px'
    textArea.style.top = '-999999px'
    textArea.style.opacity = '0'
    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()
    
    let copySuccessful = false
    
    try {
      // Try the execCommand approach
      copySuccessful = document.execCommand('copy')
    } catch (err) {
      console.warn('execCommand copy failed:', err)
      copySuccessful = false
    }
    
    // Clean up the textarea
    document.body.removeChild(textArea)
    
    // If copy failed, show manual copy option
    if (!copySuccessful) {
      console.warn('All clipboard methods failed, showing manual copy option')
      const userAction = confirm(`Unable to copy automatically. Would you like to see the share link to copy manually?`)
      if (userAction) {
        // Show the URL in a prompt for manual copying
        prompt('Please copy this share link manually:', text)
        toast.success('Share link created! Please copy it from the dialog.')
      } else {
        toast.error('Share link created but not copied to clipboard')
      }
    } else {
      // Fallback copy was successful
      toast.success('Share link copied to clipboard!')
    }
  }

  const handleDelete = async (file: FileMetadata) => {
    if (loadingActions.includes(file.id)) return
    
    if (!confirm(`Are you sure you want to delete "${file.originalFilename}"?`)) {
      return
    }
    
    setLoadingActions(prev => [...prev, file.id])
    try {
      const response = await apiClient.deleteFile(file.id)
      if (response.error) {
        throw new Error(response.error)
      }
      
      toast.success('File deleted successfully')
      onFileUpdate()
    } catch (error) {
      console.error('Delete failed:', error)
      toast.error('Failed to delete file')
    } finally {
      setLoadingActions(prev => prev.filter(id => id !== file.id))
    }
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {files.map((file) => {
        const FileIcon = getFileIcon(file.contentType)
        const isLoading = loadingActions.includes(file.id)
        
        return (
          <Card key={file.id} className="group hover:shadow-lg transition-shadow">
            <CardContent className="p-4">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center space-x-2">
                  <FileIcon className="h-8 w-8 text-primary" />
                  {Number(file.isPublic) > 0 && (
                    <Badge variant="secondary" className="text-xs">
                      Shared
                    </Badge>
                  )}
                </div>
                
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button 
                      variant="ghost" 
                      size="sm" 
                      className="opacity-0 group-hover:opacity-100 transition-opacity"
                      disabled={isLoading}
                    >
                      <MoreVertical className="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem onClick={() => handleDownload(file)}>
                      <Download className="h-4 w-4 mr-2" />
                      Download
                    </DropdownMenuItem>
                    <DropdownMenuItem onClick={() => handleShare(file)}>
                      <Share2 className="h-4 w-4 mr-2" />
                      Share
                    </DropdownMenuItem>
                    <DropdownMenuItem 
                      onClick={() => handleDelete(file)}
                      className="text-red-600"
                    >
                      <Trash2 className="h-4 w-4 mr-2" />
                      Delete
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
              
              <div className="space-y-2">
                <h3 className="font-medium text-sm truncate" title={file.originalFilename}>
                  {file.originalFilename}
                </h3>
                
                <div className="flex justify-between text-xs text-muted-foreground">
                  <span>{formatBytes(file.fileSize)}</span>
                  <span>{formatDate(file.createdAt)}</span>
                </div>
              </div>
            </CardContent>
          </Card>
        )
      })}
    </div>
  )
}
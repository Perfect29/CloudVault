import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import { Button } from '../ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card'
import { Badge } from '../ui/badge'
import { 
  Cloud, 
  Download, 
  File, 
  Image, 
  FileText, 
  Music, 
  Video,
  Archive,
  AlertCircle,
  Loader2
} from 'lucide-react'
import { apiClient } from '../../lib/api'
import toast from 'react-hot-toast'
import type { FileMetadata } from '../../types'

export default function SharePage() {
  const { token } = useParams<{ token: string }>()
  const [file, setFile] = useState<FileMetadata | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isDownloading, setIsDownloading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (token) {
      loadSharedFile(token)
    }
  }, [token])

  const loadSharedFile = async (shareToken: string) => {
    try {
      setIsLoading(true)
      setError(null)
      
      // Use the shared file URL from API
      const sharedUrl = apiClient.getSharedFileUrl(shareToken)
      const response = await fetch(sharedUrl)
      
      if (!response.ok) {
        if (response.status === 404) {
          setError('File not found or no longer shared')
        } else if (response.status === 410) {
          setError('This share link has expired')
        } else {
          setError('Failed to load file')
        }
        return
      }
      
      const fileData = await response.json()
      setFile(fileData)
    } catch (error) {
      console.error('Failed to load shared file:', error)
      setError('Failed to load file')
    } finally {
      setIsLoading(false)
    }
  }

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
      month: 'long',
      day: 'numeric'
    })
  }

  const handleDownload = async () => {
    if (!file || isDownloading || !token) return
    
    setIsDownloading(true)
    try {
      // Use the shared file download URL
      const downloadUrl = apiClient.getSharedFileUrl(token)
      
      // Create a temporary link to download the file
      const link = document.createElement('a')
      link.href = downloadUrl
      link.download = file.originalFilename
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      
      toast.success('Download started')
    } catch (error) {
      console.error('Download failed:', error)
      toast.error('Failed to download file')
    } finally {
      setIsDownloading(false)
    }
  }

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary/5 to-accent/5">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin text-primary mx-auto mb-4" />
          <p className="text-muted-foreground">Loading shared file...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary/5 to-accent/5 p-4">
        <Card className="w-full max-w-md">
          <CardContent className="p-8 text-center">
            <AlertCircle className="h-16 w-16 text-red-500 mx-auto mb-4" />
            <h2 className="text-xl font-semibold mb-2">File Not Available</h2>
            <p className="text-muted-foreground mb-6">{error}</p>
            <Link to="/">
              <Button>Go to CloudVault</Button>
            </Link>
          </CardContent>
        </Card>
      </div>
    )
  }

  if (!file) {
    return null
  }

  const FileIcon = getFileIcon(file.contentType)

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-accent/5">
      {/* Header */}
      <header className="border-b bg-white/95 backdrop-blur supports-[backdrop-filter]:bg-white/60">
        <div className="container mx-auto px-4 h-16 flex items-center justify-between">
          <Link to="/" className="flex items-center space-x-2">
            <Cloud className="h-8 w-8 text-primary" />
            <span className="text-2xl font-bold text-primary">CloudVault</span>
          </Link>
          
          <Badge variant="secondary">Shared File</Badge>
        </div>
      </header>

      {/* Main Content */}
      <div className="container mx-auto px-4 py-12">
        <div className="max-w-2xl mx-auto">
          <Card className="shadow-xl">
            <CardHeader className="text-center pb-6">
              <div className="flex justify-center mb-4">
                <div className="p-4 bg-primary/10 rounded-full">
                  <FileIcon className="h-16 w-16 text-primary" />
                </div>
              </div>
              <CardTitle className="text-2xl mb-2">{file.originalFilename}</CardTitle>
              <p className="text-muted-foreground">
                Shared via CloudVault
              </p>
            </CardHeader>
            
            <CardContent className="space-y-6">
              {/* File Details */}
              <div className="grid grid-cols-2 gap-4 p-4 bg-muted/30 rounded-lg">
                <div>
                  <p className="text-sm text-muted-foreground">File Size</p>
                  <p className="font-medium">{formatBytes(file.fileSize)}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Uploaded</p>
                  <p className="font-medium">{formatDate(file.createdAt)}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Downloads</p>
                  <p className="font-medium">N/A</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Type</p>
                  <p className="font-medium">{file.contentType.split('/')[1]?.toUpperCase() || 'File'}</p>
                </div>
              </div>

              {/* Expiry Warning */}
              {file.publicLinkExpiresAt && (
                <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                  <div className="flex items-center space-x-2">
                    <AlertCircle className="h-5 w-5 text-yellow-600" />
                    <p className="text-sm text-yellow-800">
                      This link expires on {formatDate(file.publicLinkExpiresAt)}
                    </p>
                  </div>
                </div>
              )}

              {/* Download Button */}
              <div className="text-center">
                <Button 
                  size="lg" 
                  onClick={handleDownload}
                  disabled={isDownloading}
                  className="px-8"
                >
                  {isDownloading ? (
                    <>
                      <Loader2 className="mr-2 h-5 w-5 animate-spin" />
                      Downloading...
                    </>
                  ) : (
                    <>
                      <Download className="mr-2 h-5 w-5" />
                      Download File
                    </>
                  )}
                </Button>
              </div>

              {/* Footer */}
              <div className="text-center pt-6 border-t">
                <p className="text-sm text-muted-foreground mb-2">
                  Powered by CloudVault
                </p>
                <Link to="/">
                  <Button variant="outline" size="sm">
                    Get Your Own CloudVault
                  </Button>
                </Link>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
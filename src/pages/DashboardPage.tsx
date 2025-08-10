import { useState, useEffect, useCallback } from 'react'
import { Button } from '../components/ui/button'
import { Input } from '../components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card'
import { Progress } from '../components/ui/progress'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../components/ui/dialog'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from '../components/ui/dropdown-menu'
import { 
  Cloud, 
  Search, 
  Upload, 
  Grid3X3, 
  List, 
  Settings, 
  LogOut,
  User,
  HardDrive,
  ChevronDown
} from 'lucide-react'
import { useAuth } from '../hooks/useAuth'
import { apiClient } from '../lib/api'
import FileUpload from '../components/FileUpload'
import FileGrid from '../components/FileGrid'
import FileList from '../components/FileList'
import type { FileMetadata } from '../types'

export default function DashboardPage() {
  const { user, logout } = useAuth()
  const [files, setFiles] = useState<FileMetadata[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [isLoading, setIsLoading] = useState(true)
  const [showUpload, setShowUpload] = useState(false)
  const [showSettings, setShowSettings] = useState(false)
  const [showProfile, setShowProfile] = useState(false)

  const loadFiles = useCallback(async () => {
    if (!user?.id) return
    
    try {
      setIsLoading(true)
      const response = await apiClient.getFiles()
      if (response.data) {
        setFiles(response.data)
      } else {
        throw new Error(response.error || 'Failed to fetch files')
      }
    } catch (error) {
      console.error('Failed to load files:', error)
    } finally {
      setIsLoading(false)
    }
  }, [user?.id])

  useEffect(() => {
    loadFiles()
  }, [loadFiles])

  const filteredFiles = Array.isArray(files)
    ? files.filter(file =>
        (file.originalFilename || '').toLowerCase().includes(searchQuery.toLowerCase())
      )
    : []

  const storageUsed = (Array.isArray(files) ? files : []).reduce((total, file) => total + (file.fileSize || 0), 0)
  const storageLimit = 5368709120 // 5GB limit
  const storagePercentage = Math.min((storageUsed / storageLimit) * 100, 100)

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  const handleRefresh = () => {
    loadFiles()
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b bg-white/95 backdrop-blur supports-[backdrop-filter]:bg-white/60">
        <div className="container mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Cloud className="h-8 w-8 text-primary" />
            <span className="text-2xl font-bold text-primary">CloudVault</span>
          </div>
          
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-2 text-sm text-muted-foreground">
              <HardDrive className="h-4 w-4" />
              <span>{formatFileSize(storageUsed)} / {formatFileSize(storageLimit)}</span>
            </div>
            
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="sm" className="flex items-center space-x-2">
                  <User className="h-4 w-4" />
                  <span className="text-sm">{user?.username || user?.email}</span>
                  <ChevronDown className="h-3 w-3" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-56">
                <DropdownMenuItem onClick={() => setShowProfile(true)}>
                  <User className="h-4 w-4 mr-2" />
                  Profile
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => setShowSettings(true)}>
                  <Settings className="h-4 w-4 mr-2" />
                  Settings
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={logout}>
                  <LogOut className="h-4 w-4 mr-2" />
                  Sign Out
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        <Card className="mb-8">
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <HardDrive className="h-5 w-5" />
              <span>Storage Overview</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>{formatFileSize(storageUsed)} used</span>
                <span>{formatFileSize(storageLimit - storageUsed)} available</span>
              </div>
              <Progress value={storagePercentage} className="h-2" />
              <div className="flex justify-between text-xs text-muted-foreground">
                <span>{storagePercentage.toFixed(1)}% used</span>
                <span>{files.length} files total</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <div className="flex flex-col sm:flex-row gap-4 mb-8">
          <div className="flex-1">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search files by name..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10"
              />
            </div>
          </div>
          
          <div className="flex items-center space-x-2">
            <Button
              variant={viewMode === 'grid' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setViewMode('grid')}
            >
              <Grid3X3 className="h-4 w-4" />
            </Button>
            <Button
              variant={viewMode === 'list' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setViewMode('list')}
            >
              <List className="h-4 w-4" />
            </Button>
            
            <Button onClick={() => setShowUpload(true)}>
              <Upload className="h-4 w-4 mr-2" />
              Upload
            </Button>
          </div>
        </div>

        {isLoading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
            <p className="text-muted-foreground">Loading files...</p>
          </div>
        ) : filteredFiles.length === 0 ? (
          <div className="text-center py-12">
            <Cloud className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">
              {searchQuery ? 'No matching files' : 'No files uploaded'}
            </h3>
            <p className="text-muted-foreground mb-4">
              {searchQuery 
                ? 'Try adjusting your search terms.' 
                : 'Upload your first file to get started.'
              }
            </p>
            {!searchQuery && (
              <Button onClick={() => setShowUpload(true)}>
                <Upload className="h-4 w-4 mr-2" />
                Upload Files
              </Button>
            )}
          </div>
        ) : (
          <>
            {viewMode === 'grid' ? (
              <FileGrid files={filteredFiles} onFileUpdate={handleRefresh} />
            ) : (
              <FileList files={filteredFiles} onFileUpdate={handleRefresh} />
            )}
          </>
        )}
      </div>

      {showUpload && (
        <FileUpload
          onClose={() => setShowUpload(false)}
          onUploadComplete={handleRefresh}
        />
      )}

      <Dialog open={showProfile} onOpenChange={setShowProfile}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-2">
              <User className="h-5 w-5" />
              <span>User Profile</span>
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-6">
            <div className="flex items-center space-x-4">
              <div className="h-16 w-16 bg-primary/10 rounded-full flex items-center justify-center">
                <User className="h-8 w-8 text-primary" />
              </div>
              <div>
                <h3 className="font-semibold">{user?.username || 'User'}</h3>
                <p className="text-sm text-muted-foreground">{user?.email}</p>
              </div>
            </div>
            
            <div className="space-y-3">
              <div>
                <label className="text-sm font-medium">Email</label>
                <Input 
                  value={user?.email || ''} 
                  disabled
                  className="mt-1 bg-muted"
                />
              </div>
            </div>
            
            <div className="flex justify-end">
              <Button onClick={() => setShowProfile(false)}>
                Close
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      <Dialog open={showSettings} onOpenChange={setShowSettings}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-2">
              <Settings className="h-5 w-5" />
              <span>Application Settings</span>
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-6">
            <div className="space-y-4">
              <div>
                <label className="text-sm font-medium">Default View</label>
                <div className="flex space-x-2 mt-2">
                  <Button
                    variant={viewMode === 'grid' ? 'default' : 'outline'}
                    size="sm"
                    onClick={() => setViewMode('grid')}
                  >
                    <Grid3X3 className="h-4 w-4 mr-2" />
                    Grid
                  </Button>
                  <Button
                    variant={viewMode === 'list' ? 'default' : 'outline'}
                    size="sm"
                    onClick={() => setViewMode('list')}
                  >
                    <List className="h-4 w-4 mr-2" />
                    List
                  </Button>
                </div>
              </div>
              
              <div className="space-y-2">
                <label className="text-sm font-medium">Storage Statistics</label>
                <div className="p-3 bg-muted rounded-lg space-y-2">
                  <div className="flex justify-between text-sm">
                    <span>Used:</span>
                    <span>{formatFileSize(storageUsed)}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span>Available:</span>
                    <span>{formatFileSize(storageLimit - storageUsed)}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span>Files:</span>
                    <span>{files.length}</span>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="flex justify-end">
              <Button onClick={() => setShowSettings(false)}>
                Close
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
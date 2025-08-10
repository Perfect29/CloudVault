import React from 'react'
import { Link } from 'react-router-dom'
import { Button } from '../components/ui/button'
import { Card, CardContent } from '../components/ui/card'
import { Cloud, Shield, Share2, Zap, Upload, Download, Play } from 'lucide-react'
// Removed demo modal

export default function LandingPage() {

  return (
    <div className="min-h-screen">
      <header className="border-b bg-white/95 backdrop-blur supports-[backdrop-filter]:bg-white/60">
        <div className="container mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Cloud className="h-8 w-8 text-primary" />
            <span className="text-2xl font-bold text-primary">CloudVault</span>
          </div>
          <div className="flex items-center space-x-4">
            <Link to="/auth">
              <Button variant="ghost">Sign In</Button>
            </Link>
            <Link to="/auth">
              <Button>Get Started</Button>
            </Link>
          </div>
        </div>
      </header>

      <section className="py-20 px-4">
        <div className="container mx-auto text-center max-w-4xl">
          <h1 className="text-5xl font-bold mb-6 bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
            Professional File Storage Platform
          </h1>
          <p className="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
            Built with Spring Boot and React. Secure file management with JWT authentication, 
            PostgreSQL database, and AWS S3 integration for enterprise-grade storage solutions.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link to="/auth">
              <Button size="lg" className="text-lg px-8 py-6">
                Try Demo
              </Button>
            </Link>
            <Link to="/auth">
              <Button 
                variant="outline" 
                size="lg" 
                className="text-lg px-8 py-6"
              >
                <Play className="h-5 w-5 mr-2" />
                Learn More
              </Button>
            </Link>
          </div>
        </div>
      </section>

      <section className="py-20 px-4 bg-muted/30">
        <div className="container mx-auto max-w-6xl">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold mb-4">Technical Features</h2>
            <p className="text-muted-foreground text-lg">
              Full-stack implementation with modern technologies
            </p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            <Card className="border-0 shadow-lg">
              <CardContent className="p-6">
                <Upload className="h-12 w-12 text-primary mb-4" />
                <h3 className="text-xl font-semibold mb-2">File Upload System</h3>
                <p className="text-muted-foreground">
                  Multipart file upload with progress tracking, validation, and metadata storage in PostgreSQL.
                </p>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg">
              <CardContent className="p-6">
                <Shield className="h-12 w-12 text-primary mb-4" />
                <h3 className="text-xl font-semibold mb-2">JWT Authentication</h3>
                <p className="text-muted-foreground">
                  Spring Security with JWT tokens, password encryption, and role-based access control.
                </p>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg">
              <CardContent className="p-6">
                <Share2 className="h-12 w-12 text-primary mb-4" />
                <h3 className="text-xl font-semibold mb-2">Public Link Sharing</h3>
                <p className="text-muted-foreground">
                  Generate secure shareable links with expiration dates and access control.
                </p>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg">
              <CardContent className="p-6">
                <Zap className="h-12 w-12 text-primary mb-4" />
                <h3 className="text-xl font-semibold mb-2">REST API</h3>
                <p className="text-muted-foreground">
                  RESTful endpoints with proper HTTP status codes, error handling, and API documentation.
                </p>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg">
              <CardContent className="p-6">
                <Download className="h-12 w-12 text-primary mb-4" />
                <h3 className="text-xl font-semibold mb-2">Storage Integration</h3>
                <p className="text-muted-foreground">
                  Configurable storage backends: local filesystem or AWS S3 with proper MIME type handling.
                </p>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg">
              <CardContent className="p-6">
                <Cloud className="h-12 w-12 text-primary mb-4" />
                <h3 className="text-xl font-semibold mb-2">Docker Deployment</h3>
                <p className="text-muted-foreground">
                  Containerized application with Docker Compose, Nginx reverse proxy, and PostgreSQL.
                </p>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      <section className="py-20 px-4">
        <div className="container mx-auto text-center max-w-3xl">
          <h2 className="text-3xl font-bold mb-4">Technology Stack</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
            <div className="p-4 bg-muted rounded-lg">
              <h4 className="font-semibold">Backend</h4>
              <p className="text-sm text-muted-foreground">Spring Boot 3.2</p>
            </div>
            <div className="p-4 bg-muted rounded-lg">
              <h4 className="font-semibold">Frontend</h4>
              <p className="text-sm text-muted-foreground">React 19 + Vite</p>
            </div>
            <div className="p-4 bg-muted rounded-lg">
              <h4 className="font-semibold">Database</h4>
              <p className="text-sm text-muted-foreground">PostgreSQL</p>
            </div>
            <div className="p-4 bg-muted rounded-lg">
              <h4 className="font-semibold">Deployment</h4>
              <p className="text-sm text-muted-foreground">Docker</p>
            </div>
          </div>
          <Link to="/auth">
            <Button size="lg" className="text-lg px-8 py-6">
              Access Demo
            </Button>
          </Link>
        </div>
      </section>

      <footer className="border-t py-8 px-4 bg-muted/30">
        <div className="container mx-auto text-center">
          <div className="flex items-center justify-center space-x-2 mb-4">
            <Cloud className="h-6 w-6 text-primary" />
            <span className="text-lg font-semibold">CloudVault</span>
          </div>
          <p className="text-muted-foreground">
            Full-stack file storage platform demonstration
          </p>
        </div>
      </footer>

      {/* Demo modal removed */}
    </div>
  )
}
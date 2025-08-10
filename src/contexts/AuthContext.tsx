import React, { useEffect, useState } from 'react'
import { apiClient, type LoginRequest, type SignupRequest } from '../lib/api'
import type { AuthState } from '../types'
import { AuthContext, type AuthContextType } from './auth-context'

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [authState, setAuthState] = useState<AuthState>({
    user: null,
    isLoading: true,
    isAuthenticated: false
  })

  useEffect(() => {
    // Check for existing token and validate it
    const initAuth = async () => {
      const token = localStorage.getItem('auth_token')
      if (token) {
        apiClient.setToken(token)
        const response = await apiClient.getCurrentUser()
        
        if (response.data) {
          setAuthState({
            user: response.data,
            isLoading: false,
            isAuthenticated: true
          })
        } else {
          // Token is invalid, clear it
          apiClient.setToken(null)
          setAuthState({
            user: null,
            isLoading: false,
            isAuthenticated: false
          })
        }
      } else {
        setAuthState({
          user: null,
          isLoading: false,
          isAuthenticated: false
        })
      }
    }

    initAuth()
  }, [])

  const login = async (credentials: LoginRequest) => {
    try {
      const response = await apiClient.login(credentials)
      
      if (response.error) {
        throw new Error(response.error)
      }

      if (response.data) {
        apiClient.setToken(response.data.token)
        setAuthState({
          user: response.data.user,
          isLoading: false,
          isAuthenticated: true
        })
      }
    } catch (error) {
      console.error('Login failed:', error)
      throw error
    }
  }

  const register = async (userData: SignupRequest) => {
    try {
      const response = await apiClient.signup(userData)
      
      if (response.error) {
        throw new Error(response.error)
      }

      if (response.data) {
        apiClient.setToken(response.data.token)
        setAuthState({
          user: response.data.user,
          isLoading: false,
          isAuthenticated: true
        })
      }
    } catch (error) {
      console.error('Registration failed:', error)
      throw error
    }
  }

  const logout = () => {
    apiClient.setToken(null)
    setAuthState({
      user: null,
      isLoading: false,
      isAuthenticated: false
    })
  }

  return (
    <AuthContext.Provider value={{
      ...authState,
      login,
      register,
      logout
    }}>
      {children}
    </AuthContext.Provider>
  )
}


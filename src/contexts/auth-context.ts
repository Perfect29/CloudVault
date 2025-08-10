import { createContext } from 'react'
import type { AuthState } from '../types'
import type { LoginRequest, SignupRequest } from '../lib/api'

export interface AuthContextType extends AuthState {
  login: (credentials: LoginRequest) => Promise<void>
  register: (userData: SignupRequest) => Promise<void>
  logout: () => void
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined)
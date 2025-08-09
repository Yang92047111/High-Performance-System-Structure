import { defineStore } from 'pinia'
import axios from 'axios'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    token: localStorage.getItem('token') || null,
    isAuthenticated: false
  }),

  actions: {
    async login(credentials) {
      try {
        const response = await axios.post('/api/v1/users/login', credentials)
        const { token, user } = response.data
        
        this.token = token
        this.user = user
        this.isAuthenticated = true
        
        localStorage.setItem('token', token)
        
        // Set default authorization header
        axios.defaults.headers.common['Authorization'] = `Bearer ${token}`
        
        // Connect to WebSocket after successful login
        const { websocketService } = await import('../services/websocket')
        websocketService.connect()
        
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.error || 'Login failed' 
        }
      }
    },

    async register(userData) {
      try {
        const response = await axios.post('/api/v1/users/register', userData)
        return { success: true, data: response.data }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.error || 'Registration failed' 
        }
      }
    },

    async logout() {
      this.user = null
      this.token = null
      this.isAuthenticated = false
      
      localStorage.removeItem('token')
      delete axios.defaults.headers.common['Authorization']
      
      // Disconnect WebSocket
      const { websocketService } = await import('../services/websocket')
      websocketService.disconnect()
    },

    async initAuth() {
      if (this.token) {
        axios.defaults.headers.common['Authorization'] = `Bearer ${this.token}`
        
        try {
          const response = await axios.get('/api/v1/users/profile')
          this.user = response.data.user
          this.isAuthenticated = true
          
          // Connect to WebSocket after successful auth
          const { websocketService } = await import('../services/websocket')
          websocketService.connect()
        } catch (error) {
          // Token is invalid, clear it
          this.logout()
        }
      }
    }
  }
})
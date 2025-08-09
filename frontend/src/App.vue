<template>
  <div id="app" class="min-h-screen bg-gray-50">
    <nav class="bg-white shadow-sm border-b">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center">
            <h1 class="text-xl font-bold text-gray-900">📷 Social Media</h1>
          </div>
          <div class="flex items-center space-x-4">
            <router-link to="/" class="text-gray-700 hover:text-gray-900">Home</router-link>
            <router-link v-if="!authStore.isAuthenticated" to="/login" class="text-gray-700 hover:text-gray-900">Login</router-link>
            <div v-else class="flex items-center space-x-4">
              <span class="text-gray-700">Welcome, {{ authStore.user?.username }}!</span>
              <button @click="authStore.logout()" class="text-gray-700 hover:text-gray-900">Logout</button>
            </div>
          </div>
        </div>
      </div>
    </nav>
    
    <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <router-view />
    </main>
  </div>
</template>

<script>
import { useAuthStore } from './stores/auth'

export default {
  name: 'App',
  setup() {
    const authStore = useAuthStore()
    return { authStore }
  }
}
</script>
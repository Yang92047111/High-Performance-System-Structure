<template>
  <div class="space-y-6">
    <!-- Create Post Form -->
    <div v-if="authStore.isAuthenticated" class="bg-white rounded-lg shadow p-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Create New Post</h2>
      <form @submit.prevent="createPost" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700">Upload Image</label>
          <input
            type="file"
            @change="handleFileUpload"
            accept="image/*"
            class="mt-1 block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
          />
          <p class="mt-1 text-sm text-gray-500">Or enter image URL below</p>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700">Image URL</label>
          <input
            v-model="newPost.imageUrl"
            type="url"
            class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
            placeholder="https://example.com/image.jpg"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700">Caption</label>
          <textarea
            v-model="newPost.caption"
            rows="3"
            class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
            placeholder="Write a caption..."
          ></textarea>
        </div>
        <button
          type="submit"
          :disabled="uploading || (!newPost.imageUrl && !selectedFile)"
          class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
        >
          {{ uploading ? 'Uploading...' : 'Create Post' }}
        </button>
      </form>
    </div>

    <!-- Login prompt for non-authenticated users -->
    <div v-else class="bg-white rounded-lg shadow p-6 text-center">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Welcome to Social Media App!</h2>
      <p class="text-gray-600 mb-4">Please login to create posts and interact with content.</p>
      <router-link to="/login" class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
        Login / Register
      </router-link>
    </div>

    <!-- Posts Feed -->
    <div class="space-y-6">
      <div v-for="post in posts" :key="post.id" class="bg-white rounded-lg shadow overflow-hidden">
        <!-- Post Image -->
        <img :src="post.image_url" :alt="post.caption" class="w-full h-96 object-cover" />
        
        <!-- Post Content -->
        <div class="p-6">
          <p class="text-gray-900 mb-4">{{ post.caption }}</p>
          <p class="text-sm text-gray-500 mb-4">{{ formatDate(post.created_at) }}</p>
          
          <!-- Messages Section -->
          <div class="border-t pt-4">
            <h3 class="text-sm font-medium text-gray-900 mb-3">Messages</h3>
            
            <!-- Message List -->
            <div class="space-y-2 mb-4 max-h-40 overflow-y-auto">
              <div v-for="message in getPostMessages(post.id)" :key="message.id" class="text-sm">
                <span class="font-medium text-gray-900">{{ message.sender?.username || 'User' }}:</span>
                <span class="text-gray-700 ml-1">{{ message.message }}</span>
                <span class="text-xs text-gray-400 ml-2">{{ formatTime(message.created_at) }}</span>
              </div>
            </div>
            
            <!-- Add Message Form -->
            <form v-if="authStore.isAuthenticated" @submit.prevent="addMessage(post.id)" class="flex space-x-2">
              <input
                v-model="messageInputs[post.id]"
                type="text"
                placeholder="Add a message..."
                class="flex-1 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 text-sm"
              />
              <button
                type="submit"
                class="bg-blue-600 text-white px-3 py-1 rounded-md hover:bg-blue-700 text-sm"
              >
                Send
              </button>
            </form>
            <p v-else class="text-sm text-gray-500 text-center">
              <router-link to="/login" class="text-blue-600 hover:text-blue-800">Login</router-link> to add messages
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, reactive } from 'vue'
import axios from 'axios'
import { useAuthStore } from '../stores/auth'

export default {
  name: 'Home',
  setup() {
    const authStore = useAuthStore()
    const posts = ref([])
    const messages = ref({})
    const messageInputs = reactive({})
    const newPost = reactive({
      imageUrl: '',
      caption: ''
    })
    const selectedFile = ref(null)
    const uploading = ref(false)

    const fetchPosts = async () => {
      try {
        const response = await axios.get('/api/v1/posts')
        posts.value = response.data.posts || []
        
        // Fetch messages for each post
        for (const post of posts.value) {
          await fetchMessages(post.id)
        }
      } catch (error) {
        console.error('Error fetching posts:', error)
      }
    }

    const fetchMessages = async (postId) => {
      try {
        const response = await axios.get(`/api/v1/posts/${postId}/messages`)
        messages.value[postId] = response.data.messages || []
      } catch (error) {
        console.error('Error fetching messages:', error)
      }
    }

    const handleFileUpload = (event) => {
      selectedFile.value = event.target.files[0]
    }

    const uploadFile = async () => {
      if (!selectedFile.value) return null

      const formData = new FormData()
      formData.append('image', selectedFile.value)

      try {
        const response = await axios.post('/api/v1/upload/image', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })
        return response.data.url
      } catch (error) {
        console.error('Error uploading file:', error)
        throw error
      }
    }

    const createPost = async () => {
      try {
        uploading.value = true
        
        let imageUrl = newPost.imageUrl
        
        // If file is selected, upload it first
        if (selectedFile.value) {
          imageUrl = await uploadFile()
        }

        if (!imageUrl) {
          alert('Please provide an image URL or upload a file')
          return
        }

        await axios.post('/api/v1/posts', {
          image_url: imageUrl,
          caption: newPost.caption
        })
        
        // Reset form
        newPost.imageUrl = ''
        newPost.caption = ''
        selectedFile.value = null
        
        // Refresh posts
        await fetchPosts()
      } catch (error) {
        console.error('Error creating post:', error)
        if (error.response?.status === 401) {
          alert('Please login to create posts')
        } else {
          alert('Error creating post')
        }
      } finally {
        uploading.value = false
      }
    }

    const addMessage = async (postId) => {
      const message = messageInputs[postId]
      if (!message?.trim()) return

      try {
        await axios.post(`/api/v1/posts/${postId}/messages`, {
          message: message
        })
        
        // Clear input
        messageInputs[postId] = ''
        
        // Refresh messages for this post
        await fetchMessages(postId)
      } catch (error) {
        console.error('Error adding message:', error)
        if (error.response?.status === 401) {
          alert('Please login to add messages')
        }
      }
    }

    const getPostMessages = (postId) => {
      return messages.value[postId] || []
    }

    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleDateString()
    }

    const formatTime = (dateString) => {
      return new Date(dateString).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }

    onMounted(async () => {
      await authStore.initAuth()
      fetchPosts()
      
      // Set up real-time message handling
      if (authStore.isAuthenticated) {
        const { websocketService } = await import('../services/websocket')
        
        // Handle new messages
        websocketService.onMessage('new_message', (messageData, postId) => {
          // Add the new message to the messages for this post
          if (!messages.value[postId]) {
            messages.value[postId] = []
          }
          messages.value[postId].push(messageData)
        })
      }
    })

    return {
      posts,
      messages,
      messageInputs,
      newPost,
      selectedFile,
      uploading,
      handleFileUpload,
      createPost,
      addMessage,
      getPostMessages,
      formatDate,
      formatTime,
      authStore
    }
  }
}
</script>
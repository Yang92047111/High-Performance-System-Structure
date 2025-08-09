import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import axios from 'axios'
import './style.css'
import App from './App.vue'
import Home from './components/Home.vue'
import Login from './components/Login.vue'

// Configure axios base URL
axios.defaults.baseURL = 'http://localhost:8000'

const routes = [
  { path: '/', component: Home },
  { path: '/login', component: Login }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

const pinia = createPinia()
const app = createApp(App)

app.use(pinia)
app.use(router)
app.mount('#app')
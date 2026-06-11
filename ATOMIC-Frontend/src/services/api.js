import axios from 'axios'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080',
  headers: { 'Content-Type': 'application/json' },
})

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    const message = error.response?.data?.message || error.message || 'An unexpected error occurred'
    return Promise.reject(new Error(message))
  }
)

export const getSystemInfos = () =>
  apiClient.get('/infos').then((r) => r.data)

export const getTasks = () =>
  apiClient.get('/api/tasks').then((r) => r.data)

export const createTask = (payload) =>
  apiClient.post('/api/tasks', payload).then((r) => r.data)

export const updateTaskStatus = (id, status, lastModifiedBy) =>
  apiClient.put(`/api/tasks/${id}/status`, { status, lastModifiedBy }).then((r) => r.data)

export const deleteTask = (id) =>
  apiClient.delete(`/api/tasks/${id}`)

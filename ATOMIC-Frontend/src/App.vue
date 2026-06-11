<script setup>
import { ref, onMounted } from 'vue'
import SystemInfo from './components/SystemInfo.vue'
import TaskBoard from './components/TaskBoard.vue'
import TaskForm from './components/TaskForm.vue'
import { getTasks, createTask, updateTaskStatus, deleteTask } from './services/api'

const tasks = ref([])
const loadingTasks = ref(true)
const globalError = ref(null)

const loadTasks = async () => {
  try {
    tasks.value = await getTasks()
  } catch (err) {
    globalError.value = err.message
  } finally {
    loadingTasks.value = false
  }
}

const handleCreateTask = async (payload) => {
  try {
    const newTask = await createTask(payload)
    tasks.value.push(newTask)
  } catch (err) {
    globalError.value = err.message
  }
}

const handleStatusChange = async ({ task, newStatus }) => {
  try {
    const updated = await updateTaskStatus(task.id, newStatus, task.lastModifiedBy)
    const index = tasks.value.findIndex((t) => t.id === task.id)
    if (index !== -1) tasks.value[index] = updated
  } catch (err) {
    globalError.value = err.message
  }
}

const handleDeleteTask = async (taskId) => {
  try {
    await deleteTask(taskId)
    tasks.value = tasks.value.filter((t) => t.id !== taskId)
  } catch (err) {
    globalError.value = err.message
  }
}

const dismissError = () => { globalError.value = null }

onMounted(loadTasks)
</script>

<template>
  <div class="layout">
    <header class="header">
      <div class="header__brand">
        <span class="header__logo">⚛</span>
        <span class="header__name">ATOMIC <span class="header__sub">Tasky</span></span>
      </div>
      <span class="header__tagline">Task Management Dashboard</span>
    </header>

    <main class="main">
      <SystemInfo />

      <div v-if="globalError" class="alert alert--error">
        ⚠ {{ globalError }}
        <button class="alert__close" @click="dismissError">✕</button>
      </div>

      <div class="content-grid">
        <section class="section section--board">
          <div class="section__header">
            <h2 class="section__title">Task Board</h2>
            <button class="btn-refresh" @click="loadTasks" title="Refresh">↻ Refresh</button>
          </div>

          <div v-if="loadingTasks" class="loading">Loading tasks...</div>
          <TaskBoard
            v-else
            :tasks="tasks"
            @onStatusChange="handleStatusChange"
            @onDeleteTask="handleDeleteTask"
          />
        </section>

        <aside class="section section--form">
          <TaskForm @onTaskCreate="handleCreateTask" />
        </aside>
      </div>
    </main>
  </div>
</template>

<style>
*, *::before, *::after { box-sizing: border-box; }
body {
  margin: 0; padding: 0;
  background: #020617;
  color: #e2e8f0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  min-height: 100vh;
}
input, textarea, button { font-family: inherit; }
</style>

<style scoped>
.layout   { display: flex; flex-direction: column; min-height: 100vh; }
.header   {
  display: flex; align-items: center; justify-content: space-between;
  padding: 0.875rem 2rem;
  background: #0f172a; border-bottom: 1px solid #1e293b;
}
.header__brand  { display: flex; align-items: center; gap: 0.6rem; }
.header__logo   { font-size: 1.4rem; }
.header__name   { font-weight: 700; font-size: 1.1rem; color: #f1f5f9; }
.header__sub    { color: #3b82f6; }
.header__tagline{ font-size: 0.8rem; color: #475569; }
.main     { flex: 1; padding: 1.5rem 2rem; max-width: 1400px; margin: 0 auto; width: 100%; }
.content-grid { display: grid; grid-template-columns: 1fr 300px; gap: 1.5rem; align-items: start; }
.section  { }
.section--board { }
.section--form  { }
.section__header{ display: flex; align-items: center; justify-content: space-between; margin-bottom: 1rem; }
.section__title { margin: 0; font-size: 1rem; font-weight: 600; color: #e2e8f0; }
.btn-refresh { background: #1e293b; color: #94a3b8; border: 1px solid #334155; border-radius: 6px; padding: 0.3rem 0.7rem; cursor: pointer; font-size: 0.8rem; }
.btn-refresh:hover { color: #e2e8f0; }
.loading  { color: #475569; font-size: 0.9rem; padding: 2rem; text-align: center; }
.alert    { display: flex; align-items: center; justify-content: space-between; padding: 0.75rem 1rem; border-radius: 8px; margin-bottom: 1rem; font-size: 0.875rem; }
.alert--error { background: #450a0a; color: #fca5a5; border: 1px solid #7f1d1d; }
.alert__close { background: transparent; border: none; color: inherit; cursor: pointer; font-size: 1rem; padding: 0; }
@media (max-width: 900px) { .content-grid { grid-template-columns: 1fr; } }
</style>

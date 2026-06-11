<script setup>
import { ref, onMounted } from 'vue'
import { getSystemInfos } from '../services/api'

const loading = ref(true)
const info = ref(null)
const error = ref(null)
const isVaultDown = ref(false)

onMounted(async () => {
  try {
    const data = await getSystemInfos()
    info.value = data
    isVaultDown.value = data?.service_unavailable === true
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="system-info">
    <div v-if="loading" class="banner banner--loading">
      <span class="spinner" aria-label="Loading system info..."></span>
      Fetching system status...
    </div>

    <div v-else-if="error" class="banner banner--error">
      ⚠ Could not reach backend: {{ error }}
    </div>

    <div v-else-if="isVaultDown" class="banner banner--warning">
      ⚠ Vault service is currently unavailable. Running on fallback configuration.
    </div>

    <div v-else class="banner banner--success">
      ✓ System operational — Vault v{{ info?.version || 'unknown' }}
      <span class="meta">cluster: {{ info?.cluster_name || 'n/a' }}</span>
    </div>
  </div>
</template>

<style scoped>
.system-info { margin-bottom: 1.5rem; }
.banner {
  padding: 0.75rem 1.25rem;
  border-radius: 8px;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: 0.75rem;
}
.banner--loading  { background: #1e293b; color: #94a3b8; }
.banner--error    { background: #450a0a; color: #fca5a5; border: 1px solid #7f1d1d; }
.banner--warning  { background: #422006; color: #fed7aa; border: 1px solid #78350f; }
.banner--success  { background: #052e16; color: #86efac; border: 1px solid #14532d; }
.meta { margin-left: auto; color: #4ade80; font-size: 0.8rem; }
.spinner {
  width: 14px; height: 14px;
  border: 2px solid #475569;
  border-top-color: #60a5fa;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  flex-shrink: 0;
}
@keyframes spin { to { transform: rotate(360deg); } }
</style>

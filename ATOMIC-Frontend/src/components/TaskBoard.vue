<script setup>
const props = defineProps({
  tasks: { type: Array, required: true },
})
const emit = defineEmits(['onStatusChange', 'onDeleteTask'])

const columns = [
  { key: 'PENDING',     label: 'To Do',      color: '#3b82f6' },
  { key: 'IN_PROGRESS', label: 'In Progress', color: '#f59e0b' },
  { key: 'COMPLETED',   label: 'Done',        color: '#22c55e' },
]

const nextStatus = { PENDING: 'IN_PROGRESS', IN_PROGRESS: 'COMPLETED', COMPLETED: null }

const tasksForColumn = (key) => props.tasks.filter((t) => t.status === key)
</script>

<template>
  <div class="board">
    <div v-for="col in columns" :key="col.key" class="column">
      <div class="column__header" :style="{ borderTopColor: col.color }">
        <span class="column__label">{{ col.label }}</span>
        <span class="column__count">{{ tasksForColumn(col.key).length }}</span>
      </div>

      <div v-if="tasksForColumn(col.key).length === 0" class="column__empty">
        No tasks here
      </div>

      <div
        v-for="task in tasksForColumn(col.key)"
        :key="task.id"
        class="card"
      >
        <div class="card__title">{{ task.title }}</div>
        <div v-if="task.description" class="card__desc">{{ task.description }}</div>

        <div class="card__badges">
          <span class="badge badge--blue">👤 {{ task.createdBy }}</span>
          <span v-if="task.lastModifiedBy !== task.createdBy" class="badge badge--purple">
            ✏ {{ task.lastModifiedBy }}
          </span>
        </div>

        <div class="card__actions">
          <button
            v-if="nextStatus[col.key]"
            class="btn btn--advance"
            @click="emit('onStatusChange', { task, newStatus: nextStatus[col.key] })"
          >
            → {{ columns.find(c => c.key === nextStatus[col.key])?.label }}
          </button>
          <button
            class="btn btn--delete"
            @click="emit('onDeleteTask', task.id)"
          >
            🗑
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.board { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
.column {
  background: #0f172a;
  border-radius: 10px;
  padding: 1rem;
  min-height: 200px;
  border-top: 3px solid transparent;
}
.column__header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 1rem; padding-top: 0.5rem; }
.column__label  { font-weight: 600; font-size: 0.9rem; color: #e2e8f0; }
.column__count  { background: #1e293b; color: #94a3b8; border-radius: 999px; padding: 1px 8px; font-size: 0.75rem; }
.column__empty  { color: #475569; font-size: 0.8rem; text-align: center; padding: 1rem 0; }
.card {
  background: #1e293b;
  border-radius: 8px;
  padding: 0.875rem;
  margin-bottom: 0.75rem;
  border: 1px solid #334155;
}
.card__title  { font-weight: 600; color: #f1f5f9; margin-bottom: 0.35rem; }
.card__desc   { font-size: 0.8rem; color: #94a3b8; margin-bottom: 0.5rem; line-height: 1.4; }
.card__badges { display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 0.6rem; }
.badge        { font-size: 0.7rem; padding: 2px 8px; border-radius: 999px; }
.badge--blue  { background: #1e3a5f; color: #93c5fd; }
.badge--purple{ background: #2e1065; color: #c4b5fd; }
.card__actions{ display: flex; gap: 0.4rem; justify-content: flex-end; }
.btn          { border: none; border-radius: 6px; padding: 0.3rem 0.6rem; cursor: pointer; font-size: 0.78rem; transition: opacity 0.15s; }
.btn:hover    { opacity: 0.8; }
.btn--advance { background: #1e40af; color: #bfdbfe; }
.btn--delete  { background: #3f1515; color: #fca5a5; }
@media (max-width: 768px) { .board { grid-template-columns: 1fr; } }
</style>

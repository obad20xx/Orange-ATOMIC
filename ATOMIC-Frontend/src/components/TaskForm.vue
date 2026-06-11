<script setup>
import { ref } from 'vue'

const emit = defineEmits(['onTaskCreate'])

const title = ref('')
const description = ref('')
const createdBy = ref('')
const errors = ref({})

const validate = () => {
  errors.value = {}
  if (!title.value.trim())     errors.value.title = 'Title is required'
  if (!createdBy.value.trim()) errors.value.createdBy = 'Creator name is required'
  return Object.keys(errors.value).length === 0
}

const submit = () => {
  if (!validate()) return
  emit('onTaskCreate', {
    title: title.value.trim(),
    description: description.value.trim(),
    createdBy: createdBy.value.trim(),
  })
  title.value = ''
  description.value = ''
  createdBy.value = ''
}
</script>

<template>
  <form class="task-form" @submit.prevent="submit" novalidate>
    <h3 class="form__title">➕ New Task</h3>

    <div class="field">
      <label class="field__label" for="tf-title">Title *</label>
      <input id="tf-title" v-model="title" class="field__input" :class="{ 'field__input--error': errors.title }" placeholder="What needs to be done?" />
      <span v-if="errors.title" class="field__error">{{ errors.title }}</span>
    </div>

    <div class="field">
      <label class="field__label" for="tf-desc">Description</label>
      <textarea id="tf-desc" v-model="description" class="field__input field__textarea" placeholder="Optional details..." rows="2"></textarea>
    </div>

    <div class="field">
      <label class="field__label" for="tf-creator">Created By *</label>
      <input id="tf-creator" v-model="createdBy" class="field__input" :class="{ 'field__input--error': errors.createdBy }" placeholder="Your name" />
      <span v-if="errors.createdBy" class="field__error">{{ errors.createdBy }}</span>
    </div>

    <button type="submit" class="form__submit">Create Task</button>
  </form>
</template>

<style scoped>
.task-form  { background: #0f172a; border: 1px solid #1e293b; border-radius: 10px; padding: 1.25rem; }
.form__title{ margin: 0 0 1rem; font-size: 0.95rem; color: #e2e8f0; }
.field      { margin-bottom: 0.875rem; }
.field__label{ display: block; font-size: 0.8rem; color: #94a3b8; margin-bottom: 0.3rem; }
.field__input{
  width: 100%; box-sizing: border-box;
  background: #1e293b; border: 1px solid #334155;
  color: #f1f5f9; border-radius: 6px;
  padding: 0.5rem 0.75rem; font-size: 0.875rem;
  outline: none; transition: border-color 0.15s;
}
.field__input:focus      { border-color: #3b82f6; }
.field__input--error     { border-color: #ef4444; }
.field__textarea         { resize: vertical; min-height: 56px; }
.field__error  { font-size: 0.75rem; color: #f87171; margin-top: 0.25rem; display: block; }
.form__submit  {
  width: 100%; padding: 0.6rem;
  background: #1d4ed8; color: #eff6ff;
  border: none; border-radius: 6px;
  font-weight: 600; cursor: pointer;
  transition: background 0.15s;
}
.form__submit:hover { background: #2563eb; }
</style>

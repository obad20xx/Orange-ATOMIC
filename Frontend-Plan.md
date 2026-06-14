# Frontend Architecture & Design Document

## 1. Architectural Overview
The **ATOMIC-Frontend** is built as a highly responsive Single Page Application (SPA) leveraging **Vue 3** and the **Composition API**. It is built and bundled using **Vite** for unparalleled development speed and optimized production assets. The UI adheres to modern, clean web aesthetics using pure, scalable CSS without relying on heavy UI libraries, prioritizing performance and tailored styling.

## 2. Technology Stack & Rationale
*   **Vue 3 (Composition API):** Utilizing `<script setup>` syntax provides a clean, reactive, and highly readable component structure.
*   **Vite:** Serves as the build tool, enabling Hot Module Replacement (HMR) during development and generating highly optimized, cacheable static assets for production.
*   **Axios / Native Fetch wrapper:** Centralizes all HTTP interactions in a dedicated service layer to manage responses and intercepts uniformly.
*   **Nginx:** In production, the static assets are served via a hardened Nginx container that also acts as a reverse proxy to eliminate CORS overhead.

## 3. Component Hierarchy & Design

The application avoids a monolithic structure by strictly dividing responsibilities into cohesive components:

### 3.1 `App.vue` (The Orchestrator)
Acts as the central state manager and layout wrapper.
*   Maintains the reactive master `tasks` list.
*   Passes data down to child components via `props`.
*   Listens for state-mutating events (like `onTaskCreate` or `onStatusChange`) from children to ensure unidirectional data flow.
*   Handles global error catching and displays dismissible error banners.

### 3.2 `SystemInfo.vue` (Infrastructure Auditing)
Directly satisfies the integration requirement for the external service (HashiCorp Vault).
*   **Lifecycle:** Automatically fetches system info (`/infos`) on `onMounted`.
*   **Resilient UX:** Displays contextual banners (Loading, Success, or a graceful Warning if Vault is unreachable) based on the backend's circuit breaker response.

### 3.3 `TaskBoard.vue` (Kanban Visualization)
A highly organized visualization layer displaying tasks by status (`TODO`, `IN_PROGRESS`, `DONE`).
*   **Responsiveness:** Adapts dynamically to viewport sizes.
*   **Auditing Display:** Prominently renders the `createdBy` and conditional `lastModifiedBy` fields returned from the backend DTOs.
*   **Interactivity:** Emits actionable events (`onStatusChange`, `onDeleteTask`) back to the orchestrator.

### 3.4 `TaskForm.vue` (Data Entry)
A lightweight component dedicated to capturing user input.
*   **Validation:** Implements client-side validation logic that mirrors the backend's Jakarta Validation constraints, preventing malformed payloads from ever hitting the network.

## 4. API Integration Strategy

All backend communications are abstracted into `src/services/api.js`.
*   **Relative Routing:** In production, the `VITE_API_BASE_URL` is set to `/`. This forces the Vue application to make relative API calls (e.g., `/api/tasks`). Nginx then intercepts and routes these requests directly to the internal backend Kubernetes service. This elegant proxy strategy completely eliminates CORS complexity and preflight request overhead.
*   **Error Propagation:** The service layer standardizes error handling, catching HTTP exceptions and formatting them into readable messages that the Vue reactive state can easily display in the UI.

## 5. Testing & Quality Assurance
The frontend utilizes **Vitest** and **Vue Test Utils** to ensure component reliability.
*   **Component Isolation:** Tests (e.g., `SystemInfo.spec.js`) isolate components by mocking the `api.js` service module.
*   **DOM Assertion:** Tests verify that given a specific mocked API response, the correct HTML elements (such as success or error banners) render correctly in the virtual DOM.
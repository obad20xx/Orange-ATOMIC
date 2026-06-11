### Step 1: Environment & API Client Configuration

* **Details:** We need a clean, centralized Axios configuration (or native `fetch` wrapper) that reads the backend URL from environment variables. It must handle routing base prefixes correctly (e.g., handling `/api` and `/infos`).
* **Copilot Context:** Create a file named `src/services/api.js`.
* **Copilot Prompt:**
> "Create a lightweight API service module using Axios (or native fetch) for a Vue 3 application. It should read the base URL from `import.meta.env.VITE_API_BASE_URL`. Implement two clean, asynchronous export functions: `getSystemInfos()` which hits `/infos`, and `getTasks()` / `updateTaskStatus(id, status, user)` which hit the `/api/tasks` endpoints. Include basic interceptors or try/catch blocks to gracefully pass backend error messages to the UI."



---

### Step 2: The Core Components (Simple but Powerful UI)

To avoid a monolithic, messy `App.vue`, we will break the dashboard down into three highly cohesive components.

#### 2.1: The System Info Banner (`components/SystemInfo.vue`)

* **Details:** This component satisfies the core interview requirement: calling `/infos` and displaying the external service (Vault) metadata.
* **Copilot Prompt:**
> "Create a Vue 3 component named `SystemInfo.vue` using `<script setup>`. It should call the `getSystemInfos` API service on lifecycle mount. Show a loading spinner state while fetching, a beautifully styled alert banner displaying the system metadata on success, and a graceful, amber-colored fallback alert if the backend reports that the external Vault service is down/unreachable."



#### 2.2: The Task Board (`components/TaskBoard.vue`)

* **Details:** A clean Kanban-style or categorized board displaying tasks by status (`TODO`, `IN_PROGRESS`, `DONE`). It must explicitly display: Task Title, Description, Who added it (`createdBy`), and Who last changed it (`lastModifiedBy`).
* **Copilot Prompt:**
> "Create a Vue 3 component named `TaskBoard.vue` using `<script setup>`. It accepts an array of tasks as a prop and emits an `onStatusChange` event. Divide the layout into three distinct visual columns: 'To Do', 'In Progress', and 'Done'. Each task item must be rendered inside a clean card showing the title, description, a badge for 'Created By: [user]', and a conditional badge showing 'Last Modified By: [user]' if it has been modified."



#### 2.3: Quick Action Form (`components/TaskForm.vue`)

* **Details:** A simple inline form or modal to add a new task, ensuring client-side validation matches our backend constraints.
* **Copilot Prompt:**
> "Create a simple Vue 3 form component named `TaskForm.vue` using `<script setup>` and template validation. It should contain inputs for Title, Description, and Creator Name. Prevent submission if fields are empty, and emit an `onTaskCreate` event with the payload when valid."



---

### Step 3: Stitching it Together (`App.vue`)

* **Details:** The single-page brain of **Tasky**. It orchestrates state management, aggregates API responses, and handles user interactions seamlessly.
* **Copilot Context:** Open `src/App.vue`. Keep your `src/services/api.js` open in a split tab so Copilot sees the available methods.
* **Copilot Prompt:**
> "Write the primary single-page dashboard interface in `App.vue` using Vue 3 `<script setup>`. Import `SystemInfo.vue`, `TaskBoard.vue`, and `TaskForm.vue`. Manage a reactive global state for the master `tasks` list. Implement handler functions to catch emitted events: fetching the latest task state from the backend server on initialization, posting a new task, and updating a task's status while updating the auditor tracking field. Style the overall layout using a clean, professional dark-mode grid."



---

### Step 4: Unit Testing the Frontend

* **Details:** The prompt requires unit tests on *either* the backend or frontend. Since we are implementing backend tests in Milestone 1, adding even 1 or 2 quick component tests on the frontend via **Vitest** and **Vue Test Utils** will completely solidify your status as a thorough engineer.
* **Copilot Context:** Create a file named `src/components/__tests__/SystemInfo.spec.js`.
* **Copilot Prompt:**
> "Write a unit test using Vitest and `@vue/test-utils` for the `SystemInfo.vue` component. Mock the API service module to simulate a successful response returning system data. Assert that the loading indicator disappears and the correct system metadata is rendered in the DOM interface."
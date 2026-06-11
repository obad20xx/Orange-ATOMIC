package com.orange.ATOMIC;

import com.orange.ATOMIC.domain.Task;
import com.orange.ATOMIC.domain.TaskStatus;
import com.orange.ATOMIC.dto.CreateTaskRequestDto;
import com.orange.ATOMIC.dto.UpdateTaskStatusRequestDto;
import com.orange.ATOMIC.repository.TaskRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class TaskApiTests {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Autowired
    private TaskRepository taskRepository;
    
    @Autowired
    private ObjectMapper objectMapper;
    
    @BeforeEach
    void setUp() {
        taskRepository.deleteAll();
    }
    
    @Test
    void testGetTasksEmptyList() throws Exception {
        mockMvc.perform(get("/api/tasks"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$", hasSize(0)));
    }
    
    @Test
    void testCreateTaskSuccess() throws Exception {
        CreateTaskRequestDto request = CreateTaskRequestDto.builder()
            .title("Test Task")
            .description("Test Description")
            .createdBy("test-user")
            .build();
        
        mockMvc.perform(post("/api/tasks")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").exists())
            .andExpect(jsonPath("$.title").value("Test Task"))
            .andExpect(jsonPath("$.status").value(TaskStatus.PENDING.toString()));
    }
    
    @Test
    void testCreateTaskValidationError() throws Exception {
        CreateTaskRequestDto request = new CreateTaskRequestDto();
        
        mockMvc.perform(post("/api/tasks")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.fieldErrors").exists());
    }
    
    @Test
    void testUpdateTaskStatus() throws Exception {
        Task task = Task.builder()
            .title("Test Task")
            .description("Test Description")
            .status(TaskStatus.PENDING)
            .createdBy("test-user")
            .lastModifiedBy("test-user")
            .build();
        Task savedTask = taskRepository.save(task);
        
        UpdateTaskStatusRequestDto request = UpdateTaskStatusRequestDto.builder()
            .status(TaskStatus.IN_PROGRESS)
            .lastModifiedBy("test-user-2")
            .build();
        
        mockMvc.perform(put("/api/tasks/" + savedTask.getId() + "/status")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value(TaskStatus.IN_PROGRESS.toString()))
            .andExpect(jsonPath("$.lastModifiedBy").value("test-user-2"));
    }
    
    @Test
    void testUpdateTaskStatusNotFound() throws Exception {
        UpdateTaskStatusRequestDto request = UpdateTaskStatusRequestDto.builder()
            .status(TaskStatus.IN_PROGRESS)
            .lastModifiedBy("test-user")
            .build();
        
        mockMvc.perform(put("/api/tasks/" + UUID.randomUUID() + "/status")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isNotFound());
    }
    
    @Test
    void testDeleteTaskSuccess() throws Exception {
        Task task = Task.builder()
            .title("Task to delete")
            .status(TaskStatus.PENDING)
            .createdBy("test-user")
            .lastModifiedBy("test-user")
            .build();
        Task savedTask = taskRepository.save(task);
        
        mockMvc.perform(delete("/api/tasks/" + savedTask.getId()))
            .andExpect(status().isNoContent());
        
        mockMvc.perform(get("/api/tasks"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$", hasSize(0)));
    }
    
    @Test
    void testDeleteTaskNotFound() throws Exception {
        mockMvc.perform(delete("/api/tasks/" + UUID.randomUUID()))
            .andExpect(status().isNotFound());
    }
    
    @Test
    void testGetVaultInfoFallback() throws Exception {
        mockMvc.perform(get("/infos"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.service_unavailable").value(true));
    }
}

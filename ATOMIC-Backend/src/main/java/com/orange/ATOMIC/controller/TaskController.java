package com.orange.ATOMIC.controller;

import com.orange.ATOMIC.dto.CreateTaskRequestDto;
import com.orange.ATOMIC.dto.TaskResponseDto;
import com.orange.ATOMIC.dto.UpdateTaskStatusRequestDto;
import com.orange.ATOMIC.service.TaskService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
public class TaskController {
    
    private final TaskService taskService;
    
    @GetMapping
    public ResponseEntity<List<TaskResponseDto>> getAllTasks() {
        return ResponseEntity.ok(taskService.getAllTasks());
    }
    
    @PostMapping
    public ResponseEntity<TaskResponseDto> createTask(@Valid @RequestBody CreateTaskRequestDto request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(taskService.createTask(request));
    }
    
    @PutMapping("/{taskId}/status")
    public ResponseEntity<TaskResponseDto> updateTaskStatus(
        @PathVariable UUID taskId,
        @Valid @RequestBody UpdateTaskStatusRequestDto request
    ) {
        return ResponseEntity.ok(taskService.updateTaskStatus(taskId, request));
    }
    
    @DeleteMapping("/{taskId}")
    public ResponseEntity<Void> deleteTask(@PathVariable UUID taskId) {
        taskService.deleteTask(taskId);
        return ResponseEntity.noContent().build();
    }
}

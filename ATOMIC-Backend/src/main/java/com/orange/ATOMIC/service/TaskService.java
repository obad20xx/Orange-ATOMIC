package com.orange.ATOMIC.service;

import com.orange.ATOMIC.domain.Task;
import com.orange.ATOMIC.domain.TaskStatus;
import com.orange.ATOMIC.dto.CreateTaskRequestDto;
import com.orange.ATOMIC.dto.TaskResponseDto;
import com.orange.ATOMIC.dto.UpdateTaskStatusRequestDto;
import com.orange.ATOMIC.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TaskService {
    
    private final TaskRepository taskRepository;
    
    public List<TaskResponseDto> getAllTasks() {
        return taskRepository.findAll().stream()
            .map(this::mapToResponseDto)
            .collect(Collectors.toList());
    }
    
    public TaskResponseDto createTask(CreateTaskRequestDto request) {
        Task task = Task.builder()
            .title(request.getTitle())
            .description(request.getDescription())
            .status(TaskStatus.PENDING)
            .createdBy(request.getCreatedBy())
            .lastModifiedBy(request.getCreatedBy())
            .build();
        
        Task savedTask = taskRepository.save(task);
        return mapToResponseDto(savedTask);
    }
    
    public TaskResponseDto updateTaskStatus(UUID taskId, UpdateTaskStatusRequestDto request) {
        Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> new IllegalArgumentException("Task not found with id: " + taskId));
        
        task.setStatus(request.getStatus());
        task.setLastModifiedBy(request.getLastModifiedBy());
        
        Task updatedTask = taskRepository.save(task);
        return mapToResponseDto(updatedTask);
    }
    
    public void deleteTask(UUID taskId) {
        if (!taskRepository.existsById(taskId)) {
            throw new IllegalArgumentException("Task not found with id: " + taskId);
        }
        taskRepository.deleteById(taskId);
    }
    
    private TaskResponseDto mapToResponseDto(Task task) {
        return TaskResponseDto.builder()
            .id(task.getId())
            .title(task.getTitle())
            .description(task.getDescription())
            .status(task.getStatus())
            .createdBy(task.getCreatedBy())
            .lastModifiedBy(task.getLastModifiedBy())
            .createdAt(task.getCreatedAt())
            .lastModifiedAt(task.getLastModifiedAt())
            .build();
    }
}

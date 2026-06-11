package com.orange.ATOMIC.dto;

import com.orange.ATOMIC.domain.TaskStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TaskResponseDto {
    private UUID id;
    private String title;
    private String description;
    private TaskStatus status;
    private String createdBy;
    private String lastModifiedBy;
    private LocalDateTime createdAt;
    private LocalDateTime lastModifiedAt;
}

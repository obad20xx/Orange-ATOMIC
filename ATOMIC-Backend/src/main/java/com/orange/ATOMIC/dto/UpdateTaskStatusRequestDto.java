package com.orange.ATOMIC.dto;

import com.orange.ATOMIC.domain.TaskStatus;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateTaskStatusRequestDto {
    
    @NotNull(message = "Status is required")
    private TaskStatus status;
    
    @NotNull(message = "Last modified by is required")
    private String lastModifiedBy;
}

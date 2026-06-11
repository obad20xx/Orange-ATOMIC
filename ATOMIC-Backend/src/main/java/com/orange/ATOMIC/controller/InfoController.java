package com.orange.ATOMIC.controller;

import com.orange.ATOMIC.service.VaultService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequiredArgsConstructor
public class InfoController {
    
    private final VaultService vaultService;
    
    @GetMapping("/infos")
    public ResponseEntity<Map<String, Object>> getVaultInfo() {
        Map<String, Object> vaultInfo = vaultService.getVaultHealth();
        return ResponseEntity.ok(vaultInfo);
    }
}

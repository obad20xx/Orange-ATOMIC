package com.orange.ATOMIC.service;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class VaultService {
    
    private final RestClient restClient;
    
    @CircuitBreaker(name = "vault", fallbackMethod = "vaultFallback")
    public Map<String, Object> getVaultHealth() {
        try {
            ResponseEntity<Map> response = restClient.get()
                .uri("http://localhost:8200/v1/sys/health")
                .retrieve()
                .toEntity(Map.class);
            
            if (response.getStatusCode().is2xxSuccessful()) {
                return response.getBody();
            }
            return vaultFallback(new Exception("Non-2xx response from Vault"));
        } catch (Exception e) {
            log.warn("Vault health check failed", e);
            return vaultFallback(e);
        }
    }
    
    public Map<String, Object> vaultFallback(Exception e) {
        log.info("Using Vault fallback due to: {}", e.getMessage());
        Map<String, Object> fallback = new HashMap<>();
        fallback.put("sealed", null);
        fallback.put("standby", null);
        fallback.put("performance_standby", null);
        fallback.put("replication_perf_mode", "unknown");
        fallback.put("replication_dr_mode", "unknown");
        fallback.put("server_time_utc", System.currentTimeMillis() / 1000);
        fallback.put("version", "unknown");
        fallback.put("cluster_name", "unknown");
        fallback.put("cluster_id", "unknown");
        fallback.put("service_unavailable", true);
        return fallback;
    }
}

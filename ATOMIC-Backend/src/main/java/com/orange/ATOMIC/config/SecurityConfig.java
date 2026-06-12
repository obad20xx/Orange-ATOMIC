package com.orange.ATOMIC.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // 1. Enforce the CorsConfigurationSource bean we built earlier
            .cors(Customizer.withDefaults()) 
            
            // 2. Disable CSRF (Safe for Stateless APIs using JWT/Tokens rather than Cookies)
            .csrf(csrf -> csrf.disable()) 
            
            // 3. Set Session Management to Stateless (No JSESSIONID cookies created on the server)
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            
            // 4. Configure Endpoint Authorization Matrix
            .authorizeHttpRequests(auth -> auth
                // Public App Data
                .requestMatchers("/infos").permitAll()
                
                // Public DevOps & Cluster Monitoring
                .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                
                // Public API Documentation (Swagger)
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**", "/swagger-ui.html").permitAll()
                
                // Public Business Infrastructure (Covers GET, POST, PUT, DELETE for tasks)
                .requestMatchers("/api/tasks/**").permitAll()
                
                // Catch-all safety net
                .anyRequest().authenticated()
            );

        return http.build();
    }
}
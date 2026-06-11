package com.orange.ATOMIC.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI atomicOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("ATOMIC API")
                        .version("v1.0")
                        .description("Living blueprint contract for Frontend and QA teams"));
    }
}
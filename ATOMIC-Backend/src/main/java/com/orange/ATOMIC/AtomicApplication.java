package com.orange.ATOMIC;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.client.RestClient;

@SpringBootApplication
public class AtomicApplication {

	public static void main(String[] args) {
		SpringApplication.run(AtomicApplication.class, args);
	}

	@Bean
	public RestClient restClient() {
		return RestClient.create();
	}
}

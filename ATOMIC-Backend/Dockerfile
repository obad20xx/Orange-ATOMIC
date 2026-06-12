# Stage 1: Compile the application using JDK 21
FROM gradle:8.7-jdk21-alpine AS builder
WORKDIR /build

# Cache dependencies
COPY build.gradle settings.gradle ./
RUN gradle dependencies --no-daemon || true

# Copy source code and compile an executable jar file
COPY src ./src
RUN gradle bootJar --no-daemon -x test

# Stage 2: Minimal Production JRE 21 Runtime Environment
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Harden container by adding a non-root system user
RUN addgroup -S taskygroup && adduser -S taskyuser -G taskygroup
USER taskyuser

# Copy the build artifact from Stage 1
COPY --from=builder /build/build/libs/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
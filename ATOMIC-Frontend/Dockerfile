# ==========================================
# STAGE 1: Compile Vue Application Source
# ==========================================
FROM node:20-alpine AS builder
WORKDIR /app

# Cache node modules installation
COPY package*.json ./
RUN npm ci

# Copy code configuration and compile production bundle
COPY . .
RUN npm run build

# ==========================================
# STAGE 2: Production Nginx Static Server
# ==========================================
FROM nginx:alpine

# Remove default static landing page placeholder files
RUN rm -rf /usr/share/nginx/html/*

# Copy build artifacts directly into the Nginx public directory
COPY --from=builder /app/dist /usr/share/nginx/html

# EXPOSE port 80 for the Nginx engine
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
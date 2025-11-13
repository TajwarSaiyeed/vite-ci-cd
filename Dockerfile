# ============================================
# STAGE 1: Build the Vite application
# ============================================
# Use Node.js 20 Alpine (lightweight Linux) as the base image
# 'AS builder' names this stage so we can reference it later
FROM node:20-alpine AS builder

# Set the working directory inside the container to /app
# All subsequent commands will run from this directory
WORKDIR /app

# Enable corepack (Node.js package manager manager) and prepare pnpm
# This allows us to use pnpm without installing it globally
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy only package files first (for better Docker layer caching)
# If these files haven't changed, Docker will reuse the cached layer
COPY package.json pnpm-lock.yaml ./

# Install dependencies using pnpm
# --frozen-lockfile ensures the exact versions from pnpm-lock.yaml are installed
# This prevents any unexpected version updates during build
RUN pnpm install --frozen-lockfile

# Copy all remaining project files into the container
# This includes source code, config files, etc.
COPY . .

# Define a build argument for the API URL
# This can be overridden during docker build with --build-arg
# Default value points to production API
ARG VITE_API_URL=https://api.prod.example.com

# Build the Vite application for production
# The VITE_API_URL environment variable is passed to the build process
# Vite will embed this value during the build (NOT at runtime)
RUN VITE_API_URL=${VITE_API_URL} pnpm run build

# ============================================
# STAGE 2: Serve the built application
# ============================================
# Use nginx Alpine image (lightweight web server)
# This creates a much smaller final image than including Node.js
FROM nginx:alpine

# Copy the built files from the 'builder' stage
# /app/dist is where Vite outputs the production build
# /usr/share/nginx/html is nginx's default serving directory
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port 80 to allow external connections
# This is the standard HTTP port
EXPOSE 80

# Start nginx in the foreground (daemon off prevents it from running in background)
# This keeps the container running
CMD ["nginx", "-g", "daemon off;"]



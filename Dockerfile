# STAGE 1: Build the Vite application

# Use Node.js 20 Alpine as the base image for building the app
FROM node:20-alpine AS builder

# Set the working directory inside the container to /app
WORKDIR /app

# Enable corepack (Node.js package manager manager) and prepare pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy only package files first 
COPY package.json pnpm-lock.yaml ./

# Install dependencies using pnpm
# --frozen-lockfile ensures the exact versions from pnpm-lock.yaml are installed
RUN pnpm install --frozen-lockfile

# Copy all remaining project files into the container
COPY . .

# Define a build argument for the API URL
# This can be overridden during docker build with --build-arg
# Default value points to production API
ARG VITE_API_URL=https://api.prod.example.com

# Build the Vite application for production
# The VITE_API_URL environment variable is passed to the build process
RUN VITE_API_URL=${VITE_API_URL} pnpm run build


# STAGE 2: Serve the built application

# Use nginx Alpine image
# This creates a much smaller final image than including Node.js
FROM nginx:alpine

# Copy the built files from the 'builder' stage
# /app/dist is where Vite outputs the production build
# /usr/share/nginx/html is nginx's default serving directory
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port 80 to allow external connections
EXPOSE 80

# Start nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]



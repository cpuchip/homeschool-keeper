# Multi-stage Docker build for Homeschool Keeper

# Stage 1: Build Vue.js frontend
FROM node:22-alpine AS frontend-builder

WORKDIR /app/backend/frontend

# Copy frontend package files
COPY backend/frontend/package*.json ./

# Install dependencies
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Copy frontend source code
COPY backend/frontend/ ./

# Build frontend for production
RUN npm run build

# Stage 2: Build Go backend
FROM golang:1.25-alpine AS backend-builder

WORKDIR /app

# Copy Go mod files
COPY backend/go.mod backend/go.sum ./

# Download dependencies
RUN go mod download

# Copy Go source code
COPY backend/ ./

# Copy built frontend into backend/frontend/dist
COPY --from=frontend-builder /app/backend/frontend/dist ./frontend/dist

# Build the Go binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o homeschool-keeper .

# Stage 3: Final production image
FROM alpine:3.20

WORKDIR /app

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates tzdata

# Copy the binary from builder stage
COPY --from=backend-builder /app/homeschool-keeper .

# Copy built frontend assets
COPY --from=backend-builder /app/frontend/dist ./frontend/dist

# Create non-root user
RUN adduser -D -g '' appuser
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/health || exit 1

# Command to run the application
CMD ["./homeschool-keeper"]

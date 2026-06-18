# syntax=docker/dockerfile:1

# ---- Build stage ----
FROM golang:1.25-alpine AS build

WORKDIR /src

# Cache dependencies first.
COPY go.mod go.sum ./
RUN go mod download

# Build the statically linked server binary.
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" \
    -o /out/mcp-mssql-server ./cmd/server

# ---- Runtime stage ----
FROM alpine:3.20 AS runtime

# ca-certificates for TLS connections to SQL Server.
RUN apk --no-cache add ca-certificates && \
    addgroup -S mcp && adduser -S -G mcp mcp

WORKDIR /app
COPY --from=build /out/mcp-mssql-server /app/mcp-mssql-server

# Run as a non-root user.
USER mcp

ENTRYPOINT ["/app/mcp-mssql-server"]

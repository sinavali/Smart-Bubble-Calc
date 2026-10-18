# Multi-stage build for ultra-minimal, high-security production container
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Download modules
COPY go.mod ./
RUN go mod download

# Copy source code
COPY . .

# Build static binary without CGO (RAM footprint ~15MB)
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/bubble-server ./cmd/server

# Final minimal runner stage
FROM alpine:3.20

RUN apk --no-cache add ca-certificates tzdata curl

WORKDIR /app

COPY --from=builder /app/bubble-server .
COPY config.json .

ENV PORT=8080
ENV TZ=Asia/Tehran

EXPOSE 8080

CMD ["./bubble-server"]

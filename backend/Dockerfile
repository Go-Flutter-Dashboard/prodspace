FROM golang:1.24 AS builder

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o admin-backend ./app

FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /app

COPY --from=builder /app/admin-backend /app/admin-backend
COPY wait-for-it.sh ./wait-for-it.sh
RUN chmod +x ./wait-for-it.sh

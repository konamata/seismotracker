FROM golang:1.23.4 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o seismotracker .


FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/seismotracker .
EXPOSE 8080
CMD ["./seismotracker"]
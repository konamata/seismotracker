FROM golang:1.24 AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-w -s" -o seismo-fetcher main.go

FROM scratch
WORKDIR /app/
COPY --from=builder /app/seismo-fetcher /app/seismo-fetcher
CMD ["./seismo-fetcher"]
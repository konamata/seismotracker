FROM postgres:17

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-17-postgis-3 && \
    rm -rf /var/lib/apt/lists/*

CMD ["/usr/local/bin/docker-entrypoint.sh", "postgres", "-c", "max_wal_size=2GB", "-c", "checkpoint_timeout=5min", "-c", "max_parallel_workers=8", "-c", "max_parallel_workers_per_gather=4", "-c", "max_worker_processes=8"]
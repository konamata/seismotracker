ARG py_version=3.11.2

FROM --platform=$BUILDPLATFORM python:$py_version-slim-bullseye as base

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    git \
    libpq-dev \
    make \
    openssh-client \
    software-properties-common \
  && apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

ENV PYTHONIOENCODING=utf-8
ENV LANG=C.UTF-8

RUN python -m pip install --upgrade "pip==24.0" "setuptools==69.2.0" "wheel==0.43.0" --no-cache-dir


FROM base as dbt-core

ARG commit_ref=main

HEALTHCHECK CMD dbt --version || exit 1

WORKDIR /usr/app/dbt/
ENTRYPOINT ["dbt"]

RUN python -m pip install --no-cache-dir "dbt-core @ git+https://github.com/dbt-labs/dbt-core@${commit_ref}#subdirectory=core"


FROM base as dbt-postgres

HEALTHCHECK CMD dbt --version || exit 1

WORKDIR /usr/app/dbt/
ENTRYPOINT ["dbt"]

RUN python -m pip install --no-cache-dir dbt-postgres

FROM dbt-core as dbt-third-party

ARG dbt_third_party

RUN if [ "$dbt_third_party" ]; then \
        python -m pip install --no-cache-dir "${dbt_third_party}"; \
    else \
        echo "No third party adapter provided"; \
    fi \
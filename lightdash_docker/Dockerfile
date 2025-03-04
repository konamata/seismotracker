# -----------------------------
# Stage 0: Install Dependencies
# -----------------------------
    ARG NODE_VERSION=20
    FROM --platform=$BUILDPLATFORM node:${NODE_VERSION}-bookworm-slim AS base
    
    ENV PNPM_HOME="/pnpm"
    ENV PATH="$PNPM_HOME:$PATH"
    
    # Install pnpm
    RUN npm i -g corepack@latest && \
        corepack enable pnpm && \
        corepack prepare pnpm@9.15.5 --activate && \
        pnpm config set store-dir /pnpm/store
    
    WORKDIR /usr/app
    
    # Install common dependencies
    RUN apt-get update && \
        apt-get install -y --no-install-recommends \
            build-essential \
            g++ \
            python3 \
            python3-psycopg2 \
            python3-venv \
            python3-dev \
            software-properties-common \
            unzip \
            git \
            libcairo2-dev \
            libpango1.0-dev \
            librsvg2-dev \
            && apt-get clean \
            && rm -rf /var/lib/apt/lists/*
    
    # Install architecture-specific dependencies
    RUN if [ "$(dpkg --print-architecture)" = "arm64" ]; then \
          apt-get install -y --no-install-recommends libpq-dev:arm64; \
        else \
          apt-get install -y --no-install-recommends libpq-dev; \
        fi
    
    # -----------------------------
    # Stage 1: Dev Environment
    # -----------------------------
    FROM --platform=$TARGETPLATFORM base AS dev
    
    RUN apt-get update && apt-get install -y --no-install-recommends \
        postgresql-client \
        && apt-get clean
    
    EXPOSE 3000 8080
    
    # -----------------------------
    # Stage 2: Build for Production
    # -----------------------------
    FROM --platform=$BUILDPLATFORM base AS prod-builder
    
    # Install dependencies for build process
    COPY package.json .
    COPY pnpm-workspace.yaml .
    COPY pnpm-lock.yaml .
    COPY tsconfig.json .
    COPY .eslintrc.js .
    COPY packages/common/package.json ./packages/common/
    COPY packages/warehouses/package.json ./packages/warehouses/
    COPY packages/backend/package.json ./packages/backend/
    COPY packages/frontend/package.json ./packages/frontend/
    
    # Use cache for faster builds
    RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
        pnpm install --frozen-lockfile --prefer-offline
    
    # Build common
    COPY packages/common/tsconfig.json ./packages/common/
    COPY packages/common/tsconfig.build.json ./packages/common/
    COPY packages/common/src/ ./packages/common/src/
    RUN pnpm -F @lightdash/common build
    
    # Build warehouses
    COPY packages/warehouses/tsconfig.json ./packages/warehouses/
    COPY packages/warehouses/src/ ./packages/warehouses/src/
    RUN pnpm -F @lightdash/warehouses build
    
    # Build backend
    COPY packages/backend/tsconfig.json ./packages/backend/
    COPY packages/backend/src/ ./packages/backend/src
    RUN pnpm -F backend build
    
    # Build frontend
    COPY packages/frontend ./packages/frontend
    RUN pnpm -F frontend build
    
    # Remove development dependencies
    RUN rm -rf node_modules && rm -rf packages/*/node_modules
    
    # Install only production dependencies
    ENV NODE_ENV production
    RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
        pnpm install --prod --frozen-lockfile --prefer-offline
    
    # -----------------------------
    # Stage 3: Execution Environment
    # -----------------------------
    FROM --platform=$TARGETPLATFORM node:${NODE_VERSION}-bookworm-slim AS prod
    
    ENV NODE_ENV production
    ENV PATH="$PNPM_HOME:$PATH"
    
    # Install pnpm
    RUN npm i -g corepack@latest && \
        corepack enable pnpm && \
        corepack prepare pnpm@9.15.5 --activate && \
        pnpm config set store-dir /pnpm/store
    
    WORKDIR /usr/app
    
    # Install runtime dependencies
    RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        python3-psycopg2 \
        python3-venv \
        git \
        build-essential \
        libcairo2-dev \
        libpango1.0-dev \
        librsvg2-dev \
        dumb-init \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
    
    # Copy built application from builder stage
    COPY --from=prod-builder /usr/app /usr/app
    
    # Set up dbt versions
    COPY --from=prod-builder /usr/local/dbt1.4 /usr/local/dbt1.4
    COPY --from=prod-builder /usr/local/dbt1.5 /usr/local/dbt1.5
    COPY --from=prod-builder /usr/local/dbt1.6 /usr/local/dbt1.6
    COPY --from=prod-builder /usr/local/dbt1.7 /usr/local/dbt1.7
    COPY --from=prod-builder /usr/local/dbt1.8 /usr/local/dbt1.8
    COPY --from=prod-builder /usr/local/dbt1.9 /usr/local/dbt1.9
    
    RUN ln -s /usr/local/dbt1.4/bin/dbt /usr/local/bin/dbt \
        && ln -s /usr/local/dbt1.5/bin/dbt /usr/local/bin/dbt1.5 \
        && ln -s /usr/local/dbt1.6/bin/dbt /usr/local/bin/dbt1.6 \
        && ln -s /usr/local/dbt1.7/bin/dbt /usr/local/bin/dbt1.7 \
        && ln -s /usr/local/dbt1.8/bin/dbt /usr/local/bin/dbt1.8 \
        && ln -s /usr/local/dbt1.9/bin/dbt /usr/local/bin/dbt1.9
    
    # Copy production entrypoint
    COPY ./docker/prod-entrypoint.sh /usr/bin/prod-entrypoint.sh
    
    EXPOSE 8080
    
    WORKDIR /usr/app/packages/backend
    
    ENTRYPOINT ["dumb-init", "--", "/usr/bin/prod-entrypoint.sh"]
    CMD ["node", "dist/index.js"]
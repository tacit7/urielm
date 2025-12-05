# Build stage
FROM elixir:1.17-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    nodejs \
    npm \
    git \
    python3

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Copy dependency files
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy assets
COPY assets/package*.json assets/
RUN cd assets && npm ci --production=false

# Copy application code
COPY . .

# Build assets
RUN cd assets && node build.js --deploy
RUN mix tailwind urielm --minify
RUN mix phx.digest

# Compile and build release
RUN mix compile
RUN mix release

# Runtime stage - use same Elixir image to avoid OpenSSL mismatch
FROM elixir:1.17-alpine

RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    ca-certificates \
    nodejs

WORKDIR /app

# Copy release from builder
COPY --from=builder /app/_build/prod/rel/urielm ./

# Copy Digital Ocean CA certificate for database SSL verification
COPY priv/certs/do-ca.crt /etc/ssl/certs/do-ca.crt

# Create non-root user
RUN addgroup -g 1000 urielm && \
    adduser -D -u 1000 -G urielm urielm && \
    chown -R urielm:urielm /app

USER urielm

ENV HOME=/app
ENV MIX_ENV=prod
ENV NODE_ENV=production
ENV PORT=4000

EXPOSE 4000

CMD ["bin/urielm", "start"]

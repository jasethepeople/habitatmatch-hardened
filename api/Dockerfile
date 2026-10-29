FROM hexpm/elixir:1.18.4-erlang-27.2-debian-bookworm-20250610-slim AS build
WORKDIR /app
ENV MIX_ENV=prod
RUN mix local.hex --force && mix local.rebar --force
COPY mix.exs mix.lock* ./
RUN mix deps.get --only prod
COPY config ./config
COPY lib ./lib
COPY priv ./priv
RUN mix compile && mix release
FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends openssl libstdc++6 ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV LANG=C.UTF-8 HOME=/app
COPY --from=build /app/_build/prod/rel/habitat_match ./
USER 10001:10001
EXPOSE 4000
CMD ["/bin/sh","-c","/app/bin/habitat_match eval \"HabitatMatch.Release.migrate\" && /app/bin/habitat_match start"]

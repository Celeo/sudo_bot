FROM docker.io/hexpm/elixir:1.12.2-erlang-22.3.4.19-ubuntu-xenial-20210114 AS build

ARG DISCORD_TOKEN
WORKDIR /opt/app
ENV MIX_ENV=prod
ENV DISCORD_TOKEN=${DISCORD_TOKEN}

RUN apt-get update && apt-get install -y cmake

COPY mix.exs mix.lock ./
RUN mix local.hex --force   &&\
    mix local.rebar --force &&\
    mix deps.get            &&\
    mix deps.compile

COPY config ./config
COPY lib ./lib
RUN mix release

FROM docker.io/hexpm/elixir:1.12.2-erlang-22.3.4.19-ubuntu-xenial-20210114 AS run
RUN mkdir /opt/app
WORKDIR /opt/app

COPY --from=build /opt/app/_build/prod/rel/sudo_bot .

CMD ["./bin/sudo_bot", "start"]

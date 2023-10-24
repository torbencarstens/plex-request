FROM hexpm/elixir:1.15.7-erlang-26.1.1-debian-bookworm-20230612-slim

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
#RUN mix local.hex --force && \
#    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
#RUN mix deps.compile

COPY priv priv

# note: if your project uses a tool like https://purgecss.com/,
# which customizes asset compilation based on what it finds in
# your Elixir templates, you will need to move the asset compilation
# step down so that `lib` is available.
COPY assets assets

# compile assets
RUN mix assets.deploy

# Compile the release
COPY lib lib

#RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

#RUN mix phx.gen.release
#RUN mix release

CMD mix phx.server

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
#FROM debian:bookworm-20230612-slim
#
#RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
#  && apt-get clean && rm -f /var/lib/apt/lists/*_*
#
## Set the locale
#RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
#
#ENV LANG en_US.UTF-8
#ENV LANGUAGE en_US:en
#ENV LC_ALL en_US.UTF-8
#
#WORKDIR "/app"
#RUN chown nobody /app
#
## set runner ENV
#ENV MIX_ENV="prod"
#
## Only copy the final release from the build stage
#COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/plex_request ./
##COPY --from=builder --chown=nobody:root /app/priv/static/assets /assets
##COPY --from=builder --chown=nobody:root /app/priv/static/images /assets/images
##COPY --from=builder --chown=nobody:root /app/priv/static/robots.txt /assets/robots.txt
##COPY --from=builder --chown=nobody:root /app/priv/static/favicon.ico /assets/favicon.ico
#COPY --from=builder --chown=nobody:root /app/priv/static/assets /assets
#
#USER nobody
#
## If using an environment that doesn't automatically reap zombie processes, it is
## advised to add an init process such as tini via `apt-get install`
## above and adding an entrypoint. See https://github.com/krallin/tini for details
## ENTRYPOINT ["/tini", "--"]
#
#CMD /app/bin/server

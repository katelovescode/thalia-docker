#!/bin/bash

#######################
# Requirements
#######################
# homebrew

#######################
# Dependencies Added
#######################
# yq

# TODO: ENHANCEMENT
# remove added dependencies that aren't essential for rails

#######################
# Optional
#######################
# nodenv
# rbenv

# For local development & testing
# trap "find . ! -name 'dockerized_rails.sh' ! -name '.' ! -name '..' -name ".*" -exec rm -rf {} +" INT

# TODO: ENHANCEMENT
# confirmation dialogue saying this script handles rbenv or the default ruby, nodenv or the default node
# if you have rbenv or nodenv this will work
# if you're using system ruby or node, no guarantees

# TODO: ENHANCEMENT
# confirmation dialogue saying this script handles rbenv or the default ruby, nodenv or the default node
if which brew; then
  if ! which yq; then
    brew install yq
  fi
else
  echo "homebrew is required for this script, please install homebrew and run again"
  exit 1
fi

# Take in user's preferred app_name, defaults to the directory name
read -rp "App Name [$(basename "$(pwd)")]: " app_name
app_name=${app_name:-$(basename "$(pwd)")}
constant_app_name=$(echo "$app_name" | tr '[:lower:]' '[:upper:]')

# If rbenv is installed, ask for a version number, default to 3.2.3
if command -v rbenv &>/dev/null; then
  read -rp "Ruby version [3.2.3]: " ruby_version
  version=${ruby_version:-3.2.3}
  rbenv local "$version"
  if ! rbenv versions | grep "$version"; then
    rbenv install "$version"
  fi
fi

# If nodenv is installed, ask for a version number, default to 20.12.2
if command -v nodenv &>/dev/null; then
  read -rp "Node version [20.12.2]: " node_version
  version=${node_version:-20.12.2}
  nodenv local "$version"
  if ! nodenv versions | grep "$version"; then
    nodenv install "$version"
  fi
fi

# TODO: ENHANCEMENT
# install bundler and rails if they're not already installed
# if ! gem list | grep bundler; then gem install bundler; else echo "bundler is already installed"; fi
# if ! gem list | grep rails; then gem install rails; else echo "rails is already installed"; fi
# Same thing for ruby, same thing for node, same thing for yarn

# if there have been changes (version files added because rbenv and nodenv exist), commit them
if [[ $(git status --porcelain) ]]; then
  git add . && git commit -m "Version files for local env management"
fi

# initiate rails w/ postgres, esbuild, postcss
rails new . -n "$app_name" -d postgresql -j esbuild -c postcss -T

# commit the bare rails initiation
git add . && git commit -m "Fresh rails install with postgres, esbuild, postcss, and removing minitest"

# edit the default database configuration to include the host we need to connect rails to the postgres container
m="<%= ENV[\"${constant_app_name}_DATABASE_HOST\"] %>" yq -i '.default.host = strenv(m)' config/database.yml

# TODO: conditionally do this on localhost only, and/or replace dockerfile/build for local dev, maybe a second script
# turn off forced ssl
sed -i -e 's/config.force_ssl = true/config.force_ssl = false/g' config/environments/production.rb

# commit the host configuration
git add . && git commit -m "Fresh rails install with postgres, esbuild, postcss, and removing minitest"

# create the network
docker network create "$app_name"

# initiated a data volume and make the custom user the owner
docker volume create "${app_name}_pgdata"

# This assumes that `rails new` creates a database.yml with the following production configuration:
# production:
#   <<: *default
#   database: [app_name]_production
#   username: [app_name]
#   password: <%= ENV["[APP_NAME]_DATABASE_PASSWORD"] %>
# If versions of Rails after 7 change how this is done, this script won't work anymore

docker run -d \
  --name "${app_name}_postgres" \
  --network "$app_name" \
  --network-alias "${app_name}_postgres" \
  -v "${app_name}_pgdata":/var/lib/postgresql/data \
  -p 5432:5432 \
  -e POSTGRES_USER="${app_name}" \
  -e POSTGRES_DB="${app_name}_production" \
  -e POSTGRES_PASSWORD=password \
  postgres
# TODO: ENHANCEMENT
# configure passwords/secrets

docker build . -t "$app_name"

# Wait for postgres to be up

# Max query attempts before consider setup failed
# MAX_TRIES=5

# # Return true-like values if and only if logs
# # contain the expected "ready" line
# function dbIsReady() {
#   docker logs "${app_name}_postgres" | grep "database system is ready to accept connections"
# }

# function waitUntilServiceIsReady() {
#   attempt=1
#   while [ $attempt -le $MAX_TRIES ]; do
#     if "$@"; then
#       echo "$2 container is up!"
#       break
#     fi
#     echo "Waiting for $2 container... (attempt: $((attempt++)))"
#     sleep 5
#   done

#   if [ $attempt -gt $MAX_TRIES ]; then
#     echo "Error: $2 not responding, cancelling set up"
#     exit 1
#   fi
# }

# waitUntilServiceIsReady dbIsReady "PostgreSQL"

docker run -d \
  --name "$app_name" \
  --network "$app_name" \
  --network-alias "${app_name}_app" \
  -p 3000:3000 \
  -e RAILS_MASTER_KEY="$(cat ./config/master.key)" \
  -e ${constant_app_name}_DATABASE_HOST="${app_name}_postgres" \
  -e "${constant_app_name}_DATABASE_PASSWORD"=password \
  "$app_name"
# TODO: ENHANCEMENT
# configure passwords/secrets

# TODO: CURRENT BREAKING ERROR
# rails container is exiting with socket error; my hunch is that it's because the POSTGRES_HOST isn't used in the rails app database.yml, so we might need to programmatically set that line, need to dig into this

#!/bin/bash

#######################
# Requirements
#######################
# homebrew

#######################
# Dependencies Added
#######################
# yq
# ruby
# node

# TODO: ENHANCEMENT
# remove added dependencies that aren't essential for rails

#######################
# Optional
#######################
# nodenv
# rbenv

# TODO: ENHANCEMENT
# confirmation dialogue saying this script handles rbenv or the default ruby, nodenv or the default node
# if you have rbenv or nodenv this will work
# if you're using system ruby or node, no guarantees

# TODO: ENHANCEMENT
# Take in target directory to the script as a param

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

# Take in user's preferred ruby version, defaults to 3.2.3
read -rp "Ruby version [3.2.3]: " ruby_version
version=${ruby_version:-3.2.3}
if command -v rbenv &>/dev/null; then
  rbenv local "$version"
  if ! rbenv versions | grep "$version"; then
    rbenv install "$version"
  fi
# if nodenv is not installed, install latest version with brew
else
  brew install "ruby@${version}"
fi

# Take in user's preferred node version, defaults to 20.12.2
read -rp "Node version [20.12.2]: " node_version
version=${node_version:-20.12.2}
# if nodenv is installed, check for this version and install it if it doesn't exist
if command -v nodenv &>/dev/null; then
  nodenv local "$version"
  if ! nodenv versions | grep "$version"; then
    nodenv install "$version"
  fi
# if nodenv is not installed, install this version with brew
else
  major_version=$(echo "$version" | cut -d '.' -f1)
  if ! which node || ! node -v == "$version"; then
    brew install "node@${major_version}"
  fi
fi

# if there have been changes (specificially version files added because rbenv and nodenv exist), commit them
if [[ $(git status --porcelain) ]]; then
  git add . && git commit -m "Version files for local env management"
fi

# install bundler and rails if they're not already installed
gem install bundler rails

# install yarn if it's not already installed
npm install -g yarn

# TODO: ENHANCEMENT
# take in other rails new flags

# initiate rails w/ postgres, esbuild, postcss
rails new . -n "$app_name" -d postgresql -j esbuild -c postcss -T

# commit the bare rails initiation
git add . && git commit -m "Fresh rails install with postgres, esbuild, postcss, and removing minitest"

# The rest of this script assumes that `rails new` creates a database.yml with the following production configuration:
#
# production:
#   <<: *default
#   database: [app_name]_production
#   username: [app_name]
#   password: <%= ENV["[APP_NAME]_DATABASE_PASSWORD"] %>
#
# If versions of Rails after 7 change how this is done, this script won't work anymore

# edit the default database configuration to include the host we need to connect rails to the postgres container
host="<%= ENV[\"${constant_app_name}_DATABASE_HOST\"] %>" yq -i '.default.host = strenv(host)' config/database.yml

# TODO: ENHANCEMENT
# conditionally do this on localhost only, and/or replace dockerfile/build for local dev, maybe a second script
# turn off forced ssl
sed -i -e 's/config.force_ssl = true/config.force_ssl = false/g' config/environments/production.rb

# commit the host configuration
git add . && git commit -m "Fresh rails install with postgres, esbuild, postcss, and removing minitest"

# create the network
docker network create "$app_name"

# initiate a data volume
docker volume create "${app_name}_pgdata"

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

docker run -d \
  --name "$app_name" \
  --network "$app_name" \
  --network-alias "${app_name}_app" \
  -p 3000:3000 \
  -e RAILS_MASTER_KEY="$(cat ./config/master.key)" \
  -e "${constant_app_name}_DATABASE_HOST"="${app_name}_postgres" \
  -e "${constant_app_name}_DATABASE_PASSWORD"=password \
  "$app_name"
# TODO: ENHANCEMENT
# configure passwords/secrets

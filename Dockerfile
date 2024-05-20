# syntax=docker/dockerfile:1
FROM ruby:3.2.3
RUN apt-get update -qq && apt-get install -y nodejs npm postgresql-client
RUN npm install -g npx yarn
WORKDIR /thalia
COPY Gemfile /thalia/Gemfile
COPY Gemfile.lock /thalia/Gemfile.lock
COPY ./engines/thalia_discord_bot /thalia/engines/thalia_discord_bot
RUN bundle install

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Configure the main process to run when running the image
CMD ["rails", "server", "-b", "0.0.0.0"]

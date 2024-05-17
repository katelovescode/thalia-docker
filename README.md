# README

Initialized using a slight alteration of the following instructions: [Quickstart: Compose and Rails](https://github.com/docker/awesome-compose/tree/master/official-documentation-samples/rails)

This unique configuration:

- Dockerfile: add `npm` to `apt-get install`, add `RUN npm install -g npx yarn`
- Docker New command: `docker compose run --no-deps app rails new . -f -n thalia -d postgresql -j esbuild -c postcss -T --skip-docker`

# Dome Lite Backend

![](https://github.com/themakersteam/dome-lite-backend/workflows/Publish/badge.svg)
![](https://github.com/themakersteam/dome-lite-backend/workflows/Rebase%20Staging/badge.svg)

## Setup

If this is your first time setting up the project, you should do the following:

### 1. Add Credentials for Package Registries 

Copy `.env.example` to `.env`:

```shell
cp .env.example .env
```

#### GitHub Package Registry (`BUNDLE_RUBYGEMS__PKG__GITHUB__COM`)

Generate a [Personal Access Token] with `repo` and `package:read` scopes

Refer to [Configuring RubyGems for use with GitHub Package Registry] for more info.

#### Sidekiq Enterprise (`BUNDLE_ENTERPRISE__CONTRIBSYS__COM`)

Find it on [1Password] (if you don't have an account, use the [1Password invitation link]).

### 2. Run setup script

```bash
script/setup
```

## How to develop?

Whenever you pull any commits, run the following command to make sure everything is up to date:

```bash
script/setup
```

The app server should be running on (http://127.0.0.1:3000)

## Rails Console

To enter Rails console, run the following:

```bash
script/console
```

## `byebug`

To attach to the running container (if you want to use `byebug`):

```bash
script/attach
```

## PubSub Emulator

To create the publishers and subscribers on the emulator, run the following:

```bash
docker-compose exec pubsub-emulator /scripts/setup.sh
```

To create an OrderCreated/OrderUpdated message update the `./docker/pubsub-emulator/scripts/order_created.json`
or `./docker/pubsub-emulator/scripts/order_updated.json` file with desired values then run below command:

```bash
docker-compose exec pubsub-emulator python /scripts/helper.py project publish OrderCreated /scripts/order_created.json
docker-compose exec pubsub-emulator python /scripts/helper.py project publish OrderUpdated /scripts/order_updated.json
```

To debug the published events run below commands for a topic:

```bash
docker-compose exec pubsub-emulator subscriber.py project create POSOrderUpdated debug-POSOrderUpdated
docker-compose exec pubsub-emulator python /scripts/helper.py project receive debug-POSOrderUpdated

docker-compose exec pubsub-emulator subscriber.py project create POSStoreUpdated debug-POSStoreUpdated
docker-compose exec pubsub-emulator python /scripts/helper.py project receive debug-POSStoreUpdated

docker-compose exec pubsub-emulator subscriber.py project create POSCatalogUpdated debug-POSCatalogUpdated
docker-compose exec pubsub-emulator python /scripts/helper.py project receive debug-POSCatalogUpdated
```

## How to import a database dump?

If you need to import a specific database dump, make sure you followed all the steps in the [Setup]
section, and then run:

```bash
docker-compose exec app rails db:drop db:create
```

Import it using the following command (replace `$PATH` with the dump file location):

```sh
cat $PATH | docker-compose exec -T postgres psql -U postgres -d app_development
```

## Troubleshooting

> A server is already running. Check /app/tmp/pids/server.pid.

If you face this issue, run the following commands:

```bash
rm tmp/pids/server.pid
docker-compose up -d
```

[Personal Access Token]: https://github.com/settings/tokens
[Configuring RubyGems for use with GitHub Package Registry]: https://help.github.com/en/articles/configuring-rubygems-for-use-with-github-package-registry
[1Password]: https://themakersteam.1password.com/vaults/lu4ew2yomipbbp6qta6k653b3u/allitems/f23hcizldja4zipln6dqz7vjzq
[1Password invitation link]: https://themakersteam.1password.com/teamjoin/invitation/R4R33EXTAVDP7MR5BLEBEIDB7E

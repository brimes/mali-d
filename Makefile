.DEFAULT_GOAL := help
COMPOSE := docker compose
WEB := $(COMPOSE) exec web
RUN  := $(COMPOSE) run --rm web

.PHONY: help
help: ## Lista comandos disponíveis
	@awk 'BEGIN {FS = ":.*##"; printf "Uso: make \033[36m<comando>\033[0m\n\nComandos:\n"} \
		/^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# --- Lifecycle -----------------------------------------------------------------

.PHONY: setup
setup: build db-prepare seed ## Build + criar DB + rodar migrations + seed (primeira vez)

.PHONY: build
build: ## Build da imagem web
	$(COMPOSE) build

.PHONY: up
up: ## Sobe containers em background
	$(COMPOSE) up -d

.PHONY: up-fg
up-fg: ## Sobe containers em foreground (logs ao vivo)
	$(COMPOSE) up

.PHONY: down
down: ## Para containers
	$(COMPOSE) down

.PHONY: restart
restart: ## Reinicia o web
	$(COMPOSE) restart web

.PHONY: ps
ps: ## Status dos containers
	$(COMPOSE) ps

.PHONY: logs
logs: ## Tail logs do web
	$(COMPOSE) logs -f web

.PHONY: logs-db
logs-db: ## Tail logs do postgres
	$(COMPOSE) logs -f db

# --- Banco ---------------------------------------------------------------------

.PHONY: db-prepare
db-prepare: ## db:prepare (create + migrate)
	$(RUN) bin/rails db:prepare

.PHONY: migrate
migrate: ## Roda migrations (em public + em todos os tenants)
	$(WEB) bin/rails db:migrate

.PHONY: rollback
rollback: ## Rollback uma migration
	$(WEB) bin/rails db:rollback

.PHONY: seed
seed: ## Roda db:seed (cria admin master)
	$(WEB) bin/rails db:seed

.PHONY: db-reset
db-reset: ## DROP + create + migrate + seed (apaga TUDO)
	$(RUN) bin/rails db:drop db:create db:migrate db:seed

.PHONY: psql
psql: ## Console psql no DB de desenvolvimento
	$(COMPOSE) exec db psql -U postgres mali_d_development

# --- Rails ---------------------------------------------------------------------

.PHONY: console
console: ## bin/rails console
	$(WEB) bin/rails console

.PHONY: runner
runner: ## Executa script Ruby (uso: make runner CMD='puts User.count')
	$(WEB) bin/rails runner "$(CMD)"

.PHONY: routes
routes: ## Lista rotas (filtra com GREP=foo)
	$(WEB) bin/rails routes $(if $(GREP),| grep $(GREP),)

.PHONY: bash
bash: ## Shell no container web
	$(WEB) bash

# --- Geradores -----------------------------------------------------------------

.PHONY: g
g: ## Generator (uso: make g G='model Foo bar:string')
	$(RUN) bin/rails g $(G)

# --- Assets / Tailwind ---------------------------------------------------------

.PHONY: css
css: ## Build único do Tailwind
	$(WEB) bin/rails tailwindcss:build

.PHONY: css-watch
css-watch: ## Watch do Tailwind em foreground
	$(WEB) bin/rails tailwindcss:watch

# --- Qualidade -----------------------------------------------------------------

.PHONY: test
test: ## RSpec
	$(WEB) bundle exec rspec

.PHONY: lint
lint: ## RuboCop
	$(WEB) bundle exec rubocop

.PHONY: brakeman
brakeman: ## Análise estática de segurança
	$(WEB) bundle exec brakeman --no-pager

# --- Tenants -------------------------------------------------------------------

.PHONY: tenant-list
tenant-list: ## Lista subdomínios das empresas
	$(WEB) bin/rails runner 'puts Company.pluck(:subdomain)'

.PHONY: tenant-migrate
tenant-migrate: ## Migra apenas os schemas dos tenants
	$(WEB) bin/rails db:migrate

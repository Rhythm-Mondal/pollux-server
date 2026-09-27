SHELL := /bin/bash

COMPOSE ?= docker compose
COMPOSE_FILE := compose.yml
ENV_FILE := .env
ENV_EXAMPLE := .env.example

.DEFAULT_GOAL := help

.PHONY: help env check build up up-d down restart ps logs logs-api logs-db \
	api-shell db-shell db-login db-reset

help:
	@echo "Pollux development commands:"
	@echo "  make env        Create .env from .env.example when it is missing"
	@echo "  make check      Validate the Compose configuration"
	@echo "  make build      Build the API image"
	@echo "  make up         Start the development stack"
	@echo "  make up-d       Start the development stack in the background"
	@echo "  make down       Stop the development stack"
	@echo "  make restart    Restart the development stack"
	@echo "  make ps         Show service status"
	@echo "  make logs       Follow logs for all services"
	@echo "  make logs-api   Follow API logs"
	@echo "  make logs-db    Follow PostgreSQL logs"
	@echo "  make api-shell  Open a shell in the API container"
	@echo "  make db-shell   Open a PostgreSQL shell"
	@echo "  make db-reset   Remove the local database volume and recreate it"

$(ENV_FILE):
	@if [ -f "$(ENV_EXAMPLE)" ]; then \
		cp "$(ENV_EXAMPLE)" "$(ENV_FILE)"; \
		echo "Created $(ENV_FILE). Update its development values before sharing it."; \
	else \
		echo "$(ENV_EXAMPLE) is missing; cannot create $(ENV_FILE)."; \
		exit 1; \
	fi

env: $(ENV_FILE)

check: $(ENV_FILE)
	@$(COMPOSE) -f $(COMPOSE_FILE) config -q

build: $(ENV_FILE)
	@$(COMPOSE) -f $(COMPOSE_FILE) build

up: $(ENV_FILE)
	@$(COMPOSE) -f $(COMPOSE_FILE) up --build

up-d: $(ENV_FILE)
	@$(COMPOSE) -f $(COMPOSE_FILE) up --build --detach

down:
	@$(COMPOSE) -f $(COMPOSE_FILE) down

restart: $(ENV_FILE)
	@$(COMPOSE) -f $(COMPOSE_FILE) down
	@$(COMPOSE) -f $(COMPOSE_FILE) up --build --detach

ps: $(ENV_FILE)
	@$(COMPOSE) -f $(COMPOSE_FILE) ps

logs: $(ENV_FILE)
	@$(COMPOSE) -f $(COMPOSE_FILE) logs --follow

logs-api: $(ENV_FILE)
	@$(COMPOSE) -f $(COMPOSE_FILE) logs --follow pollux

logs-db: $(ENV_FILE)
	@$(COMPOSE) -f $(COMPOSE_FILE) logs --follow pollux-pg

api-shell: $(ENV_FILE)
	@$(COMPOSE) -f $(COMPOSE_FILE) exec pollux sh

db-shell: $(ENV_FILE)
	@$(COMPOSE) -f $(COMPOSE_FILE) exec pollux-pg sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

db-login: db-shell

db-reset: $(ENV_FILE)
	@$(COMPOSE) -f $(COMPOSE_FILE) down --volumes --remove-orphans
	@$(COMPOSE) -f $(COMPOSE_FILE) up --build --detach

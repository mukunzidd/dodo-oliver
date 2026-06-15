# CBATechno monorepo — quick commands.
#   web     → bun        (cbatechno-web)
#   mobile  → npm/expo   (cbatechno-mobile)
#   shared  → npm/tsc    (@cbatechno/shared)
#   backend → supabase   (cbatechno-backend)  — local stack: studio on :54323
#
# Run `make` or `make help` to list everything.

WEB     := cbatechno-web
MOBILE  := cbatechno-mobile
SHARED  := cbatechno-shared
BACKEND := cbatechno-backend

# Local Supabase URLs (see `make db-status` for the rest).
STUDIO_URL  := http://127.0.0.1:54323
MAILPIT_URL := http://127.0.0.1:54324

.DEFAULT_GOAL := help
.PHONY: help install dev dev-restart \
        db-start db-stop db-restart db-status db-studio mail db-reset db-push db-diff \
        db-types db-seed db-migrate functions-serve advisors \
        web-dev web-build web-test web-lint web-format \
        mobile-start mobile-ios mobile-android \
        shared-build shared-typecheck \
        docker-up docker-down docker-logs \
        check test clean

## ----------------------------------------------------------------------------
## General
## ----------------------------------------------------------------------------

help: ## Show this help
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

dev: db-start ## Start local backend, then run the web app against it (local by default)
	@echo "Local Supabase up — Studio: $(STUDIO_URL). Web app uses .env.local (local)."
	cd $(WEB) && bun run dev

dev-restart: db-restart ## Restart everything: Supabase stack + web dev server (:3000)
	-lsof -ti tcp:3000 | xargs kill 2>/dev/null || true
	@echo "Local Supabase up — Studio: $(STUDIO_URL). Web app uses .env.local (local)."
	cd $(WEB) && bun run dev

install: ## Install deps across all sub-projects
	cd $(WEB)     && bun install
	cd $(SHARED)  && npm install
	cd $(MOBILE)  && npm install
	cd $(BACKEND) && npm install

## ----------------------------------------------------------------------------
## Supabase (local backend stack)
## ----------------------------------------------------------------------------

db-start: ## Start the local Supabase stack
	cd $(BACKEND) && supabase start

db-stop: ## Stop the local Supabase stack
	cd $(BACKEND) && supabase stop

db-restart: db-stop db-start ## Restart the local Supabase stack

db-status: ## Show local Supabase URLs and keys
	cd $(BACKEND) && supabase status

db-studio: ## Open Supabase Studio in the browser
	open $(STUDIO_URL)

mail: ## Open Mailpit (local email inbox) in the browser
	open $(MAILPIT_URL)

db-reset: ## Reset DB: re-run all migrations + seed.sql (DESTROYS local data)
	cd $(BACKEND) && supabase db reset

db-push: ## Push local migrations to the linked remote project
	cd $(BACKEND) && supabase db push

db-diff: ## Diff local schema against migrations
	cd $(BACKEND) && supabase db diff

db-migrate: ## Create a new migration: make db-migrate name=add_foo
	cd $(BACKEND) && supabase migration new $(name)

db-seed: ## Load the demo catalog into the running DB
	cd $(BACKEND) && psql "$$(supabase status -o env | grep DB_URL | cut -d= -f2- | tr -d '"')" -f supabase/seeds/demo-catalog.sql

db-types: ## Regenerate TS types into cbatechno-shared/src/database.ts
	cd $(BACKEND) && npm run gen:types

functions-serve: ## Serve edge functions locally
	cd $(BACKEND) && supabase functions serve

advisors: ## Run Supabase security/performance advisors
	cd $(BACKEND) && supabase db advisors

## ----------------------------------------------------------------------------
## Web (cbatechno-web)
## ----------------------------------------------------------------------------

web-dev: ## Run the web app in dev mode (:3000)
	cd $(WEB) && bun run dev

web-build: ## Build the web app
	cd $(WEB) && bun run build

web-test: ## Run web tests
	cd $(WEB) && bun run test

web-lint: ## Lint the web app
	cd $(WEB) && bun run lint

web-format: ## Format + autofix the web app
	cd $(WEB) && bun run format

## ----------------------------------------------------------------------------
## Mobile (cbatechno-mobile)
## ----------------------------------------------------------------------------

mobile-start: ## Start the Expo dev server
	cd $(MOBILE) && npm run start

mobile-ios: ## Start Expo on iOS
	cd $(MOBILE) && npm run ios

mobile-android: ## Start Expo on Android
	cd $(MOBILE) && npm run android

## ----------------------------------------------------------------------------
## Shared (@cbatechno/shared)
## ----------------------------------------------------------------------------

shared-build: ## Build the shared package
	cd $(SHARED) && npm run build

shared-typecheck: ## Typecheck the shared package
	cd $(SHARED) && npm run typecheck

## ----------------------------------------------------------------------------
## Docker (web container)
## ----------------------------------------------------------------------------

docker-up: ## Build + run the web app container (:3000)
	docker compose up --build -d

docker-down: ## Stop the web app container
	docker compose down

docker-logs: ## Tail the web container logs
	docker compose logs -f web

## ----------------------------------------------------------------------------
## Aggregate
## ----------------------------------------------------------------------------

check: shared-typecheck web-lint ## Typecheck shared + lint web

test: web-test ## Run all tests

clean: ## Remove build artifacts
	rm -rf $(WEB)/dist $(SHARED)/dist

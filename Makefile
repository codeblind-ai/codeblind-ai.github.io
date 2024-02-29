default: menu
.PHONY: default

menu:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(lastword $(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: menu

#######################################################################
# PRIMARY TARGETS

install: ## installs dependancies and tools
	@$(MAKE) tools
	@$(MAKE) update
.PHONY: install

serve: ## starts the development server
	@npm run serve
.PHONY: serve

clean: ## removes all build artifacts
	@npm run clean
	@rm -rf node_modules public resources .hugo_build.lock package-lock.json
.PHONY: clean
tools:
.PHONY: tools

update:
	@go mod tidy
	@go mod download
	@npm install
.PHONY: update

# Настройки
SPEC_URL     := https://api.clo.ru/openapi.json
API_URL      := https://api.clo.ru/
SPEC_FIXED   := openapi.final.json
JQ_SCRIPT    := fix.jq
CONFIG       := config.yaml
SDK_OUT      := clo_cloud.gen.go

# Инструменты
JQ           := jq
OAPI_CODEGEN := oapi-codegen
CURL         := curl -sSfL
BASE_MODULE  := github.com/Elaugaste/clo-cloud-sdk

.PHONY: all
all: generate clean-spec ## Полный цикл (сборка + очистка)

.PHONY: fetch-and-fix
fetch-and-fix: ## 1. Скачивание и трансформация спеки
	@echo "--- [1/3] Fetching and fixing spec ---"
	@$(CURL) $(SPEC_URL) | $(JQ) --arg api_url "$(API_URL)" -f $(JQ_SCRIPT) > $(SPEC_FIXED)

.PHONY: update-mod
update-mod: fetch-and-fix ## 2. Обновление go.mod (если мажорная версия > 1)
	@echo "--- [2/3] Checking version for go.mod ---"
	@VERSION=$$(jq -r '.info.version' $(SPEC_FIXED)); \
	MAJOR=$$(echo $$VERSION | cut -d. -f1); \
	if [ "$$MAJOR" -gt "1" ]; then \
		NEW_MOD="$(BASE_MODULE)/v$$MAJOR"; \
		echo "Major version is $$MAJOR. Module path: $$NEW_MOD"; \
	else \
		NEW_MOD="$(BASE_MODULE)"; \
		echo "Major version is $$MAJOR. Module path: $$NEW_MOD"; \
	fi; \
	go mod edit -module $$NEW_MOD

.PHONY: generate
generate: update-mod ## 3. Генерация кода и go mod tidy
	@echo "--- [3/3] Generating Go SDK ---"
	@$(OAPI_CODEGEN) -config $(CONFIG) $(SPEC_FIXED)
	@go mod tidy
	@echo "Success: $(SDK_OUT) generated."

.PHONY: release
release: generate ## Создание git-тега с авто-инкрементом патча
	@VERSION=$$(jq -r '.info.version' $(SPEC_FIXED)); \
	TAG_PREFIX="v$$VERSION"; \
	if ! git rev-parse "$$TAG_PREFIX" >/dev/null 2>&1; then \
		echo "--- Creating new base tag: $$TAG_PREFIX ---"; \
		git tag -a "$$TAG_PREFIX" -m "Release $$TAG_PREFIX"; \
		git push origin "$$TAG_PREFIX"; \
	else \
		echo "--- Tag $$TAG_PREFIX already exists. Finding next internal patch... ---"; \
		LATEST_TAG=$$(git tag -l "$$TAG_PREFIX.*" | sort -V | tail -n1); \
		if [ -z "$$LATEST_TAG" ]; then \
			NEXT_PATCH=1; \
		else \
			CURRENT_PATCH=$$(echo $$LATEST_TAG | cut -d. -f4); \
			NEXT_PATCH=$$(($$CURRENT_PATCH + 1)); \
		fi; \
		NEW_TAG="$$TAG_PREFIX.$$NEXT_PATCH"; \
		echo "--- Creating internal patch tag: $$NEW_TAG ---"; \
		git tag -a "$$NEW_TAG" -m "Internal release $$NEW_TAG"; \
		git push origin "$$NEW_TAG"; \
	fi


.PHONY: clean-spec
clean-spec: ## Удаление временного файла спеки
	@rm -f $(SPEC_FIXED)

.PHONY: help
help: ## Справка
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0s %s\n", $$1, $$2}'

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
release: generate ## Создание git-тега (требует предварительной генерации)
	@VERSION=$$(jq -r '.info.version' $(SPEC_FIXED)); \
	if git rev-parse "v$$VERSION" >/dev/null 2>&1; then \
		echo "Tag v$$VERSION already exists. Skipping."; \
	else \
		echo "Creating tag v$$VERSION..."; \
		git tag -a "v$$VERSION" -m "Release v$$VERSION"; \
		git push origin "v$$VERSION"; \
	fi

.PHONY: clean-spec
clean-spec: ## Удаление временного файла спеки
	@rm -f $(SPEC_FIXED)

.PHONY: help
help: ## Справка
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0s %s\n", $$1, $$2}'

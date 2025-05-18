DC   			= docker compose
.DEFAULT_GOAL	= help

.PHONY: help
help:
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

### INIT
.PHONY: build
build: ## Build application image
	@$(DC) build

.PHONY: init
init: ## Init application
	@#curl http://localhost:11434/api/pull -d '{"name": "llama3"}'
	@$(DC) exec tts sh -c "git clone https://github.com/coqui-ai/TTS.git ."
	@$(DC) exec tts sh -c "pip install --upgrade pip && pip install Flask && pip install -e ."
#	@$(DC) exec php sh -c 'composer install'
#	@$(DC) exec php sh -c './vendor/bin/rr get-binary -l /app/bin'

.PHONY: up
up: ## Start containers
	@$(DC) up -d

.PHONY: down
down: ## Stop and remove containers
	@$(DC) down

.PHONY: shell
shell: ## Shell in php container
	@$(DC) exec -it php bash

#.PHONY: serve
#serve: ## Start HTTP server
#	@$(DC) exec -it php sh -c "./bin/rr serve -c /app/.rr.dev.yaml"

.PHONY: llm-ping
llm-ping:
	@curl http://localhost:11434/api/tags && echo

.PHONY: llm-request
llm-request:
	curl http://localhost:11434/api/generate -d '{"model": "llama3", "prompt": "Podaj dwa dowolne słowa", "stream": false}' && echo


.PHONY: tts-request
tts-request:
	@curl -X POST http://localhost:8080/transcribe -F "audio_file=@audio/test.wav"
	
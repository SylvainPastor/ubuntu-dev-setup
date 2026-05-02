# Makefile — Test dev-setup in a clean Ubuntu 24.04 container.
#
# Usage:
#   make           # show help
#   make build     # build the Docker image
#   make test      # run full bootstrap.sh in a container
#   make shell     # open a shell inside a container
#   make test-topic TOPIC=03-cpp   # target one topic

IMAGE := dev-setup-test
TAG   := ubuntu-24.04
RUN   := docker run --rm -it $(IMAGE):$(TAG)
SHELLCHECK_IMG := koalaman/shellcheck-alpine:stable

# Topic lists for test-* targets:
#   - 01-shell        : chsh warns inside Docker (no real PAM)
#   - 06-containers   : Docker-in-Docker, install OK but daemon not testable
# These two are excluded from test-embedded.
TOPICS_FAST     := 00-system 03-cpp 05-python
TOPICS_EMBEDDED := 00-system 02-dev-tools 03-cpp 04-embedded 05-python 07-yocto 08-ros2

.DEFAULT_GOAL := help

.PHONY: help build rebuild lint test test-fast test-embedded test-topic test-idempotent shell clean

help:  ## List available targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?##/ \
		{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build:  ## Build the Docker image
	docker build -t $(IMAGE):$(TAG) .

rebuild:  ## Rebuild the image, ignoring cache
	docker build --no-cache -t $(IMAGE):$(TAG) .

lint:  ## Run shellcheck on every script (local if available, otherwise Docker)
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "→ shellcheck (local, $$(shellcheck --version | awk '/^version/ {print $$2}'))"; \
		find . -name '*.sh' -print0 | xargs -0 shellcheck -x; \
	else \
		echo "→ shellcheck via Docker ($(SHELLCHECK_IMG))"; \
		docker run --rm -v "$(CURDIR):/mnt" -w /mnt $(SHELLCHECK_IMG) \
			sh -c 'find . -name "*.sh" -print0 | xargs -0 shellcheck -x'; \
	fi
	@echo "✓ shellcheck OK"

test: build  ## Run full bootstrap.sh (~40 min, all topics)
	$(RUN) ./bootstrap.sh

test-fast: build  ## Quick smoke test (~5 min): 00-system + 03-cpp + 05-python
	$(RUN) ./bootstrap.sh $(TOPICS_FAST)

test-embedded: build  ## Embedded dev profile (~25 min, excludes 01-shell and 06-containers)
	$(RUN) ./bootstrap.sh $(TOPICS_EMBEDDED)

test-topic: build  ## Run a specific topic: make test-topic TOPIC=03-cpp
	@test -n "$(TOPIC)" || { echo "Usage: make test-topic TOPIC=<name>"; exit 1; }
	$(RUN) ./bootstrap.sh $(TOPIC)

test-idempotent: build  ## Run bootstrap.sh twice (idempotency check)
	docker run --rm $(IMAGE):$(TAG) bash -c \
		'./bootstrap.sh 00-system 03-cpp \
		 && echo "════════ 2nd pass ════════" \
		 && ./bootstrap.sh 00-system 03-cpp'

shell: build  ## Open an interactive shell in a container
	$(RUN) bash

clean:  ## Remove the Docker image
	-docker rmi $(IMAGE):$(TAG)

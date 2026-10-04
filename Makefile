.PHONY: docker-img podman-img

NAME = cryptopro

all: docker-img podman-img

docker-img: Dockerfile ## Build Docker container
	docker build -f Dockerfile . -t $(NAME)

docker-run: ## Run Podman container
	RUNNER=docker ./run.sh

podman-img: Dockerfile ## Build Podman container
	podman build -f Dockerfile . -t $(NAME)

podman-run: ## Run Podman container
	RUNNER=podman ./run.sh

help: ## Show this help
	@sed -ne '/@sed/!s/:.*## /:\t/p' $(MAKEFILE_LIST)

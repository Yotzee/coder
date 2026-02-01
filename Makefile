IMAGE_NAME := coder-dev
CONTAINER_NAME := coder-dev
PORT := 8080

.PHONY: build start stop restart shell logs clean bump

## Build the Docker image (uses BuildKit)
build:
	DOCKER_BUILDKIT=1 docker build -t $(IMAGE_NAME) .

## Start the container (web VNC on http://localhost:8080)
start:
	@docker rm -f $(CONTAINER_NAME) 2>/dev/null || true
	docker run --rm -d \
		-p $(PORT):8080 \
		-v $$(pwd):/home/developer/workspace \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$HOME/.claude:/home/developer/.claude \
		-v $$HOME/.config/opencode:/home/developer/.config/opencode \
		--name $(CONTAINER_NAME) \
		$(IMAGE_NAME)
	@echo "Web VNC running at http://localhost:$(PORT)"

## Stop the container
stop:
	docker rm -f $(CONTAINER_NAME)

## Restart (stop + start)
restart: stop start

## Open a shell in the running container
shell:
	docker exec -it $(CONTAINER_NAME) /bin/zsh

## Show container logs
logs:
	docker logs -f $(CONTAINER_NAME)

## Bump patch version (e.g., 1.0.0 → 1.0.1)
bump:
	@VERSION=$$(cat VERSION | tr -d '\n') && \
	MAJOR=$$(echo $$VERSION | cut -d. -f1) && \
	MINOR=$$(echo $$VERSION | cut -d. -f2) && \
	PATCH=$$(echo $$VERSION | cut -d. -f3) && \
	NEW_VERSION="$$MAJOR.$$MINOR.$$((PATCH + 1))" && \
	echo "$$NEW_VERSION" > VERSION && \
	echo "Bumped version: $$VERSION → $$NEW_VERSION"

## Remove image and prune Docker cache
clean:
	docker rm -f $(CONTAINER_NAME) 2>/dev/null || true
	docker rmi $(IMAGE_NAME) 2>/dev/null || true
	docker system prune -f

up:
	docker compose -f $(DOCKER_COMPOSE_FILE) up -d
down: 
	docker compose -f $(DOCKER_COMPOSE_FILE) down
ps:
	docker compose -f $(DOCKER_COMPOSE_FILE) ps
logs:
	docker compose -f $(DOCKER_COMPOSE_FILE) logs -f
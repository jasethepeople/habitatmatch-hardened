.PHONY: setup api web test security bench docker-up docker-down
setup:
	cd api && mix deps.get && mix ecto.setup
api:
	cd api && mix phx.server
web:
	cd web && bun install && bun run dev
test:
	cd api && MIX_ENV=test mix test
	cd web && bun test
security:
	cd api && mix sobelow --config
bench:
	python3 bench/lottery_bench.py

docker-up:
	docker compose up --build

docker-down:
	docker compose down

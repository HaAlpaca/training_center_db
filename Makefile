.PHONY: help up down restart reset logs psql test-triggers dev build install

# Biến cấu hình
DB_CONTAINER = csdl_postgres
DB_USER = admin
DB_NAME = training_db

help:
	@echo =================================================================
	@echo           HE THONG QUAN LY DAO TAO - DANH SACH LENH MAKE
	@echo =================================================================
	@echo   make up             : Khoi chay PostgreSQL va pgAdmin ngam
	@echo   make down           : Dung cac container
	@echo   make restart        : Khoi dong lai cac container
	@echo   make reset          : Xoa toan bo du lieu va nap lai tu dau (reset DB)
	@echo   make logs           : Xem nhat ky log cua PostgreSQL
	@echo   make psql           : Truy cap truc tiep vao giao dien psql shell
	@echo   make test-triggers  : Chay kich ban kiem thu Triggers
	@echo   make install        : Cai dat dependencies cho web frontend
	@echo   make dev            : Chay giao dien Next.js (http://localhost:3000)
	@echo   make build          : Dong goi ung dung Next.js cho production
	@echo =================================================================

# --- DOCKER & DATABASE COMMANDS ---
up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

reset:
	docker compose down -v
	docker compose up -d

logs:
	docker compose logs -f postgres

psql:
	docker exec -it $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME)

test-triggers:
	docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) < tests/test_triggers.sql

# --- FRONTEND (NEXT.JS) COMMANDS ---
install:
	npm --prefix web install

dev:
	npm --prefix web run dev

build:
	npm --prefix web run build

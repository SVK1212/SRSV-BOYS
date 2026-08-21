# Generic Makefile for multiple languages
# Detects common project files and runs sensible defaults for build/test/lint/format/clean

SHELL := /bin/bash

.PHONY: all deps build test lint fmt clean help

all: build

deps:
	@echo "Installing dependencies if detected..."
	@if [ -f package.json ]; then \
		npm install; \
	elif [ -f pyproject.toml ] || [ -f requirements.txt ] || [ -f setup.py ]; then \
		if [ -f requirements.txt ]; then python -m pip install -r requirements.txt; else python -m pip install . || echo "Install your project's dependencies manually"; fi; \
	elif [ -f go.mod ]; then \
		go mod download; \
	elif [ -f Cargo.toml ]; then \
		cargo fetch; \
	else \
		echo "No dependency manifest found."; \
	fi

build:
	@echo "Running build for detected toolchain..."
	@if [ -f package.json ]; then \
		npm run build; \
	elif [ -f pyproject.toml ] || [ -f setup.py ]; then \
		python -m build || echo "Install build backend (pip install build)"; \
	elif [ -f go.mod ]; then \
		go build ./...; \
	elif [ -f Cargo.toml ]; then \
		cargo build --release; \
	else \
		echo "No build step detected."; \
	fi

test:
	@echo "Running tests for detected toolchain..."
	@if [ -f package.json ]; then \
		npm test; \
	elif [ -f pyproject.toml ] || [ -f setup.py ]; then \
		pytest || echo "Install pytest"; \
	elif [ -f go.mod ]; then \
		go test ./...; \
	elif [ -f Cargo.toml ]; then \
		cargo test; \
	else \
		echo "No test step detected."; \
	fi

lint:
	@echo "Running linters (if configured)..."
	@if [ -f package.json ]; then \
		npm run lint || (command -v eslint >/dev/null && eslint .) || echo "No npm lint script or eslint found"; \
	elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then \
		(command -v flake8 >/dev/null && flake8 .) || echo "flake8 not found"; \
	elif [ -f go.mod ]; then \
		(command -v golangci-lint >/dev/null && golangci-lint run) || echo "golangci-lint not found"; \
	elif [ -f Cargo.toml ]; then \
		(command -v cargo >/dev/null && cargo fmt -- --check) || echo "rustfmt/cargo not found"; \
	else \
		echo "No linter configured."; \
	fi

fmt:
	@echo "Formatting code (if formatter available)..."
	@if [ -f package.json ]; then \
		npm run format || (command -v prettier >/dev/null && prettier --write .) || echo "No npm format script or prettier found"; \
	elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then \
		(command -v black >/dev/null && black .) || echo "black not found"; \
	elif [ -f go.mod ]; then \
		gofmt -w .; \
	elif [ -f Cargo.toml ]; then \
		cargo fmt; \
	else \
		echo "No formatter configured."; \
	fi

clean:
	@echo "Cleaning common build artifacts..."
	@rm -rf node_modules dist build target *.egg-info .pytest_cache || true
	@find . -name '__pycache__' -type d -print0 | xargs -0 rm -rf || true
	@git clean -fdX || true

help:
	@printf "Usage:\n"
	@printf "  make [target]\n\n"
	@printf "Targets:\n"
	@printf "  all (default)  - alias for build\n"
	@printf "  deps           - install dependencies (npm/pip/go/cargo)\n"
	@printf "  build          - build the project if a build system is detected\n"
	@printf "  test           - run tests\n"
	@printf "  lint           - run linters\n"
	@printf "  fmt            - format code\n"
	@printf "  clean          - remove build artifacts\n"
	@printf "  help           - show this help\n"

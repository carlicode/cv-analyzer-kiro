.PHONY: help install install-dev run test lint format clean docker-build docker-run deploy-railway deploy-aws deploy-aws-full sam-build sam-deploy aws-logs aws-status aws-cleanup

help:
	@echo "Comandos disponibles:"
	@echo "  make install       - Instalar dependencias de producción"
	@echo "  make install-dev   - Instalar dependencias de desarrollo"
	@echo "  make run           - Ejecutar servidor de desarrollo"
	@echo "  make test          - Ejecutar tests"
	@echo "  make lint          - Ejecutar linter"
	@echo "  make format        - Formatear código"
	@echo "  make clean         - Limpiar archivos temporales"
	@echo "  make docker-build  - Construir imagen Docker"
	@echo "  make docker-run    - Ejecutar con Docker Compose"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy-railway    - Desplegar a Railway"
	@echo "  make deploy-aws-full   - Deploy completo a AWS (Lambda + S3)"
	@echo "  make deploy-aws        - Deploy solo Lambda (manual)"
	@echo "  make sam-build         - Build con AWS SAM"
	@echo "  make sam-deploy        - Deploy con AWS SAM"
	@echo ""
	@echo "AWS Management:"
	@echo "  make aws-logs          - Ver logs de Lambda"
	@echo "  make aws-status        - Ver estado del stack"
	@echo "  make aws-cleanup       - Eliminar recursos de AWS"

install:
	pip install -r requirements.txt

install-dev:
	pip install -r requirements-dev.txt

run:
	uvicorn main:app --reload --host 0.0.0.0 --port 8000

test:
	pytest

test-cov:
	pytest --cov=. --cov-report=html --cov-report=term

lint:
	flake8 . --exclude=venv,env,.venv --max-line-length=120
	mypy . --ignore-missing-imports

format:
	black . --exclude='/(\.git|\.venv|venv|env|__pycache__)/'
	isort . --skip-glob='**/venv/*' --skip-glob='**/.venv/*'

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	rm -rf htmlcov .coverage

docker-build:
	docker build -t cv-analyzer:latest .

docker-run:
	docker-compose up

docker-stop:
	docker-compose down

# Deployment commands
deploy-railway:
	@echo "🚀 Desplegando a Railway..."
	./deploy-railway.sh

deploy-aws-full:
	@echo "🚀 Desplegando a AWS (Lambda + S3)..."
	./deploy-aws.sh

deploy-aws:
	@echo "🚀 Desplegando solo Lambda..."
	@make sam-build
	@make sam-deploy

sam-build:
	@echo "📦 Building con AWS SAM..."
	sam build

sam-deploy:
	@echo "🚀 Deploying con AWS SAM..."
	sam deploy

# AWS Management commands
aws-logs:
	@echo "📋 Mostrando logs de Lambda..."
	sam logs -n CVAnalyzerFunction --tail

aws-status:
	@echo "📊 Estado del stack..."
	@aws cloudformation describe-stacks \
		--stack-name cv-analyzer-stack \
		--query 'Stacks[0].{Status:StackStatus,Outputs:Outputs}' \
		--output table

aws-cleanup:
	@echo "🗑️  Eliminando recursos de AWS..."
	./cleanup-aws.sh

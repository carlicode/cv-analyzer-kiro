#!/bin/bash
# Script para desplegar a AWS Lambda usando SAM

set -e

echo "🚀 Desplegando CV Analyzer a AWS Lambda..."
echo ""

# Verificar que SAM CLI esté instalado
if ! command -v sam &> /dev/null; then
    echo "❌ Error: AWS SAM CLI no está instalado"
    echo ""
    echo "Instala SAM CLI:"
    echo "  macOS: brew install aws-sam-cli"
    echo "  Linux: pip install aws-sam-cli"
    echo "  Docs: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    exit 1
fi

# Verificar que AWS CLI esté configurado
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ Error: AWS CLI no está configurado"
    echo ""
    echo "Configura AWS CLI:"
    echo "  aws configure"
    exit 1
fi

echo "✓ AWS SAM CLI instalado"
echo "✓ AWS CLI configurado"
echo ""

# Build
echo "📦 Building application..."
sam build --use-container

# Deploy
echo ""
echo "🚀 Deploying to AWS..."
sam deploy --guided

echo ""
echo "✅ Deployment completado!"
echo ""
echo "📋 Próximos pasos:"
echo "  1. Copia la URL del API Gateway del output"
echo "  2. Prueba el endpoint: curl <API_URL>"
echo "  3. Analiza un CV: python scripts/test_endpoint.py tu_cv.pdf <API_URL>"
echo ""

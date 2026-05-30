#!/bin/bash

# Script de Deploy Automático a AWS Lambda
# Autor: @Carli.Code
# Demo: GDG Santa Cruz · Women Techmakers · UCB Bolivia

set -e  # Exit on error

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                              ║"
echo "║                    🚀 CV Analyzer - Deploy a AWS Lambda                     ║"
echo "║                                                                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# 1. Verificar herramientas
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Verificando herramientas necesarias..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI no está instalado"
    echo "Instala con: brew install awscli"
    exit 1
fi
print_success "AWS CLI instalado"

# Verificar SAM CLI
if ! command -v sam &> /dev/null; then
    print_error "SAM CLI no está instalado"
    echo "Instala con: brew install aws-sam-cli"
    exit 1
fi
print_success "SAM CLI instalado"

# Verificar Docker
if ! docker ps &> /dev/null; then
    print_error "Docker no está corriendo"
    echo "Inicia Docker Desktop y vuelve a ejecutar este script"
    exit 1
fi
print_success "Docker está corriendo"

# Verificar credenciales AWS
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS CLI no está configurado"
    echo "Configura con: aws configure"
    exit 1
fi
print_success "AWS CLI configurado"

echo ""

# 2. Verificar acceso a Bedrock
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 Verificando acceso a AWS Bedrock..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if aws bedrock list-foundation-models --region us-east-1 &> /dev/null; then
    print_success "Acceso a Bedrock confirmado"
else
    print_warning "No se pudo verificar acceso a Bedrock"
    print_info "Asegúrate de tener permisos para bedrock:ListFoundationModels"
fi

echo ""

# 3. Build
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 Building aplicación con SAM..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "Esto puede tomar 3-5 minutos..."

if sam build --use-container; then
    print_success "Build completado exitosamente"
else
    print_error "Error en el build"
    exit 1
fi

echo ""

# 4. Deploy
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Deploying a AWS Lambda..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "Esto puede tomar 5-7 minutos..."

# Verificar si existe samconfig.toml
if [ -f "samconfig.toml" ]; then
    print_info "Usando configuración existente (samconfig.toml)"
    if sam deploy; then
        print_success "Deploy completado exitosamente"
    else
        print_error "Error en el deploy"
        exit 1
    fi
else
    print_info "Primera vez deploying, usando modo guiado"
    if sam deploy --guided; then
        print_success "Deploy completado exitosamente"
    else
        print_error "Error en el deploy"
        exit 1
    fi
fi

echo ""

# 5. Obtener outputs
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Información del Deploy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Obtener URL de la API
API_URL=$(aws cloudformation describe-stacks \
    --stack-name cv-analyzer-stack \
    --query 'Stacks[0].Outputs[?OutputKey==`CVAnalyzerApi`].OutputValue' \
    --output text 2>/dev/null || echo "")

if [ -n "$API_URL" ]; then
    print_success "API URL: $API_URL"
    echo ""
    
    # 6. Verificar health check
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 Verificando API..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    sleep 5  # Esperar a que la API esté lista
    
    if curl -s "$API_URL" | grep -q "ok"; then
        print_success "API funcionando correctamente"
    else
        print_warning "API deployada pero health check falló"
        print_info "Puede tomar unos minutos en estar completamente lista"
    fi
else
    print_warning "No se pudo obtener la URL de la API"
    print_info "Verifica en AWS Console: https://console.aws.amazon.com/lambda/"
fi

echo ""

# 7. Resumen final
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Deploy Completado"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "Tu API está en producción!"
echo ""
echo "📝 Próximos pasos:"
echo ""
echo "1. Probar la API:"
echo "   curl $API_URL"
echo ""
echo "2. Ver documentación interactiva:"
echo "   open ${API_URL}docs"
echo ""
echo "3. Probar análisis de CV:"
echo "   python scripts/test_endpoint.py tu_cv.pdf $API_URL"
echo ""
echo "4. Ver logs en tiempo real:"
echo "   sam logs -n CVAnalyzerFunction --tail"
echo ""
echo "5. Ver métricas en AWS Console:"
echo "   https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions/cv-analyzer-api"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_info "Guarda esta URL: $API_URL"
echo ""


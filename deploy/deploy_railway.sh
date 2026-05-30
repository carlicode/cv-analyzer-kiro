#!/bin/bash
# Script para desplegar a Railway

set -e

echo "🚀 Desplegando CV Analyzer a Railway..."
echo ""

# Verificar que Railway CLI esté instalado
if ! command -v railway &> /dev/null; then
    echo "❌ Error: Railway CLI no está instalado"
    echo ""
    echo "Instala Railway CLI:"
    echo "  npm install -g @railway/cli"
    echo "  O visita: https://docs.railway.app/develop/cli"
    exit 1
fi

echo "✓ Railway CLI instalado"
echo ""

# Login (si no está logueado)
echo "🔐 Verificando autenticación..."
if ! railway whoami &> /dev/null; then
    echo "Necesitas hacer login en Railway:"
    railway login
fi

echo "✓ Autenticado en Railway"
echo ""

# Inicializar proyecto (si no existe)
if [ ! -f ".railway" ]; then
    echo "📦 Inicializando proyecto Railway..."
    railway init
fi

# Configurar variables de entorno
echo ""
echo "⚙️  Configurando variables de entorno..."
echo ""
echo "Necesitas configurar las siguientes variables en Railway:"
echo "  - AWS_REGION"
echo "  - AWS_ACCESS_KEY_ID"
echo "  - AWS_SECRET_ACCESS_KEY"
echo ""
read -p "¿Quieres configurarlas ahora? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "AWS_REGION (default: us-east-1): " aws_region
    aws_region=${aws_region:-us-east-1}
    railway variables set AWS_REGION="$aws_region"
    
    read -p "AWS_ACCESS_KEY_ID: " aws_key
    railway variables set AWS_ACCESS_KEY_ID="$aws_key"
    
    read -sp "AWS_SECRET_ACCESS_KEY: " aws_secret
    echo
    railway variables set AWS_SECRET_ACCESS_KEY="$aws_secret"
    
    echo "✓ Variables configuradas"
fi

# Deploy
echo ""
echo "🚀 Desplegando a Railway..."
railway up

echo ""
echo "✅ Deployment completado!"
echo ""
echo "📋 Próximos pasos:"
echo "  1. Obtén la URL: railway domain"
echo "  2. Prueba el endpoint: curl <RAILWAY_URL>"
echo "  3. Analiza un CV: python scripts/test_endpoint.py tu_cv.pdf <RAILWAY_URL>"
echo ""

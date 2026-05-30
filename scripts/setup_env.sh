#!/bin/bash
# Script para configurar el entorno de desarrollo

echo "🚀 Configurando entorno de desarrollo para CV Analyzer..."

# Crear entorno virtual si no existe
if [ ! -d "venv" ]; then
    echo "📦 Creando entorno virtual..."
    python3 -m venv venv
fi

# Activar entorno virtual
echo "🔌 Activando entorno virtual..."
source venv/bin/activate

# Instalar dependencias
echo "📥 Instalando dependencias..."
pip install --upgrade pip
pip install -r requirements-dev.txt

# Crear archivo .env si no existe
if [ ! -f ".env" ]; then
    echo "📝 Creando archivo .env desde .env.example..."
    cp .env.example .env
    echo "⚠️  IMPORTANTE: Edita el archivo .env con tus credenciales de AWS"
fi

echo ""
echo "✅ Entorno configurado correctamente!"
echo ""
echo "📋 Próximos pasos:"
echo "  1. Edita el archivo .env con tus credenciales de AWS"
echo "  2. Activa el entorno virtual: source venv/bin/activate"
echo "  3. Ejecuta el servidor: python main.py"
echo "  4. Prueba el API: python scripts/test_endpoint.py tu_cv.pdf"
echo ""

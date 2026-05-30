# Quick Start Guide 🚀

Guía rápida para poner en marcha el CV Analyzer en menos de 5 minutos.

## Prerrequisitos

- Python 3.11+
- Cuenta AWS con acceso a Bedrock
- Git

## Paso 1: Clonar y Setup

```bash
# Clonar el repositorio
git clone https://github.com/carlicode/cv-analyzer-kiro.git
cd cv-analyzer-kiro

# Cambiar a la rama con el código
git checkout 2-project-structure

# Ejecutar setup automático
./scripts/setup_env.sh
```

## Paso 2: Configurar AWS

Edita el archivo `.env` con tus credenciales:

```bash
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=tu_access_key_aqui
AWS_SECRET_ACCESS_KEY=tu_secret_key_aqui
```

### ¿Cómo obtener credenciales AWS?

1. Ve a [AWS Console](https://console.aws.amazon.com/)
2. IAM → Users → Tu usuario → Security credentials
3. Create access key → Command Line Interface (CLI)
4. Copia Access Key ID y Secret Access Key

### Habilitar Bedrock

1. Ve a [AWS Bedrock Console](https://console.aws.amazon.com/bedrock/)
2. Model access → Manage model access
3. Habilita "Claude 3.5 Sonnet v2"
4. Save changes

## Paso 3: Ejecutar

```bash
# Activar entorno virtual
source venv/bin/activate

# Iniciar servidor
python main.py
```

El servidor estará en `http://localhost:8000`

## Paso 4: Probar

### Opción A: Con el script de prueba

```bash
python scripts/test_endpoint.py tu_cv.pdf
```

### Opción B: Con curl

```bash
curl -X POST "http://localhost:8000/analyze" \
  -F "file=@tu_cv.pdf" \
  -F "language=es"
```

### Opción C: Swagger UI

Abre en tu navegador: http://localhost:8000/docs

## Troubleshooting

### Error: "AWS authentication failed"

- Verifica que las credenciales en `.env` sean correctas
- Asegúrate de que el usuario IAM tenga permisos para Bedrock

### Error: "Model access denied"

- Ve a AWS Bedrock Console
- Habilita el modelo Claude 3.5 Sonnet v2

### Error: "No module named 'fitz'"

```bash
pip install PyMuPDF
```

### Error: "File too large"

El límite es 5MB. Puedes cambiarlo en `.env`:

```bash
MAX_FILE_SIZE_MB=10
```

## Comandos Útiles

```bash
# Ver logs del servidor
python main.py

# Ejecutar tests
pytest

# Ver documentación
open http://localhost:8000/docs

# Limpiar archivos temporales
make clean

# Formatear código
make format
```

## Próximos Pasos

1. ✅ Servidor funcionando
2. 📖 Lee [ARCHITECTURE.md](ARCHITECTURE.md) para entender la arquitectura
3. 🧪 Ejecuta los tests: `pytest`
4. 🚀 Deploy a producción (ver [SETUP.md](SETUP.md))
5. 🎨 Crea un frontend simple

## Recursos

- [Documentación FastAPI](https://fastapi.tiangolo.com/)
- [AWS Bedrock Docs](https://docs.aws.amazon.com/bedrock/)
- [PyMuPDF Docs](https://pymupdf.readthedocs.io/)

## ¿Necesitas ayuda?

Abre un issue en el repositorio o contacta a @Carli.Code

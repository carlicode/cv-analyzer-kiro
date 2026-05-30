# Rama 3-deploy - Información 🚀

## ✨ Archivos de Deployment Agregados

Esta rama contiene toda la configuración necesaria para desplegar el CV Analyzer en producción.

### 📁 Estructura de Archivos de Deploy

```
cv-analyzer-kiro/
├── 🔧 Configuración AWS Lambda
│   ├── lambda_handler.py          # Handler para AWS Lambda
│   ├── template.yaml              # SAM template (CloudFormation)
│   ├── samconfig.toml             # Configuración SAM
│   └── requirements-lambda.txt    # Dependencias para Lambda
│
├── 🚂 Configuración Railway
│   ├── railway.json               # Configuración Railway
│   ├── railway.toml               # Configuración alternativa
│   └── Procfile                   # Comando de inicio
│
├── 📜 Scripts de Deploy
│   ├── deploy/deploy_aws.sh       # Script para AWS Lambda
│   └── deploy/deploy_railway.sh   # Script para Railway
│
└── 📖 Documentación
    ├── DEPLOYMENT.md              # Guía completa de deployment
    ├── DEPLOY_QUICK.md            # Guía rápida (10 min)
    └── DEPLOY_INFO.md             # Este archivo
```

## 🎯 Opciones de Deployment

### 1. AWS Lambda (Recomendado para Producción)

**Ventajas:**
- ✅ Acceso directo a Bedrock con IAM roles
- ✅ Escalado automático
- ✅ Pay-per-use (~$5-10/mes para 1000 análisis)
- ✅ Alta disponibilidad

**Archivos:**
- `lambda_handler.py` - Adaptador Mangum para FastAPI
- `template.yaml` - Infraestructura como código (SAM)
- `samconfig.toml` - Configuración del deployment

**Deploy:**
```bash
make sam-build
make sam-deploy
```

### 2. Railway (Ideal para Demos)

**Ventajas:**
- ✅ Deploy extremadamente simple
- ✅ CI/CD automático desde GitHub
- ✅ Logs en tiempo real
- ✅ Ideal para MVPs

**Archivos:**
- `railway.json` - Configuración Railway
- `railway.toml` - Configuración alternativa
- `Procfile` - Comando de inicio

**Deploy:**
```bash
make deploy-railway
```

## 🔧 Componentes Técnicos

### Lambda Handler (`lambda_handler.py`)

```python
from mangum import Mangum
from main import app

handler = Mangum(app, lifespan="off")
```

**¿Qué hace?**
- Adapta FastAPI para funcionar en AWS Lambda
- Convierte eventos de API Gateway a requests HTTP
- Maneja el ciclo de vida de la aplicación

### SAM Template (`template.yaml`)

Define la infraestructura:
- Lambda Function (512MB, 30s timeout)
- API Gateway (REST API)
- IAM Role con permisos para Bedrock
- Outputs (URLs y ARNs)

### Railway Config (`railway.json`)

Define el deployment:
- Builder: NIXPACKS (detecta Python automáticamente)
- Start command: `uvicorn main:app`
- Health check: `/`
- Restart policy: ON_FAILURE

## 📊 Comparación de Opciones

| Característica | AWS Lambda | Railway |
|----------------|------------|---------|
| **Setup** | Medio | Muy fácil |
| **Costo** | Pay-per-use | $5-20/mes |
| **Escalado** | Automático | Manual |
| **Bedrock** | Directo (IAM) | Requiere credentials |
| **CI/CD** | Manual/GitHub Actions | Automático |
| **Logs** | CloudWatch | Dashboard |
| **Ideal para** | Producción | Demos/MVPs |

## 🚀 Quick Start

### AWS Lambda

```bash
# 1. Instalar SAM CLI
brew install aws-sam-cli

# 2. Configurar AWS
aws configure

# 3. Deploy
sam build --use-container
sam deploy --guided
```

### Railway

```bash
# 1. Instalar Railway CLI
npm install -g @railway/cli

# 2. Deploy
railway login
railway init
railway up

# 3. Configurar variables
railway variables set AWS_REGION=us-east-1
railway variables set AWS_ACCESS_KEY_ID=tu_key
railway variables set AWS_SECRET_ACCESS_KEY=tu_secret
```

## 🔐 Variables de Entorno

### AWS Lambda

Las variables se configuran en `template.yaml`:

```yaml
Environment:
  Variables:
    AWS_REGION: !Ref AWS::Region  # Automático
    MAX_FILE_SIZE_MB: 5
    ALLOWED_EXTENSIONS: pdf,txt
    DEFAULT_LANGUAGE: es
```

**Nota:** No necesitas configurar credenciales AWS porque Lambda usa IAM roles.

### Railway

Configura en el dashboard o CLI:

```bash
railway variables set AWS_REGION=us-east-1
railway variables set AWS_ACCESS_KEY_ID=tu_key
railway variables set AWS_SECRET_ACCESS_KEY=tu_secret
railway variables set MAX_FILE_SIZE_MB=5
railway variables set ALLOWED_EXTENSIONS=pdf,txt
railway variables set DEFAULT_LANGUAGE=es
```

## 📝 Comandos del Makefile

```bash
# Deployment
make deploy-railway    # Deploy a Railway
make deploy-aws        # Deploy a AWS Lambda
make sam-build         # Build con SAM
make sam-deploy        # Deploy con SAM

# Desarrollo (de rama anterior)
make install          # Instalar dependencias
make run              # Ejecutar servidor local
make test             # Ejecutar tests
make docker-build     # Build Docker
make docker-run       # Run con Docker
```

## 🧪 Testing Post-Deploy

### 1. Health Check

```bash
curl https://tu-api-url/
```

Respuesta esperada:
```json
{
  "status": "ok",
  "service": "CV Analyzer API",
  "version": "1.0.0"
}
```

### 2. Análisis de CV

```bash
python scripts/test_endpoint.py tu_cv.pdf https://tu-api-url
```

### 3. Swagger UI

Abre en el navegador:
```
https://tu-api-url/docs
```

## 🐛 Troubleshooting Común

### AWS Lambda

**Error: "Model access denied"**
- Solución: Habilita Claude 3.5 Sonnet en AWS Bedrock Console

**Error: "Timeout"**
- Solución: Aumenta timeout en `template.yaml` (default: 30s)

**Error: "File too large"**
- Solución: Lambda tiene límite de 6MB. Usa Railway o S3.

### Railway

**Error: "Build failed"**
- Solución: Verifica que `requirements.txt` esté en la raíz

**Error: "AWS authentication failed"**
- Solución: Verifica las variables de entorno AWS

**Error: "Port binding"**
- Solución: Railway asigna el puerto automáticamente vía `$PORT`

## 📊 Monitoreo

### AWS Lambda

```bash
# Logs en tiempo real
sam logs -n CVAnalyzerFunction --tail

# Métricas
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=cv-analyzer-api
```

### Railway

- Dashboard: https://railway.app/dashboard
- Logs en tiempo real
- Métricas de CPU, memoria, requests

## 💰 Costos Estimados

### AWS Lambda (1000 análisis/mes)

- Lambda: $0.20
- API Gateway: $3.50
- Bedrock: $5-10
- **Total: ~$10/mes**

### Railway

- Starter: $5/mes (500 horas)
- Developer: $20/mes (ilimitado)
- Bedrock: $5-10
- **Total: ~$15-30/mes**

## 🎯 Recomendaciones

### Para Demos y MVPs
→ **Railway** (setup en 5 minutos)

### Para Producción
→ **AWS Lambda** (mejor integración, más escalable)

### Para Desarrollo Local
→ Usa `make run` (sin deploy)

## 📚 Documentación Adicional

- **DEPLOYMENT.md** - Guía completa paso a paso
- **DEPLOY_QUICK.md** - Guía rápida (10 minutos)
- **ARCHITECTURE.md** - Arquitectura del sistema
- **QUICKSTART.md** - Setup local

## ✅ Checklist de Deploy

- [ ] Código funcionando localmente
- [ ] Tests pasando
- [ ] Variables de entorno configuradas
- [ ] AWS Bedrock habilitado (si usas AWS)
- [ ] Credenciales AWS configuradas
- [ ] Deploy ejecutado exitosamente
- [ ] Health check funcionando
- [ ] Análisis de CV funcionando
- [ ] Logs monitoreados
- [ ] URL documentada

## 🎉 Resultado

Con esta rama tienes:

✅ Configuración completa para AWS Lambda  
✅ Configuración completa para Railway  
✅ Scripts de deployment automatizados  
✅ Documentación exhaustiva  
✅ Comandos Make para facilitar el deploy  
✅ Guías rápidas y completas  

**¡Tu API está lista para producción!** 🚀

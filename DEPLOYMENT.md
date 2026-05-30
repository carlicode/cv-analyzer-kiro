# Guía de Deployment 🚀

Esta guía te ayudará a desplegar el CV Analyzer en producción. Hay dos opciones principales:

1. **AWS Lambda** (Recomendado) - Acceso directo a Bedrock, escalado automático
2. **Railway** - Deploy simple, ideal para demos

## 📋 Tabla de Contenidos

- [Opción 1: AWS Lambda](#opción-1-aws-lambda-recomendado)
- [Opción 2: Railway](#opción-2-railway)
- [Verificación Post-Deploy](#verificación-post-deploy)
- [Troubleshooting](#troubleshooting)

---

## Opción 1: AWS Lambda (Recomendado)

### ✅ Ventajas

- ✓ Acceso directo a Bedrock con IAM roles (sin configurar credenciales)
- ✓ Escalado automático
- ✓ Pay-per-use (solo pagas por requests)
- ✓ Alta disponibilidad
- ✓ Integración nativa con AWS

### 📦 Prerrequisitos

1. **AWS CLI** instalado y configurado
2. **AWS SAM CLI** instalado
3. **Docker** instalado (para build)
4. **Permisos IAM** para crear Lambda, API Gateway, y usar Bedrock

### 🔧 Instalación de Herramientas

#### macOS

```bash
# AWS CLI
brew install awscli

# SAM CLI
brew install aws-sam-cli

# Docker
brew install --cask docker
```

#### Linux

```bash
# AWS CLI
pip install awscli

# SAM CLI
pip install aws-sam-cli
```

#### Windows

Descarga los instaladores desde:
- AWS CLI: https://aws.amazon.com/cli/
- SAM CLI: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html

### ⚙️ Configuración AWS

```bash
# Configurar credenciales
aws configure

# Verificar configuración
aws sts get-caller-identity
```

### 🚀 Deployment

#### Opción A: Script Automático

```bash
./deploy/deploy_aws.sh
```

#### Opción B: Manual

```bash
# 1. Build
sam build --use-container

# 2. Deploy (primera vez)
sam deploy --guided

# 3. Deploy (siguientes veces)
sam deploy
```

### 📝 Configuración del Deploy

Durante `sam deploy --guided`, configura:

```
Stack Name: cv-analyzer-stack
AWS Region: us-east-1
Confirm changes before deploy: Y
Allow SAM CLI IAM role creation: Y
Save arguments to configuration file: Y
```

### 🔐 Permisos IAM

El template SAM crea automáticamente un rol con permisos para:
- `bedrock:InvokeModel` en Claude 3.5 Sonnet

Si necesitas permisos adicionales, edita `template.yaml`.

### 📊 Outputs

Después del deploy, obtendrás:

```
Outputs:
  CVAnalyzerApi: https://xxxxx.execute-api.us-east-1.amazonaws.com/Prod/
  CVAnalyzerFunction: arn:aws:lambda:us-east-1:xxxxx:function:cv-analyzer-api
```

### 💰 Costos Estimados

- **Lambda**: ~$0.20 por millón de requests
- **API Gateway**: ~$3.50 por millón de requests
- **Bedrock**: ~$0.003 por 1K tokens input, ~$0.015 por 1K tokens output
- **Total estimado**: ~$5-10/mes para 1000 análisis

---

## Opción 2: Railway

### ✅ Ventajas

- ✓ Deploy extremadamente simple
- ✓ CI/CD automático desde GitHub
- ✓ Logs en tiempo real
- ✓ Ideal para demos y MVPs

### ⚠️ Desventajas

- ✗ Requiere configurar credenciales AWS manualmente
- ✗ Menos escalable que Lambda
- ✗ Costo fijo mensual

### 📦 Prerrequisitos

1. Cuenta en [Railway.app](https://railway.app)
2. Railway CLI instalado (opcional)
3. Credenciales AWS

### 🔧 Instalación Railway CLI

```bash
npm install -g @railway/cli
```

### 🚀 Deployment

#### Opción A: Desde GitHub (Recomendado)

1. **Push tu código a GitHub**

```bash
git push origin 3-deploy
```

2. **Conectar con Railway**

- Ve a [railway.app](https://railway.app)
- Click en "New Project"
- Selecciona "Deploy from GitHub repo"
- Selecciona tu repositorio
- Railway detectará automáticamente la configuración

3. **Configurar Variables de Entorno**

En el dashboard de Railway, agrega:

```
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=tu_access_key
AWS_SECRET_ACCESS_KEY=tu_secret_key
MAX_FILE_SIZE_MB=5
ALLOWED_EXTENSIONS=pdf,txt
DEFAULT_LANGUAGE=es
```

4. **Deploy**

Railway desplegará automáticamente. Obtendrás una URL como:
```
https://cv-analyzer-production.up.railway.app
```

#### Opción B: Railway CLI

```bash
# Login
railway login

# Inicializar proyecto
railway init

# Configurar variables
railway variables set AWS_REGION=us-east-1
railway variables set AWS_ACCESS_KEY_ID=tu_key
railway variables set AWS_SECRET_ACCESS_KEY=tu_secret

# Deploy
railway up
```

#### Opción C: Script Automático

```bash
./deploy/deploy_railway.sh
```

### 💰 Costos Estimados

- **Starter Plan**: $5/mes (500 horas de ejecución)
- **Developer Plan**: $20/mes (uso ilimitado)

---

## Verificación Post-Deploy

### 1. Health Check

```bash
# AWS Lambda
curl https://xxxxx.execute-api.us-east-1.amazonaws.com/Prod/

# Railway
curl https://cv-analyzer-production.up.railway.app/
```

**Respuesta esperada:**
```json
{
  "status": "ok",
  "service": "CV Analyzer API",
  "version": "1.0.0"
}
```

### 2. Probar Análisis de CV

```bash
# Con el script de prueba
python scripts/test_endpoint.py tu_cv.pdf https://tu-api-url

# Con curl
curl -X POST "https://tu-api-url/analyze" \
  -F "file=@tu_cv.pdf" \
  -F "language=es"
```

### 3. Verificar Logs

#### AWS Lambda

```bash
# Ver logs
sam logs -n CVAnalyzerFunction --tail

# O en AWS Console
# CloudWatch → Log Groups → /aws/lambda/cv-analyzer-api
```

#### Railway

```bash
# CLI
railway logs

# O en el dashboard de Railway
```

---

## Troubleshooting

### Error: "AWS authentication failed"

**Causa:** Credenciales AWS incorrectas o sin permisos

**Solución:**

```bash
# Verificar credenciales
aws sts get-caller-identity

# Reconfigurar
aws configure
```

### Error: "Model access denied"

**Causa:** No tienes acceso a Claude 3.5 Sonnet en Bedrock

**Solución:**

1. Ve a [AWS Bedrock Console](https://console.aws.amazon.com/bedrock/)
2. Model access → Manage model access
3. Habilita "Claude 3.5 Sonnet v2"
4. Save changes

### Error: "File too large" en Lambda

**Causa:** Lambda tiene límite de 6MB para requests

**Solución:**

Opción 1: Usar S3 para archivos grandes
Opción 2: Aumentar límite en API Gateway (hasta 10MB)
Opción 3: Usar Railway en lugar de Lambda

### Error: "Timeout" en Lambda

**Causa:** El análisis tarda más de 30s

**Solución:**

Edita `template.yaml`:

```yaml
Globals:
  Function:
    Timeout: 60  # Aumentar a 60s
```

Redeploy:

```bash
sam build && sam deploy
```

### Error: "Module not found" en Lambda

**Causa:** Dependencias no incluidas en el build

**Solución:**

```bash
# Rebuild con container
sam build --use-container

# Redeploy
sam deploy
```

### Railway: Build Failed

**Causa:** Dependencias de sistema faltantes

**Solución:**

Railway usa Nixpacks que detecta automáticamente las dependencias. Si falla:

1. Verifica que `requirements.txt` esté en la raíz
2. Verifica que no haya errores de sintaxis en Python
3. Revisa los logs de build en Railway

---

## Monitoreo y Mantenimiento

### AWS Lambda

```bash
# Ver métricas
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=cv-analyzer-api \
  --start-time 2026-05-29T00:00:00Z \
  --end-time 2026-05-30T00:00:00Z \
  --period 3600 \
  --statistics Sum

# Ver logs en tiempo real
sam logs -n CVAnalyzerFunction --tail
```

### Railway

- Dashboard: https://railway.app/dashboard
- Logs en tiempo real
- Métricas de CPU, memoria, requests

---

## CI/CD

### GitHub Actions para AWS

Crea `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS Lambda

on:
  push:
    branches: [main, 3-deploy]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: aws-actions/setup-sam@v2
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - run: sam build --use-container
      - run: sam deploy --no-confirm-changeset --no-fail-on-empty-changeset
```

### Railway

Railway tiene CI/CD automático desde GitHub. Cada push a la rama configurada despliega automáticamente.

---

## Rollback

### AWS Lambda

```bash
# Listar versiones
aws lambda list-versions-by-function --function-name cv-analyzer-api

# Rollback a versión anterior
aws lambda update-alias \
  --function-name cv-analyzer-api \
  --name prod \
  --function-version <VERSION_NUMBER>
```

### Railway

En el dashboard de Railway:
1. Deployments
2. Selecciona un deployment anterior
3. Click en "Redeploy"

---

## Próximos Pasos

1. ✅ Deploy exitoso
2. 🔒 Configurar dominio personalizado
3. 📊 Configurar monitoreo (CloudWatch/Railway)
4. 🔐 Agregar autenticación (API Keys)
5. 🚀 Configurar CI/CD
6. 📈 Implementar rate limiting
7. 💾 Agregar caché con Redis

---

## Recursos

- [AWS SAM Docs](https://docs.aws.amazon.com/serverless-application-model/)
- [Railway Docs](https://docs.railway.app/)
- [AWS Bedrock Pricing](https://aws.amazon.com/bedrock/pricing/)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)

---

**¿Necesitas ayuda?** Abre un issue en el repositorio o contacta a @Carli.Code

# 🚀 Pasos para Deploy a AWS Lambda - Rama 4

## ✅ Cambios Realizados

1. **Actualizado modelo de IA:**
   - ❌ Claude 3.5 Sonnet (no disponible)
   - ✅ **Claude Sonnet 4.6** (más reciente y potente)

2. **Archivos actualizados:**
   - `config.py` - Modelo actualizado
   - `skills/analyze_cv.py` - Modelo actualizado
   - `template.yaml` - Permisos IAM actualizados

3. **Herramientas instaladas:**
   - ✅ AWS SAM CLI v1.161.0
   - ✅ AWS CLI configurado
   - ✅ Docker instalado (necesita iniciarse)

## 📋 Pasos para Deploy

### 1. Iniciar Docker

```bash
# Abre Docker Desktop desde Applications
# O desde terminal:
open -a Docker
```

Espera a que Docker esté completamente iniciado (ícono en la barra superior).

### 2. Build con SAM

```bash
cd "/Users/carli.code/Desktop/Kiro MVPs/cv-analyzer-kiro"
sam build --use-container
```

Este comando:
- Crea un contenedor Docker
- Instala todas las dependencias
- Empaqueta la aplicación para Lambda

**Tiempo estimado:** 3-5 minutos

### 3. Deploy a AWS

```bash
sam deploy --guided
```

Responde las preguntas:

```
Stack Name [cv-analyzer-stack]: cv-analyzer-stack
AWS Region [us-east-1]: us-east-1
Confirm changes before deploy [Y/n]: Y
Allow SAM CLI IAM role creation [Y/n]: Y
Disable rollback [y/N]: N
CVAnalyzerFunction has no authentication. Is this okay? [y/N]: y
Save arguments to configuration file [Y/n]: Y
SAM configuration file [samconfig.toml]: samconfig.toml
SAM configuration environment [default]: default
```

**Tiempo estimado:** 5-7 minutos

### 4. Obtener URL de la API

Después del deploy, verás algo como:

```
Outputs:
  CVAnalyzerApi: https://xxxxx.execute-api.us-east-1.amazonaws.com/Prod/
  CVAnalyzerFunction: arn:aws:lambda:us-east-1:447924811196:function:cv-analyzer-api
```

**Guarda esa URL!** Es tu API en producción.

### 5. Verificar que funciona

```bash
# Health check
curl https://xxxxx.execute-api.us-east-1.amazonaws.com/Prod/

# Debería responder:
# {"status":"ok","service":"CV Analyzer API","version":"1.0.0"}
```

### 6. Probar con un CV

```bash
# Usando el script de prueba
python scripts/test_endpoint.py tu_cv.pdf https://xxxxx.execute-api.us-east-1.amazonaws.com/Prod/

# O con curl
curl -X POST "https://xxxxx.execute-api.us-east-1.amazonaws.com/Prod/analyze" \
  -F "file=@tu_cv.pdf" \
  -F "language=es"
```

## 🎯 Comandos Rápidos (Make)

También puedes usar los comandos del Makefile:

```bash
# Build
make sam-build

# Deploy
make sam-deploy

# Ver logs
make sam-logs
```

## 🔍 Troubleshooting

### Error: "Docker not running"

```bash
# Inicia Docker Desktop
open -a Docker

# Espera 30 segundos y verifica
docker ps
```

### Error: "Model access denied"

Necesitas habilitar Claude Sonnet 4.6 en Bedrock:

1. Ve a: https://console.aws.amazon.com/bedrock/
2. Click en "Model access" (menú izquierdo)
3. Click en "Manage model access"
4. Busca "Claude Sonnet 4.6"
5. Marca el checkbox
6. Click en "Save changes"
7. Espera 2-3 minutos para que se active

### Error: "Stack already exists"

Si ya deployaste antes:

```bash
# Actualizar stack existente
sam deploy
```

### Ver logs en tiempo real

```bash
sam logs -n CVAnalyzerFunction --tail
```

## 💰 Costos Estimados

Para 1000 análisis de CV al mes:

- **Lambda:** $0.20 (invocaciones)
- **API Gateway:** $3.50 (requests)
- **Bedrock (Claude Sonnet 4.6):** ~$8-12 (tokens)
- **Total:** ~$12-16/mes

**Free Tier AWS:**
- Lambda: 1M requests gratis/mes
- API Gateway: 1M requests gratis/mes (primer año)

## 📊 Monitoreo

### Ver métricas en AWS Console

1. Ve a: https://console.aws.amazon.com/lambda/
2. Busca: `cv-analyzer-api`
3. Tab "Monitor" → Ver invocaciones, errores, duración

### Ver logs en CloudWatch

1. Ve a: https://console.aws.amazon.com/cloudwatch/
2. Log groups → `/aws/lambda/cv-analyzer-api`
3. Ver logs en tiempo real

## 🔄 Actualizar el Deploy

Cuando hagas cambios en el código:

```bash
# 1. Rebuild
sam build --use-container

# 2. Redeploy (sin --guided)
sam deploy

# 3. Verificar
curl https://tu-api-url/
```

## 🎉 Resultado Final

Después del deploy tendrás:

✅ API REST en producción  
✅ URL pública accesible  
✅ Escalado automático  
✅ Integración con Claude Sonnet 4.6  
✅ Logs en CloudWatch  
✅ Métricas en tiempo real  

## 📝 Próximos Pasos

1. ✅ Deploy exitoso
2. 🔒 Agregar autenticación (API Keys)
3. 🌐 Configurar dominio personalizado
4. 📊 Dashboard de monitoreo
5. 🚀 CI/CD con GitHub Actions
6. 💾 Caché con Redis/DynamoDB

---

**Creado por:** @Carli.Code  
**Demo:** GDG Santa Cruz · Women Techmakers · UCB Bolivia  
**Charla:** "Zero to Hero: MVPs Hyper-Fast con Kiro y Python"  
**Modelo:** Claude Sonnet 4.6 (AWS Bedrock)


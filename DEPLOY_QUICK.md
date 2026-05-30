# Deploy Rápido ⚡

Guía ultra-rápida para desplegar en menos de 10 minutos.

## 🎯 Opción 1: Railway (Más Fácil)

### 1. Instalar Railway CLI

```bash
npm install -g @railway/cli
```

### 2. Deploy

```bash
railway login
railway init
railway up
```

### 3. Configurar Variables

```bash
railway variables set AWS_REGION=us-east-1
railway variables set AWS_ACCESS_KEY_ID=tu_key
railway variables set AWS_SECRET_ACCESS_KEY=tu_secret
```

### 4. Obtener URL

```bash
railway domain
```

**¡Listo!** Tu API está en: `https://cv-analyzer-production.up.railway.app`

---

## 🎯 Opción 2: AWS Lambda (Recomendado para Producción)

### 1. Instalar SAM CLI

```bash
# macOS
brew install aws-sam-cli

# Linux
pip install aws-sam-cli
```

### 2. Configurar AWS

```bash
aws configure
```

### 3. Deploy

```bash
sam build --use-container
sam deploy --guided
```

Responde las preguntas:
- Stack Name: `cv-analyzer-stack`
- Region: `us-east-1`
- Confirm changes: `Y`
- Allow IAM role creation: `Y`

**¡Listo!** Tu API está en la URL que aparece en los Outputs.

---

## ✅ Verificar

```bash
# Health check
curl https://tu-api-url/

# Probar análisis
python scripts/test_endpoint.py tu_cv.pdf https://tu-api-url
```

---

## 🐛 Problemas Comunes

### "AWS authentication failed"

```bash
aws configure
# Ingresa tus credenciales
```

### "Model access denied"

1. Ve a https://console.aws.amazon.com/bedrock/
2. Model access → Manage model access
3. Habilita "Claude 3.5 Sonnet v2"

### Railway: "Build failed"

Verifica que `requirements.txt` esté en la raíz del proyecto.

---

## 📚 Más Info

Ver [DEPLOYMENT.md](DEPLOYMENT.md) para guía completa.

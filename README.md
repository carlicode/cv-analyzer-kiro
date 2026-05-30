# CV Analyzer Kiro 🤖⚡

> Demo de la charla "Zero to Hero: MVPs Hyper-Fast con Kiro y Python"
> por @Carli.Code — GDG Santa Cruz · Women Techmakers · UCB Bolivia

## ¿Qué construimos?

Un bot que analiza CVs y devuelve feedback instantáneo con IA.

Flujo: Formulario → Python → IA → Respuesta

Stack: Python + Kiro + AWS

## Ramas

| Rama | Qué hace |
|------|----------|
| main | README, visión general |
| 1-kiro-setup | Specs, Skills y Agents |
| 2-project-structure | ✅ Estructura completa del proyecto Python |
| 3-deploy | ✅ Configuración de deployment (AWS Lambda + Railway) |

## Empieza aquí

```bash
git clone https://github.com/carlicode/cv-analyzer-kiro.git
cd cv-analyzer-kiro

# Para desarrollo local
git checkout 2-project-structure

# Para deployment
git checkout 3-deploy
```

## 🚀 Deploy Rápido

### Railway (Más Fácil)

```bash
npm install -g @railway/cli
railway login
railway init
railway up
```

### AWS Lambda (Recomendado)

```bash
brew install aws-sam-cli
aws configure
sam build --use-container
sam deploy --guided
```

Ver [DEPLOY_QUICK.md](DEPLOY_QUICK.md) para guía rápida o [DEPLOYMENT.md](DEPLOYMENT.md) para guía completa.

> "Esto es un MVP. Esto es suficiente para empezar."

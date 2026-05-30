# Rama 1 — Kiro Setup 🧠

En esta rama definimos todo el proyecto dentro de .kiro/ antes de escribir una sola línea de código.

## Estructura

```
.kiro/
├── specs/cv-analyzer.md   ← QUÉ construir
├── skills/analyze-cv.md   ← CÓMO ejecutar
└── agents/cv-agent.md     ← QUIÉN orquesta
```

## Pasos en Kiro

1. Abre el proyecto en Kiro
2. Lee specs/ — entiende el problema
3. Lee skills/ — entiende cómo ejecutar el análisis
4. Lee agents/ — entiende el flujo completo
5. Escribe en el chat de Kiro:

"Based on .kiro/ specs, skills and agents, generate the complete FastAPI CV Analyzer Bot"

Kiro generará: app/main.py, app/analyzer.py, requirements.txt, .env.example

## Siguiente

```bash
git checkout 2-python-ia
```

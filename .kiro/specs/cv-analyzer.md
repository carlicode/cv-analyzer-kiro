# Spec: CV Analyzer Bot

## Objetivo

Bot que recibe un CV en PDF, lo procesa con Python y devuelve feedback con IA.

## Usuarios

- Personas buscando trabajo
- Estudiantes con su primer CV
- Profesionales actualizando perfil

## Requerimientos funcionales

### RF-01 Subida de archivo

- Acepta .pdf o .txt
- Tamaño máximo: 5MB

### RF-02 Extracción de texto

- Extrae texto completo del PDF con PyMuPDF

### RF-03 Análisis con IA

- Envía texto a Claude API
- Evalúa: claridad, habilidades, puntos fuertes, áreas de mejora, puntuación 1-10

### RF-04 Respuesta

- Feedback estructurado en menos de 10 segundos

## Stack

- Python 3.11+
- FastAPI
- PyMuPDF
- Anthropic Claude API
- Deploy: Railway o AWS Lambda

## Flujo

Usuario sube PDF → Validar → Extraer texto → Prompt → IA → Feedback

## Criterios de aceptación

- [ ] Feedback en menos de 10s
- [ ] Mínimo 4 secciones en el feedback
- [ ] Errores con mensajes claros
- [ ] Deploy con 1 comando

## Fuera de alcance

- Autenticación
- Historial
- Multi-idioma

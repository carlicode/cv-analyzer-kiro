# TalentScope AI - Frontend

Professional SaaS-style frontend for CV Analyzer powered by AI.

## 🎨 Design Features

### Branding
- **Brand Name**: TalentScope AI
- **Tagline**: Professional CV Analysis Powered by AI
- **Color Scheme**:
  - Primary Blue: `#0066FF`
  - Accent Green: `#00D9A3`
  - Dark: `#1A1A2E`
  - White: `#FFFFFF`

### UI/UX Components

#### Landing Page
- Hero section with clear value proposition
- Feature cards with icons (4 key features)
- How it works section (3-step visual process)
- Prominent CTA buttons
- Professional footer with links and social media

#### Analyzer Application
- Elegant drag & drop zone for CV upload (PDF/TXT)
- Language selector (English/Spanish)
- Progress indicator during analysis
- Results dashboard with:
  - Visual score display (circular gauge)
  - Clarity score with progress bar
  - Strengths cards (with check icons)
  - Improvements cards (with suggestion icons)
  - Highlighted summary section
- Smooth animations and micro-interactions
- Dark mode toggle

## 🛠️ Technology Stack

- **HTML5**: Semantic markup
- **CSS3**: Modern styling with CSS Grid and Flexbox
- **JavaScript**: Vanilla JS (no framework dependencies)
- **Icons**: Feather Icons
- **Fonts**: Inter (Google Fonts)
- **Design**: Mobile-first responsive design

## 📁 File Structure

```
frontend/
├── index.html          # Main HTML file (landing + app)
├── styles.css          # Complete styling
├── app.js             # Application logic
├── assets/
│   └── logo.svg       # TalentScope AI logo
└── README.md          # This file
```

## 🚀 Getting Started

### Local Development

1. **Serve the frontend**:
   ```bash
   # Using Python
   cd frontend
   python -m http.server 8080
   
   # Or using Node.js
   npx serve
   ```

2. **Access the application**:
   Open `http://localhost:8080` in your browser

3. **Backend connection**:
   - For local development, ensure the backend is running on `http://localhost:8000`
   - The frontend will automatically detect localhost and use the correct endpoint

### Production Deployment

The frontend is a static site and can be deployed to:
- **AWS S3 + CloudFront**
- **Netlify**
- **Vercel**
- **Railway** (with the backend)

## 🔌 API Integration

### Endpoint
```
POST /analyze
```

### Request
```javascript
FormData {
  file: File (PDF or TXT, max 10MB),
  language: 'en' | 'es'
}
```

### Response
```json
{
  "success": true,
  "data": {
    "score": 85,
    "clarity_score": 90,
    "strengths": ["Clear structure", "Strong experience"],
    "improvements": ["Add more metrics", "Improve formatting"],
    "summary": "Overall strong CV with clear presentation..."
  },
  "timestamp": "2024-01-01T12:00:00Z",
  "processing_time_ms": 1500
}
```

## ✨ Features

### User Experience
- ✅ Drag & drop file upload
- ✅ File validation (type and size)
- ✅ Real-time progress indication
- ✅ Animated score displays
- ✅ Responsive design (mobile, tablet, desktop)
- ✅ Dark mode support
- ✅ Smooth scroll navigation
- ✅ Error handling with user-friendly messages

### Accessibility
- ✅ Semantic HTML
- ✅ ARIA labels
- ✅ Keyboard navigation
- ✅ High contrast colors
- ✅ Readable font sizes

## 🎯 Design Inspiration

The design follows modern SaaS principles inspired by:
- **Grammarly**: Clean, focused interface
- **Notion**: Elegant typography and spacing
- **Linear**: Smooth animations and micro-interactions

## 🌐 Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## 📱 Responsive Breakpoints

- Mobile: < 768px
- Tablet: 768px - 1024px
- Desktop: > 1024px

## 🎨 Customization

### Colors
Edit CSS variables in `styles.css`:
```css
:root {
    --primary: #0066FF;
    --accent: #00D9A3;
    --dark: #1A1A2E;
    /* ... */
}
```

### Fonts
Change the Google Fonts import in `index.html`:
```html
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
```

## 📄 License

Part of the CV Analyzer project.

# TalentScope AI - Frontend Deployment Guide

## 🚀 Deployment Options

### Option 1: Deploy with Backend (Railway/AWS)

#### Railway (Recommended for Full Stack)

1. **Update `railway.toml`** (already configured):
   ```toml
   [build]
   builder = "NIXPACKS"
   
   [deploy]
   startCommand = "uvicorn main:app --host 0.0.0.0 --port $PORT"
   
   [staticFiles]
   path = "frontend"
   ```

2. **Deploy**:
   ```bash
   # Railway will automatically serve static files from /frontend
   railway up
   ```

3. **Access**:
   - Backend API: `https://your-app.railway.app/analyze`
   - Frontend: `https://your-app.railway.app/` (serves index.html)

#### AWS Lambda + S3

1. **Deploy Backend** (Lambda):
   ```bash
   sam build
   sam deploy --guided
   ```

2. **Deploy Frontend** (S3 + CloudFront):
   ```bash
   # Create S3 bucket
   aws s3 mb s3://talentscope-ai-frontend
   
   # Upload files
   aws s3 sync frontend/ s3://talentscope-ai-frontend/ \
     --exclude ".git/*" \
     --exclude "*.md"
   
   # Make public
   aws s3 website s3://talentscope-ai-frontend/ \
     --index-document index.html
   ```

3. **Update API endpoint in app.js**:
   ```javascript
   const API_ENDPOINT = 'https://your-api-gateway-url.amazonaws.com/analyze';
   ```

### Option 2: Static Hosting (Frontend Only)

#### Netlify

1. **Install Netlify CLI**:
   ```bash
   npm install -g netlify-cli
   ```

2. **Deploy**:
   ```bash
   cd frontend
   netlify deploy --prod --dir .
   ```

3. **Configure**:
   - Add environment variable for API endpoint
   - Enable CORS on backend

#### Vercel

1. **Install Vercel CLI**:
   ```bash
   npm install -g vercel
   ```

2. **Deploy**:
   ```bash
   cd frontend
   vercel --prod
   ```

3. **Configure**:
   ```json
   {
     "version": 2,
     "builds": [
       {
         "src": "index.html",
         "use": "@vercel/static"
       }
     ]
   }
   ```

#### GitHub Pages

1. **Create `gh-pages` branch**:
   ```bash
   git checkout -b gh-pages
   git push origin gh-pages
   ```

2. **Enable in GitHub Settings**:
   - Go to repository Settings > Pages
   - Select `gh-pages` branch
   - Select `/frontend` folder

3. **Access**:
   - `https://username.github.io/cv-analyzer-kiro/`

### Option 3: Docker Container

1. **Create Dockerfile** (in project root):
   ```dockerfile
   FROM python:3.11-slim
   
   WORKDIR /app
   
   # Install dependencies
   COPY requirements.txt .
   RUN pip install --no-cache-dir -r requirements.txt
   
   # Copy application
   COPY . .
   
   # Expose port
   EXPOSE 8000
   
   # Start server (serves both API and static files)
   CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
   ```

2. **Update main.py to serve static files**:
   ```python
   from fastapi.staticfiles import StaticFiles
   
   app.mount("/", StaticFiles(directory="frontend", html=True), name="frontend")
   ```

3. **Build and run**:
   ```bash
   docker build -t talentscope-ai .
   docker run -p 8000:8000 talentscope-ai
   ```

## 🔧 Configuration

### Environment Variables

Create `.env` file:
```env
# Backend
OPENAI_API_KEY=your_key_here
AWS_BEDROCK_REGION=us-east-1
MAX_FILE_SIZE_MB=10
ALLOWED_EXTENSIONS=pdf,txt

# Frontend (if using build process)
VITE_API_ENDPOINT=https://your-api.com/analyze
```

### CORS Configuration

Ensure backend allows frontend origin:

```python
# main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8080",
        "https://your-frontend-domain.com"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### API Endpoint Configuration

Update `frontend/app.js`:

```javascript
// For production
const API_ENDPOINT = 'https://your-api-domain.com/analyze';

// For development
const API_ENDPOINT = window.location.hostname === 'localhost' 
    ? 'http://localhost:8000/analyze'
    : 'https://your-api-domain.com/analyze';
```

## 📊 Performance Optimization

### 1. Minify Assets

```bash
# Install minification tools
npm install -g html-minifier clean-css-cli uglify-js

# Minify HTML
html-minifier --collapse-whitespace --remove-comments \
  frontend/index.html -o frontend/index.min.html

# Minify CSS
cleancss -o frontend/styles.min.css frontend/styles.css

# Minify JS
uglifyjs frontend/app.js -o frontend/app.min.js -c -m
```

### 2. Enable Compression

For Nginx:
```nginx
gzip on;
gzip_types text/css application/javascript image/svg+xml;
gzip_min_length 1000;
```

For Apache:
```apache
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/css application/javascript
</IfModule>
```

### 3. CDN Configuration

Use CloudFlare or AWS CloudFront:
- Cache static assets (CSS, JS, images)
- Enable HTTP/2
- Enable Brotli compression

## 🔒 Security

### Content Security Policy

Add to `index.html`:
```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               script-src 'self' https://unpkg.com; 
               style-src 'self' https://fonts.googleapis.com; 
               font-src https://fonts.gstatic.com;">
```

### HTTPS

Always use HTTPS in production:
- Let's Encrypt (free SSL)
- CloudFlare SSL
- AWS Certificate Manager

## 📈 Monitoring

### Analytics

Add Google Analytics or Plausible:
```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

### Error Tracking

Add Sentry:
```html
<script src="https://browser.sentry-cdn.com/7.x.x/bundle.min.js"></script>
<script>
  Sentry.init({ dsn: 'YOUR_DSN' });
</script>
```

## ✅ Pre-Deployment Checklist

- [ ] Test all features locally
- [ ] Verify API endpoint configuration
- [ ] Enable CORS on backend
- [ ] Test file upload (PDF and TXT)
- [ ] Test both languages (EN/ES)
- [ ] Test dark mode
- [ ] Test responsive design (mobile, tablet, desktop)
- [ ] Verify error handling
- [ ] Check browser compatibility
- [ ] Optimize images and assets
- [ ] Enable HTTPS
- [ ] Configure CSP headers
- [ ] Set up monitoring
- [ ] Test production build

## 🐛 Troubleshooting

### CORS Errors
```
Access to fetch at 'API_URL' from origin 'FRONTEND_URL' has been blocked by CORS policy
```
**Solution**: Add frontend URL to backend CORS allowed origins

### File Upload Fails
```
413 Payload Too Large
```
**Solution**: Increase max file size in backend and reverse proxy (Nginx/Apache)

### API Not Found
```
404 Not Found
```
**Solution**: Verify API endpoint URL in `app.js` matches backend deployment

### Dark Mode Not Persisting
**Solution**: Check localStorage is enabled in browser

## 📞 Support

For issues or questions:
- Check backend logs
- Verify network requests in browser DevTools
- Review CORS configuration
- Test API endpoint directly with curl/Postman

## 🎉 Success!

Once deployed, your TalentScope AI frontend will be live and ready to analyze CVs!

Access your application at your deployment URL and start analyzing CVs with AI-powered insights.

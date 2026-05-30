# 🚀 TalentScope AI - Quick Start Guide

## ⚡ Test Locally in 2 Minutes

### Step 1: Start Backend
```bash
# Terminal 1 - Backend
python main.py
```
Backend will run on `http://localhost:8000`

### Step 2: Start Frontend
```bash
# Terminal 2 - Frontend
cd frontend
./start-local.sh
```
Frontend will run on `http://localhost:8080`

### Step 3: Open Browser
Open `http://localhost:8080` in your browser

### Step 4: Test the App
1. Click "Try it Free" or scroll to analyzer
2. Select language (English or Spanish)
3. Drag & drop a CV (PDF or TXT) or click to browse
4. Click "Analyze CV"
5. View results with scores, strengths, and improvements

## 🎯 What You'll See

### Landing Page
- **Hero Section**: Value proposition with animated badge
- **Features**: 4 cards explaining key features
- **How It Works**: 3-step process visualization
- **Analyzer**: Upload and analyze interface
- **Footer**: Professional footer with links

### Analyzer Interface
- **Upload Zone**: Drag & drop or click to browse
- **Language Selector**: Choose English or Spanish
- **File Validation**: Automatic type and size checking
- **Loading State**: Animated progress indicator
- **Results Dashboard**:
  - Overall score (circular gauge)
  - Clarity score (progress bar)
  - Summary section
  - Strengths cards (green)
  - Improvements cards (teal)

### Dark Mode
- Click the moon/sun icon in the navbar
- Theme persists across sessions

## 📝 Test Files

Create test CVs or use existing ones:

### Sample CV (TXT)
```txt
John Doe
Software Engineer

Experience:
- Senior Developer at Tech Corp (2020-2024)
- Built scalable microservices with Python and FastAPI
- Led team of 5 developers
- Improved system performance by 40%

Skills:
Python, FastAPI, Docker, AWS, React

Education:
BS Computer Science, MIT (2016-2020)
```

Save as `test-cv.txt` and upload.

## 🔧 Troubleshooting

### Backend Not Starting
```bash
# Install dependencies
pip install -r requirements.txt

# Check if port 8000 is available
lsof -i :8000

# Set environment variables
export OPENAI_API_KEY=your_key_here
# or
export AWS_BEDROCK_REGION=us-east-1
```

### Frontend Not Loading
```bash
# Try alternative server
cd frontend
python3 -m http.server 8080
# or
npx serve -p 8080
```

### CORS Errors
- Make sure backend is running on port 8000
- Check browser console for errors
- Verify CORS is enabled in `main.py`

### File Upload Fails
- Check file size (max 10MB)
- Verify file type (PDF or TXT only)
- Check backend logs for errors

## 🌐 Deploy to Production

### Option 1: Railway (Easiest)
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Deploy
railway up
```

### Option 2: Docker
```bash
# Build
docker build -t talentscope-ai .

# Run
docker run -p 8000:8000 \
  -e OPENAI_API_KEY=your_key \
  talentscope-ai
```

### Option 3: AWS
```bash
# Deploy backend (Lambda)
sam build && sam deploy --guided

# Deploy frontend (S3)
aws s3 sync frontend/ s3://your-bucket/
```

See `frontend/DEPLOYMENT.md` for detailed instructions.

## 📊 Features to Test

### ✅ Core Features
- [ ] File upload (drag & drop)
- [ ] File upload (click to browse)
- [ ] Language selection (EN/ES)
- [ ] File validation (type)
- [ ] File validation (size)
- [ ] Loading animation
- [ ] Results display
- [ ] Score animations
- [ ] Strengths cards
- [ ] Improvements cards
- [ ] Summary section
- [ ] "Analyze Another" button

### ✅ UI/UX Features
- [ ] Dark mode toggle
- [ ] Smooth scrolling
- [ ] Hover effects
- [ ] Button animations
- [ ] Responsive design (resize browser)
- [ ] Mobile view (DevTools)
- [ ] Error messages
- [ ] Loading states

### ✅ Navigation
- [ ] "Try it Free" button (hero)
- [ ] "Learn More" button (hero)
- [ ] Scroll to features
- [ ] Scroll to analyzer
- [ ] Footer links
- [ ] Logo click (refresh)

## 🎨 Customization

### Change Colors
Edit `frontend/styles.css`:
```css
:root {
    --primary: #0066FF;      /* Your brand color */
    --accent: #00D9A3;       /* Accent color */
    --dark: #1A1A2E;         /* Text color */
}
```

### Change API Endpoint
Edit `frontend/app.js`:
```javascript
const API_ENDPOINT = 'https://your-api.com/analyze';
```

### Change Branding
1. Replace `frontend/assets/logo.svg`
2. Update title in `frontend/index.html`
3. Update tagline and copy

## 📱 Mobile Testing

### Using Browser DevTools
1. Open DevTools (F12)
2. Click device toolbar icon (Ctrl+Shift+M)
3. Select device (iPhone, iPad, etc.)
4. Test all features

### Using Real Device
1. Find your local IP: `ifconfig` or `ipconfig`
2. Start frontend on `0.0.0.0:8080`
3. Access from phone: `http://YOUR_IP:8080`

## 🐛 Common Issues

### "Failed to analyze CV"
- Check backend is running
- Verify API endpoint in `app.js`
- Check backend logs for errors
- Ensure API key is set

### "Invalid file type"
- Only PDF and TXT are supported
- Check file extension
- Try different file

### "File too large"
- Max size is 10MB
- Compress PDF or reduce content
- Check backend MAX_FILE_SIZE setting

### Dark mode not working
- Check browser localStorage is enabled
- Clear browser cache
- Try different browser

## 📞 Need Help?

1. Check browser console (F12)
2. Check backend logs
3. Review `FRONTEND_SUMMARY.md`
4. Review `frontend/DEPLOYMENT.md`
5. Check GitHub issues

## 🎉 Success!

If you can:
- ✅ Upload a CV
- ✅ See loading animation
- ✅ View results with scores
- ✅ Toggle dark mode
- ✅ Use on mobile

**Congratulations! TalentScope AI is working perfectly!** 🚀

Now you're ready to deploy to production and start analyzing CVs with AI-powered insights.

---

**Next Steps:**
1. Deploy to Railway/AWS/Netlify
2. Add custom domain
3. Set up analytics
4. Share with users
5. Collect feedback
6. Iterate and improve

**Happy analyzing!** 🎯

// ===================================
// TalentScope AI - Frontend Application
// ===================================

// Configuration
// DEPLOY_API_URL is replaced by deploy-aws.sh with the real API Gateway URL
const API_ENDPOINT = window.location.hostname === 'localhost'
    ? 'http://localhost:8000/analyze'
    : 'DEPLOY_API_URL/analyze';

// State Management
const state = {
    selectedFile: null,
    selectedLanguage: 'en',
    isAnalyzing: false,
    currentView: 'upload'
};

// DOM Elements
const elements = {
    // Views
    uploadView: document.getElementById('uploadView'),
    loadingView: document.getElementById('loadingView'),
    resultsView: document.getElementById('resultsView'),
    errorView: document.getElementById('errorView'),
    
    // Upload elements
    dropzone: document.getElementById('dropzone'),
    fileInput: document.getElementById('fileInput'),
    fileInfo: document.getElementById('fileInfo'),
    fileName: document.getElementById('fileName'),
    fileSize: document.getElementById('fileSize'),
    removeFile: document.getElementById('removeFile'),
    analyzeBtn: document.getElementById('analyzeBtn'),
    
    // Loading elements
    progressFill: document.getElementById('progressFill'),
    
    // Results elements
    overallScore: document.getElementById('overallScore'),
    clarityScore: document.getElementById('clarityScore'),
    scoreCircle: document.getElementById('scoreCircle'),
    clarityBar: document.getElementById('clarityBar'),
    summaryText: document.getElementById('summaryText'),
    strengthsGrid: document.getElementById('strengthsGrid'),
    improvementsGrid: document.getElementById('improvementsGrid'),
    analyzeAnother: document.getElementById('analyzeAnother'),
    
    // Error elements
    errorMessage: document.getElementById('errorMessage'),
    tryAgain: document.getElementById('tryAgain'),
    
    // Theme toggle
    themeToggle: document.getElementById('themeToggle')
};

// ===================================
// Initialization
// ===================================
function init() {
    setupEventListeners();
    setupTheme();
    feather.replace();
}

// ===================================
// Event Listeners
// ===================================
function setupEventListeners() {
    // Dropzone events
    if (elements.dropzone && elements.fileInput) {
        elements.dropzone.addEventListener('click', () => elements.fileInput.click());
        elements.dropzone.addEventListener('dragover', handleDragOver);
        elements.dropzone.addEventListener('dragleave', handleDragLeave);
        elements.dropzone.addEventListener('drop', handleDrop);
    }

    // File input
    if (elements.fileInput) {
        elements.fileInput.addEventListener('change', handleFileSelect);
    }

    // Remove file
    if (elements.removeFile) {
        elements.removeFile.addEventListener('click', clearFile);
    }

    // Language selection
    document.querySelectorAll('input[name="language"]').forEach(radio => {
        radio.addEventListener('change', (e) => {
            state.selectedLanguage = e.target.value;
        });
    });

    // Analyze button
    if (elements.analyzeBtn) {
        elements.analyzeBtn.addEventListener('click', analyzeCV);
    }

    // Analyze another
    if (elements.analyzeAnother) {
        elements.analyzeAnother.addEventListener('click', resetToUpload);
    }

    // Try again
    if (elements.tryAgain) {
        elements.tryAgain.addEventListener('click', resetToUpload);
    }

    // Theme toggle
    if (elements.themeToggle) {
        elements.themeToggle.addEventListener('click', toggleTheme);
    }
}

// ===================================
// Theme Management
// ===================================
function setupTheme() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    document.documentElement.setAttribute('data-theme', savedTheme);
    updateThemeIcon(savedTheme);
}

function toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';

    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    updateThemeIcon(newTheme);
}

function updateThemeIcon(theme) {
    if (!elements.themeToggle) return;
    const icon = elements.themeToggle.querySelector('i');
    if (icon) {
        icon.setAttribute('data-feather', theme === 'light' ? 'moon' : 'sun');
        feather.replace();
    }
}

// ===================================
// File Handling
// ===================================
function handleDragOver(e) {
    e.preventDefault();
    elements.dropzone.classList.add('dragover');
}

function handleDragLeave(e) {
    e.preventDefault();
    elements.dropzone.classList.remove('dragover');
}

function handleDrop(e) {
    e.preventDefault();
    elements.dropzone.classList.remove('dragover');
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        handleFile(files[0]);
    }
}

function handleFileSelect(e) {
    const files = e.target.files;
    if (files.length > 0) {
        handleFile(files[0]);
    }
}

function handleFile(file) {
    // Validate file type
    const validTypes = ['application/pdf', 'text/plain'];
    if (!validTypes.includes(file.type)) {
        showError('Invalid file type. Please upload a PDF or TXT file.');
        return;
    }
    
    // Validate file size (10MB max)
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
        showError('File is too large. Maximum size is 10MB.');
        return;
    }
    
    // Store file and update UI
    state.selectedFile = file;
    displayFileInfo(file);
    elements.analyzeBtn.disabled = false;
}

function displayFileInfo(file) {
    elements.fileName.textContent = file.name;
    elements.fileSize.textContent = formatFileSize(file.size);
    elements.fileInfo.style.display = 'flex';
    elements.dropzone.style.display = 'none';
}

function clearFile() {
    state.selectedFile = null;
    elements.fileInput.value = '';
    elements.fileInfo.style.display = 'none';
    elements.dropzone.style.display = 'block';
    elements.analyzeBtn.disabled = true;
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

// ===================================
// View Management
// ===================================
function showView(viewName) {
    elements.uploadView.style.display = 'none';
    elements.loadingView.style.display = 'none';
    elements.resultsView.style.display = 'none';
    elements.errorView.style.display = 'none';
    
    switch(viewName) {
        case 'upload':
            elements.uploadView.style.display = 'block';
            break;
        case 'loading':
            elements.loadingView.style.display = 'block';
            break;
        case 'results':
            elements.resultsView.style.display = 'block';
            break;
        case 'error':
            elements.errorView.style.display = 'block';
            break;
    }
    
    state.currentView = viewName;
    feather.replace();
}

function resetToUpload() {
    clearFile();
    showView('upload');
}

// ===================================
// API Communication
// ===================================
async function analyzeCV() {
    if (!state.selectedFile || state.isAnalyzing) return;
    
    state.isAnalyzing = true;
    showView('loading');
    
    try {
        const formData = new FormData();
        formData.append('file', state.selectedFile);
        formData.append('language', state.selectedLanguage);
        
        const response = await fetch(API_ENDPOINT, {
            method: 'POST',
            body: formData
        });
        
        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            const detail = errorData.detail;
            const message = typeof detail === 'string'
                ? detail
                : (detail?.error || detail?.message || `Server error: ${response.status}`);
            throw new Error(message);
        }
        
        const result = await response.json();
        
        // Handle API response structure
        const data = result.data || result;
        displayResults(data);
        
    } catch (error) {
        console.error('Analysis error:', error);
        showError(error.message || 'Failed to analyze CV. Please try again.');
    } finally {
        state.isAnalyzing = false;
    }
}

// ===================================
// Results Display
// ===================================
function displayResults(data) {
    // Display scores
    const overallScore = Math.round(data.score || data.overall_score || 0);
    const clarityScore = Math.round(data.clarity_score || 0);
    
    elements.overallScore.textContent = overallScore;
    elements.clarityScore.textContent = clarityScore;
    
    // Animate score circle
    animateScoreCircle(overallScore);
    
    // Animate clarity bar
    elements.clarityBar.style.width = `${clarityScore}%`;
    
    // Display summary
    elements.summaryText.textContent = data.summary || 'No summary available.';
    
    // Display strengths
    displayInsights(data.strengths || [], elements.strengthsGrid, 'strength');
    
    // Display improvements
    displayInsights(data.improvements || [], elements.improvementsGrid, 'improvement');
    
    // Show results view
    showView('results');
    
    // Scroll to results
    setTimeout(() => {
        elements.resultsView.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 100);
}

function animateScoreCircle(score) {
    const circumference = 2 * Math.PI * 54; // radius = 54
    const offset = circumference - (score / 100) * circumference;
    
    // Add gradient definition if not exists
    if (!document.querySelector('#scoreGradient')) {
        const svg = elements.scoreCircle.closest('svg');
        const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
        const gradient = document.createElementNS('http://www.w3.org/2000/svg', 'linearGradient');
        gradient.setAttribute('id', 'scoreGradient');
        gradient.innerHTML = `
            <stop offset="0%" stop-color="#0066FF" />
            <stop offset="100%" stop-color="#00D9A3" />
        `;
        defs.appendChild(gradient);
        svg.insertBefore(defs, svg.firstChild);
    }
    
    setTimeout(() => {
        elements.scoreCircle.style.strokeDashoffset = offset;
    }, 100);
}

function displayInsights(insights, container, type) {
    container.innerHTML = '';
    
    if (insights.length === 0) {
        container.innerHTML = `
            <p style="color: var(--gray); text-align: center; padding: var(--spacing-md);">
                No ${type}s identified.
            </p>
        `;
        return;
    }
    
    insights.forEach(insight => {
        const card = document.createElement('div');
        card.className = `insight-card ${type}`;
        card.innerHTML = `
            <div class="insight-icon">
                <i data-feather="${type === 'strength' ? 'check' : 'alert-circle'}"></i>
            </div>
            <div class="insight-text">${escapeHtml(insight)}</div>
        `;
        container.appendChild(card);
    });
    
    feather.replace();
}

// ===================================
// Error Handling
// ===================================
function showError(message) {
    elements.errorMessage.textContent = message;
    showView('error');
}

// ===================================
// Utility Functions
// ===================================
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function scrollToAnalyzer() {
    document.getElementById('analyzer').scrollIntoView({ 
        behavior: 'smooth',
        block: 'start'
    });
}

function scrollToFeatures() {
    document.getElementById('features').scrollIntoView({ 
        behavior: 'smooth',
        block: 'start'
    });
}

// ===================================
// Initialize on DOM Ready
// ===================================
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}

// Export functions for inline onclick handlers
window.scrollToAnalyzer = scrollToAnalyzer;
window.scrollToFeatures = scrollToFeatures;

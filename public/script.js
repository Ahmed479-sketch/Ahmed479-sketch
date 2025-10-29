class DiaryApp {
    constructor() {
        this.entries = [];
        this.currentEditId = null;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.populateMonthSelector();
        this.loadEntries();
    }

    setupEventListeners() {
        // Modal controls
        document.getElementById('newEntryBtn').addEventListener('click', () => this.openModal());
        document.querySelector('.close').addEventListener('click', () => this.closeModal());
        document.getElementById('cancelBtn').addEventListener('click', () => this.closeModal());
        
        // Form submission
        document.getElementById('entryForm').addEventListener('submit', (e) => this.handleSubmit(e));
        
        // Month selector
        document.getElementById('monthSelect').addEventListener('change', (e) => this.filterByMonth(e.target.value));
        
        // Close modal when clicking outside
        window.addEventListener('click', (e) => {
            const modal = document.getElementById('entryModal');
            if (e.target === modal) {
                this.closeModal();
            }
        });
    }

    populateMonthSelector() {
        const select = document.getElementById('monthSelect');
        const currentDate = new Date();
        
        // Add current and previous 11 months
        for (let i = 0; i < 12; i++) {
            const date = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1);
            const option = document.createElement('option');
            option.value = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
            option.textContent = date.toLocaleDateString('en-US', { year: 'numeric', month: 'long' });
            select.appendChild(option);
        }
    }

    async loadEntries(yearMonth = null) {
        try {
            this.showLoading();
            let url = '/api/entries';
            
            if (yearMonth) {
                const [year, month] = yearMonth.split('-');
                url = `/api/entries/${year}/${month}`;
            }
            
            const response = await fetch(url);
            if (!response.ok) throw new Error('Failed to load entries');
            
            this.entries = await response.json();
            this.renderEntries();
        } catch (error) {
            console.error('Error loading entries:', error);
            this.showError('Failed to load entries');
        }
    }

    renderEntries() {
        const container = document.getElementById('entriesList');
        
        if (this.entries.length === 0) {
            container.innerHTML = `
                <div class="no-entries">
                    <h3>📝 No entries yet</h3>
                    <p>Start writing your first diary entry!</p>
                </div>
            `;
            return;
        }

        container.innerHTML = this.entries.map(entry => `
            <div class="entry-card">
                <div class="entry-header">
                    <div class="entry-date">${this.formatDate(entry.date)}</div>
                    <div class="entry-mood">${this.getMoodEmoji(entry.mood)}</div>
                </div>
                <h3 class="entry-title">${this.escapeHtml(entry.title)}</h3>
                <div class="entry-content">${this.escapeHtml(entry.content)}</div>
                <div class="entry-actions">
                    <button class="btn btn-secondary" onclick="app.editEntry('${entry._id}')">Edit</button>
                    <button class="btn btn-danger" onclick="app.deleteEntry('${entry._id}')">Delete</button>
                </div>
                <div class="entry-meta">
                    Created: ${this.formatDateTime(entry.createdAt)}
                    ${entry.updatedAt !== entry.createdAt ? `| Updated: ${this.formatDateTime(entry.updatedAt)}` : ''}
                </div>
            </div>
        `).join('');
    }

    openModal(entry = null) {
        const modal = document.getElementById('entryModal');
        const form = document.getElementById('entryForm');
        const title = document.getElementById('modalTitle');
        
        if (entry) {
            // Edit mode
            title.textContent = 'Edit Diary Entry';
            document.getElementById('entryDate').value = entry.date.split('T')[0];
            document.getElementById('entryTitle').value = entry.title;
            document.getElementById('entryContent').value = entry.content;
            document.getElementById('entryMood').value = entry.mood;
            this.currentEditId = entry._id;
        } else {
            // New entry mode
            title.textContent = 'New Diary Entry';
            form.reset();
            document.getElementById('entryDate').value = new Date().toISOString().split('T')[0];
            this.currentEditId = null;
        }
        
        modal.style.display = 'block';
    }

    closeModal() {
        document.getElementById('entryModal').style.display = 'none';
        document.getElementById('entryForm').reset();
        this.currentEditId = null;
    }

    async handleSubmit(e) {
        e.preventDefault();
        
        const formData = {
            date: document.getElementById('entryDate').value,
            title: document.getElementById('entryTitle').value,
            content: document.getElementById('entryContent').value,
            mood: document.getElementById('entryMood').value
        };

        try {
            let response;
            if (this.currentEditId) {
                // Update existing entry
                response = await fetch(`/api/entries/${this.currentEditId}`, {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(formData)
                });
            } else {
                // Create new entry
                response = await fetch('/api/entries', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(formData)
                });
            }

            if (!response.ok) {
                const error = await response.json();
                throw new Error(error.error || 'Failed to save entry');
            }

            this.closeModal();
            this.loadEntries();
        } catch (error) {
            console.error('Error saving entry:', error);
            alert(error.message);
        }
    }

    editEntry(id) {
        const entry = this.entries.find(e => e._id === id);
        if (entry) {
            this.openModal(entry);
        }
    }

    async deleteEntry(id) {
        if (!confirm('Are you sure you want to delete this entry?')) return;

        try {
            const response = await fetch(`/api/entries/${id}`, {
                method: 'DELETE'
            });

            if (!response.ok) throw new Error('Failed to delete entry');

            this.loadEntries();
        } catch (error) {
            console.error('Error deleting entry:', error);
            alert('Failed to delete entry');
        }
    }

    filterByMonth(yearMonth) {
        this.loadEntries(yearMonth || null);
    }

    showLoading() {
        document.getElementById('entriesList').innerHTML = '<div class="loading">Loading entries...</div>';
    }

    showError(message) {
        document.getElementById('entriesList').innerHTML = `<div class="no-entries"><h3>Error</h3><p>${message}</p></div>`;
    }

    formatDate(dateString) {
        return new Date(dateString).toLocaleDateString('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    formatDateTime(dateString) {
        return new Date(dateString).toLocaleString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    getMoodEmoji(mood) {
        const moods = {
            happy: '😊',
            sad: '😢',
            neutral: '😐',
            excited: '🤩',
            anxious: '😰'
        };
        return moods[mood] || '😐';
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Initialize the app
const app = new DiaryApp();
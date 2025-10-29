const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/dailydiary';

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

// MongoDB Connection
mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('Connected to MongoDB'))
.catch(err => console.error('MongoDB connection error:', err));

// Diary Entry Schema
const diarySchema = new mongoose.Schema({
  date: { type: Date, required: true, unique: true },
  title: { type: String, required: true },
  content: { type: String, required: true },
  mood: { type: String, enum: ['happy', 'sad', 'neutral', 'excited', 'anxious'], default: 'neutral' },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const DiaryEntry = mongoose.model('DiaryEntry', diarySchema);

// Routes
// Get all diary entries
app.get('/api/entries', async (req, res) => {
  try {
    const entries = await DiaryEntry.find().sort({ date: -1 });
    res.json(entries);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get entries by month
app.get('/api/entries/:year/:month', async (req, res) => {
  try {
    const { year, month } = req.params;
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);
    
    const entries = await DiaryEntry.find({
      date: { $gte: startDate, $lte: endDate }
    }).sort({ date: -1 });
    
    res.json(entries);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create new diary entry
app.post('/api/entries', async (req, res) => {
  try {
    const { date, title, content, mood } = req.body;
    const entry = new DiaryEntry({ date, title, content, mood });
    await entry.save();
    res.status(201).json(entry);
  } catch (error) {
    if (error.code === 11000) {
      res.status(400).json({ error: 'Entry for this date already exists' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
});

// Update diary entry
app.put('/api/entries/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, content, mood } = req.body;
    
    const entry = await DiaryEntry.findByIdAndUpdate(
      id,
      { title, content, mood, updatedAt: new Date() },
      { new: true }
    );
    
    if (!entry) {
      return res.status(404).json({ error: 'Entry not found' });
    }
    
    res.json(entry);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Delete diary entry
app.delete('/api/entries/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const entry = await DiaryEntry.findByIdAndDelete(id);
    
    if (!entry) {
      return res.status(404).json({ error: 'Entry not found' });
    }
    
    res.json({ message: 'Entry deleted successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Serve frontend
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
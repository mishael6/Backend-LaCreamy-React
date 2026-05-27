import express from 'express';
import cors from 'cors';
import * as dotenv from 'dotenv';
import rateLimit from 'express-rate-limit';
import connectDB from './config/db.js';
import authRoutes from './routes/auth.js';
import adminRoutes from './routes/admin.js';
import apiRoutes from './routes/api.js';

if (process.env.NODE_ENV !== 'production') {
  dotenv.config();
}

const app = express();
const PORT = process.env.PORT || 5000;

// Connect to MongoDB
connectDB();

// Global rate limiter
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200,
  message: { success: false, message: 'Too many requests. Please slow down.' },
});

// Middleware
app.use(globalLimiter);
app.use(cors({
  origin: [
    'http://localhost:5173',
    'https://lacreamy.netlify.app', // add after netlify deploy
  ],
  credentials: true,
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'ðŸ¥ LaCreamy API is running',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api', apiRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.originalUrl} not found.` });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ success: false, message: 'Something went wrong on the server.' });
});

app.listen(PORT, () => {
  console.log(`\nðŸš€ LaCreamy Backend running on http://localhost:${PORT}`);
  console.log(`ðŸ“Œ Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`\nAvailable endpoints:`);
  console.log(`  POST   /api/auth/send-otp`);
  console.log(`  POST   /api/auth/verify-otp`);
  console.log(`  GET    /api/auth/me`);
  console.log(`  POST   /api/admin/login`);
  console.log(`  GET    /api/admin/stats`);
  console.log(`  GET    /api/products`);
  console.log(`  POST   /api/orders\n`);
});


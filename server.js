// backend/src/server.js
// ─────────────────────────────────────────
//  MediCare+ API Server  v2.0
//  Node.js + Express + PostgreSQL
// ─────────────────────────────────────────

require('dotenv').config();

const express     = require('express');
const cors        = require('cors');
const helmet      = require('helmet');
const morgan      = require('morgan');
const rateLimit   = require('express-rate-limit');
const { connectDB } = require('./config/db');

// Route modules
const authRoutes        = require('./routes/auth');
const doctorRoutes      = require('./routes/doctors');
const appointmentRoutes = require('./routes/appointments');
const productRoutes     = require('./routes/products');
const orderRoutes       = require('./routes/orders');
const emergencyRoutes   = require('./routes/emergency');
const aiRoutes          = require('./routes/ai');
const recordRoutes      = require('./routes/records');

const app  = express();
const PORT = process.env.PORT || 5000;

// ─── Middleware ───────────────────────────
app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(cors({
  origin: process.env.FRONTEND_URL || '*',
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// Rate limiter
app.use('/api/', rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 min
  max: 200,
  message: { error: 'Too many requests. Please try again later.' }
});

// AI endpoint stricter limit
app.use('/api/ai/', rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  message: { error: 'AI rate limit. Wait a minute.' }
}));

// ─── Routes ───────────────────────────────
app.use('/api/auth',         authRoutes);
app.use('/api/doctors',      doctorRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/products',     productRoutes);
app.use('/api/orders',       orderRoutes);
app.use('/api/emergency',    emergencyRoutes);
app.use('/api/ai',           aiRoutes);
app.use('/api/records',      recordRoutes);

// ─── Health check ─────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', version: '2.0', time: new Date() });
});

// ─── 404 handler ──────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.path} not found` });
});

// ─── Global error handler ─────────────────
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message
  });
});

// ─── Boot ─────────────────────────────────
const start = async () => {
  await connectDB();
  app.listen(PORT, () => {
    console.log(`\n🚀 MediCare+ API running at http://localhost:${PORT}`);
    console.log(`📋 Health check: http://localhost:${PORT}/api/health`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}\n`);
  });
};

start();

module.exports = app;

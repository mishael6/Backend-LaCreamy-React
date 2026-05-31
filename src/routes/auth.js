import express from 'express';
import { signup, login, getMe, updateProfile } from '../controllers/authController.js';
import { protect } from '../middleware/auth.js';
import rateLimit from 'express-rate-limit';

const router = express.Router();

// Rate limit login attempts
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { success: false, message: 'Too many login attempts. Please wait 15 minutes.' },
});

router.post('/signup', signup);
router.post('/login', loginLimiter, login);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);

export default router;


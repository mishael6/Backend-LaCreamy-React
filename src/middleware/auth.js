import { verifyUserToken, verifyAdminToken } from '../utils/jwt.js';
import User from '../models/User.js';
import Admin from '../models/Admin.js';

// Protect customer routes
export const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'Not authorized. Please log in.' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = verifyUserToken(token);

    const user = await User.findById(decoded.id).select('-__v');
    if (!user) {
      return res.status(401).json({ success: false, message: 'User no longer exists.' });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
  }
};

// Protect admin routes
export const protectAdmin = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'Admin access required.' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = verifyAdminToken(token);

    if (decoded.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Forbidden. Admin access only.' });
    }

    const admin = await Admin.findById(decoded.id).select('-password -__v');
    if (!admin) {
      return res.status(401).json({ success: false, message: 'Admin account not found.' });
    }

    req.admin = admin;
    next();
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Invalid or expired admin token.' });
  }
};


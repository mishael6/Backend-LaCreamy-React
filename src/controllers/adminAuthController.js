import Admin from '../models/Admin.js';
import { generateAdminToken } from '../utils/jwt.js';

// @desc    Admin login
// @route   POST /api/admin/login
// @access  Public
export const adminLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required.' });
    }

    const admin = await Admin.findOne({ email: email.toLowerCase() });
    if (!admin) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const isMatch = await admin.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    admin.lastLogin = new Date();
    await admin.save();

    const token = generateAdminToken(admin._id);

    return res.status(200).json({
      success: true,
      message: 'Admin login successful.',
      token,
      admin: {
        id: admin._id,
        name: admin.name,
        email: admin.email,
        role: admin.role,
      },
    });
  } catch (error) {
    console.error('adminLogin error:', error);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// @desc    Get admin profile
// @route   GET /api/admin/me
// @access  Admin
export const getAdminMe = async (req, res) => {
  return res.status(200).json({ success: true, admin: req.admin });
};


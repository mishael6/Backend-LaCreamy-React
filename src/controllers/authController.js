import User from '../models/User.js';
import { generateUserToken } from '../utils/jwt.js';
import { formatPhone } from '../utils/sms.js';

// @desc    Register new customer
// @route   POST /api/auth/signup
// @access  Public
export const signup = async (req, res) => {
  try {
    const { name, phone, password } = req.body;

    if (!name || !phone || !password) {
      return res.status(400).json({ success: false, message: 'Name, phone and password are required.' });
    }

    if (password.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters.' });
    }

    const formattedPhone = formatPhone(phone);

    const existing = await User.findOne({ phone: formattedPhone });
    if (existing) {
      return res.status(400).json({ success: false, message: 'An account with this phone number already exists.' });
    }

    const user = await User.create({
      name: name.trim(),
      phone: formattedPhone,
      password,
    });

    const token = generateUserToken(user._id);

    return res.status(201).json({
      success: true,
      message: 'Account created successfully!',
      token,
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        address: user.address,
      },
    });
  } catch (error) {
    console.error('signup error:', error);
    return res.status(500).json({ success: false, message: 'Server error. Please try again.' });
  }
};

// @desc    Login customer
// @route   POST /api/auth/login
// @access  Public
export const login = async (req, res) => {
  try {
    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({ success: false, message: 'Phone and password are required.' });
    }

    const formattedPhone = formatPhone(phone);

    const user = await User.findOne({ phone: formattedPhone });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid phone number or password.' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid phone number or password.' });
    }

    const token = generateUserToken(user._id);

    return res.status(200).json({
      success: true,
      message: 'Login successful!',
      token,
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        address: user.address,
      },
    });
  } catch (error) {
    console.error('login error:', error);
    return res.status(500).json({ success: false, message: 'Server error. Please try again.' });
  }
};

// @desc    Get current customer profile
// @route   GET /api/auth/me
// @access  Protected
export const getMe = async (req, res) => {
  return res.status(200).json({ success: true, user: req.user });
};

// @desc    Update customer profile
// @route   PUT /api/auth/profile
// @access  Protected
export const updateProfile = async (req, res) => {
  try {
    const { name, address } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { name, address },
      { new: true, runValidators: true }
    ).select('-password -__v');

    return res.status(200).json({ success: true, user });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to update profile.' });
  }
};

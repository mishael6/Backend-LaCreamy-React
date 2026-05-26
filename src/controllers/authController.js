import User from '../models/User.js';
import OTP from '../models/OTP.js';
import { generateOTP, sendSMS, formatPhone } from '../utils/sms.js';
import { generateUserToken } from '../utils/jwt.js';

const OTP_EXPIRES_MINUTES = parseInt(process.env.OTP_EXPIRES_MINUTES) || 5;

// @desc    Send OTP to phone number
// @route   POST /api/auth/send-otp
// @access  Public
export const sendOTP = async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ success: false, message: 'Phone number is required.' });
    }

    const formattedPhone = formatPhone(phone);

    // Delete any existing OTP for this phone
    await OTP.deleteMany({ phone: formattedPhone });

    // Generate OTP
    const code = generateOTP();
    const expiresAt = new Date(Date.now() + OTP_EXPIRES_MINUTES * 60 * 1000);

    // Save OTP to DB
    await OTP.create({ phone: formattedPhone, code, expiresAt });

    // Send via Payloqa
    const message = `Your LaCreamy verification code is: ${code}. Valid for ${OTP_EXPIRES_MINUTES} minutes. Do not share this code.`;
    const smsSent = await sendSMS(formattedPhone, message);

    if (!smsSent.success) {
      return res.status(500).json({ success: false, message: 'Failed to send OTP. Please try again.' });
    }

    // In development, return OTP in response for testing
    const devData = process.env.NODE_ENV === 'development' ? { otp: code } : {};

    return res.status(200).json({
      success: true,
      message: `OTP sent to ${phone}`,
      phone: formattedPhone,
      expiresIn: `${OTP_EXPIRES_MINUTES} minutes`,
      ...devData,
    });
  } catch (error) {
    console.error('sendOTP error:', error);
    return res.status(500).json({ success: false, message: 'Server error. Please try again.' });
  }
};

// @desc    Verify OTP and login/register customer
// @route   POST /api/auth/verify-otp
// @access  Public
export const verifyOTP = async (req, res) => {
  try {
    const { phone, code, name } = req.body;

    if (!phone || !code) {
      return res.status(400).json({ success: false, message: 'Phone and OTP code are required.' });
    }

    const formattedPhone = formatPhone(phone);

    // Find OTP
    const otpRecord = await OTP.findOne({ phone: formattedPhone, verified: false });

    if (!otpRecord) {
      return res.status(400).json({ success: false, message: 'OTP not found. Please request a new one.' });
    }

    // Check expiry
    if (new Date() > otpRecord.expiresAt) {
      await OTP.deleteOne({ _id: otpRecord._id });
      return res.status(400).json({ success: false, message: 'OTP has expired. Please request a new one.' });
    }

    // Check max attempts
    if (otpRecord.attempts >= 3) {
      await OTP.deleteOne({ _id: otpRecord._id });
      return res.status(400).json({ success: false, message: 'Too many attempts. Please request a new OTP.' });
    }

    // Verify code
    if (otpRecord.code !== code.toString()) {
      await OTP.updateOne({ _id: otpRecord._id }, { $inc: { attempts: 1 } });
      const remaining = 3 - (otpRecord.attempts + 1);
      return res.status(400).json({
        success: false,
        message: `Incorrect OTP. ${remaining} attempt(s) remaining.`,
      });
    }

    // Mark OTP as verified
    await OTP.updateOne({ _id: otpRecord._id }, { verified: true });

    // Find or create user
    let user = await User.findOne({ phone: formattedPhone });
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      user = await User.create({
        phone: formattedPhone,
        name: name || 'Customer',
        isVerified: true,
      });
    } else {
      user.isVerified = true;
      await user.save();
    }

    const token = generateUserToken(user._id);

    return res.status(200).json({
      success: true,
      message: isNewUser ? 'Account created successfully!' : 'Login successful!',
      isNewUser,
      token,
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        address: user.address,
      },
    });
  } catch (error) {
    console.error('verifyOTP error:', error);
    return res.status(500).json({ success: false, message: 'Server error. Please try again.' });
  }
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
    ).select('-__v');

    return res.status(200).json({ success: true, user });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to update profile.' });
  }
};

// @desc    Get current customer profile
// @route   GET /api/auth/me
// @access  Protected
export const getMe = async (req, res) => {
  return res.status(200).json({ success: true, user: req.user });
};


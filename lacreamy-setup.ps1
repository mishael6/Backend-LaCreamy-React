# LaCreamy Backend - Auto Setup Script
# Run this from inside your backend folder

New-Item -ItemType Directory -Force -Path "src\config" | Out-Null
@'
import mongoose from 'mongoose';

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`✅ MongoDB Atlas Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`❌ MongoDB Connection Error: ${error.message}`);
    process.exit(1);
  }
};

export default connectDB;

'@ | Set-Content -Path 'src\config\db.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\models" | Out-Null
@'
import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    unique: true,
    trim: true,
  },
  address: {
    type: String,
    default: '',
    trim: true,
  },
  isVerified: {
    type: Boolean,
    default: false,
  },
  loyaltyPoints: {
    type: Number,
    default: 0,
  },
}, { timestamps: true });

export default mongoose.model('User', userSchema);

'@ | Set-Content -Path 'src\models\User.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\models" | Out-Null
@'
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const adminSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
    default: 'Admin',
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: 6,
  },
  role: {
    type: String,
    enum: ['superadmin', 'admin'],
    default: 'admin',
  },
  lastLogin: {
    type: Date,
    default: null,
  },
}, { timestamps: true });

// Hash password before saving
adminSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

// Compare password
adminSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

export default mongoose.model('Admin', adminSchema);

'@ | Set-Content -Path 'src\models\Admin.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\models" | Out-Null
@'
import mongoose from 'mongoose';

const otpSchema = new mongoose.Schema({
  phone: {
    type: String,
    required: true,
  },
  code: {
    type: String,
    required: true,
  },
  expiresAt: {
    type: Date,
    required: true,
    index: { expires: 0 }, // auto-delete when expired
  },
  attempts: {
    type: Number,
    default: 0,
  },
  verified: {
    type: Boolean,
    default: false,
  },
}, { timestamps: true });

export default mongoose.model('OTP', otpSchema);

'@ | Set-Content -Path 'src\models\OTP.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\models" | Out-Null
@'
import mongoose from 'mongoose';

const productSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Product name is required'],
    trim: true,
  },
  category: {
    type: String,
    required: [true, 'Category is required'],
    enum: ['croissants', 'cakes', 'tarts', 'cookies', 'bread', 'seasonal'],
  },
  price: {
    type: Number,
    required: [true, 'Price is required'],
    min: [0, 'Price cannot be negative'],
  },
  description: {
    type: String,
    required: [true, 'Description is required'],
    trim: true,
  },
  emoji: {
    type: String,
    default: '🥐',
  },
  badge: {
    type: String,
    default: '',
    trim: true,
  },
  gradient: {
    type: String,
    default: 'linear-gradient(135deg, #F5E9C8 0%, #E8CC8A 100%)',
  },
  image: {
    type: String,    // URL to uploaded image
    default: '',
  },
  isAvailable: {
    type: Boolean,
    default: true,
  },
  isFeatured: {
    type: Boolean,
    default: false,
  },
  stock: {
    type: Number,
    default: 999,
  },
}, { timestamps: true });

export default mongoose.model('Product', productSchema);

'@ | Set-Content -Path 'src\models\Product.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\models" | Out-Null
@'
import mongoose from 'mongoose';

const orderItemSchema = new mongoose.Schema({
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
  },
  name: String,
  price: Number,
  emoji: String,
  qty: {
    type: Number,
    required: true,
    min: 1,
  },
  subtotal: Number,
});

const deliveryStageSchema = new mongoose.Schema({
  stage: {
    type: String,
    enum: [
      'order_placed',
      'confirmed',
      'being_prepared',
      'out_for_delivery',
      'delivered',
      'cancelled',
    ],
  },
  timestamp: {
    type: Date,
    default: Date.now,
  },
  note: {
    type: String,
    default: '',
  },
});

const orderSchema = new mongoose.Schema({
  orderNumber: {
    type: String,
    unique: true,
  },
  customer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  customerName: String,
  customerPhone: String,
  deliveryAddress: {
    type: String,
    default: '',
  },
  specialNote: {
    type: String,
    default: '',
  },
  items: [orderItemSchema],
  subtotal: {
    type: Number,
    required: true,
  },
  deliveryFee: {
    type: Number,
    default: 10,
  },
  total: {
    type: Number,
    required: true,
  },
  status: {
    type: String,
    enum: [
      'order_placed',
      'confirmed',
      'being_prepared',
      'out_for_delivery',
      'delivered',
      'cancelled',
    ],
    default: 'order_placed',
  },
  deliveryHistory: [deliveryStageSchema],
  estimatedDelivery: {
    type: Date,
    default: null,
  },
  receiptSent: {
    type: Boolean,
    default: false,
  },
}, { timestamps: true });

// Auto-generate order number before saving
orderSchema.pre('save', async function (next) {
  if (!this.orderNumber) {
    const count = await mongoose.model('Order').countDocuments();
    this.orderNumber = `LC-${String(count + 1).padStart(4, '0')}`;
  }
  next();
});

export default mongoose.model('Order', orderSchema);

'@ | Set-Content -Path 'src\models\Order.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\controllers" | Out-Null
@'
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

'@ | Set-Content -Path 'src\controllers\authController.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\controllers" | Out-Null
@'
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

'@ | Set-Content -Path 'src\controllers\adminAuthController.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\controllers" | Out-Null
@'
import Product from '../models/Product.js';

// @desc    Get all products (public)
// @route   GET /api/products
// @access  Public
export const getProducts = async (req, res) => {
  try {
    const { category, available } = req.query;
    const filter = {};
    if (category && category !== 'all') filter.category = category;
    if (available !== undefined) filter.isAvailable = available === 'true';

    const products = await Product.find(filter).sort({ createdAt: -1 });
    return res.status(200).json({ success: true, count: products.length, products });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch products.' });
  }
};

// @desc    Get single product
// @route   GET /api/products/:id
// @access  Public
export const getProduct = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found.' });
    return res.status(200).json({ success: true, product });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch product.' });
  }
};

// @desc    Create product
// @route   POST /api/admin/products
// @access  Admin
export const createProduct = async (req, res) => {
  try {
    const { name, category, price, description, emoji, badge, gradient, isAvailable, isFeatured, stock } = req.body;

    if (!name || !category || !price || !description) {
      return res.status(400).json({ success: false, message: 'Name, category, price and description are required.' });
    }

    const product = await Product.create({
      name, category, price: parseFloat(price), description,
      emoji: emoji || '🥐',
      badge: badge || '',
      gradient: gradient || 'linear-gradient(135deg, #F5E9C8 0%, #E8CC8A 100%)',
      isAvailable: isAvailable !== false,
      isFeatured: isFeatured || false,
      stock: stock || 999,
    });

    return res.status(201).json({ success: true, message: 'Product created successfully!', product });
  } catch (error) {
    console.error('createProduct error:', error);
    return res.status(500).json({ success: false, message: 'Failed to create product.' });
  }
};

// @desc    Update product
// @route   PUT /api/admin/products/:id
// @access  Admin
export const updateProduct = async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(
      req.params.id,
      { ...req.body },
      { new: true, runValidators: true }
    );
    if (!product) return res.status(404).json({ success: false, message: 'Product not found.' });
    return res.status(200).json({ success: true, message: 'Product updated!', product });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to update product.' });
  }
};

// @desc    Delete product
// @route   DELETE /api/admin/products/:id
// @access  Admin
export const deleteProduct = async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found.' });
    return res.status(200).json({ success: true, message: 'Product deleted.' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to delete product.' });
  }
};

'@ | Set-Content -Path 'src\controllers\productController.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\controllers" | Out-Null
@'
import Order from '../models/Order.js';
import Product from '../models/Product.js';
import { sendSMS } from '../utils/sms.js';

const DELIVERY_FEE = 10;

const STATUS_LABELS = {
  order_placed: 'Order Placed',
  confirmed: 'Confirmed',
  being_prepared: 'Being Prepared',
  out_for_delivery: 'Out for Delivery',
  delivered: 'Delivered',
  cancelled: 'Cancelled',
};

// @desc    Place a new order
// @route   POST /api/orders
// @access  Protected (Customer)
export const placeOrder = async (req, res) => {
  try {
    const { items, deliveryAddress, specialNote } = req.body;

    if (!items || items.length === 0) {
      return res.status(400).json({ success: false, message: 'No items in order.' });
    }

    // Fetch products and calculate totals
    let subtotal = 0;
    const orderItems = [];

    for (const item of items) {
      const product = await Product.findById(item.productId);
      if (!product || !product.isAvailable) {
        return res.status(400).json({ success: false, message: `Product "${item.name}" is unavailable.` });
      }
      const itemSubtotal = product.price * item.qty;
      subtotal += itemSubtotal;
      orderItems.push({
        product: product._id,
        name: product.name,
        price: product.price,
        emoji: product.emoji,
        qty: item.qty,
        subtotal: itemSubtotal,
      });
    }

    const total = subtotal + DELIVERY_FEE;

    const order = await Order.create({
      customer: req.user._id,
      customerName: req.user.name,
      customerPhone: req.user.phone,
      deliveryAddress: deliveryAddress || req.user.address || '',
      specialNote: specialNote || '',
      items: orderItems,
      subtotal,
      deliveryFee: DELIVERY_FEE,
      total,
      status: 'order_placed',
      deliveryHistory: [{ stage: 'order_placed', note: 'Your order has been placed.' }],
    });

    // Send SMS confirmation
    const itemsList = orderItems.map(i => `${i.name} x${i.qty}`).join(', ');
    const confirmMsg = `🥐 LaCreamy: Order #${order.orderNumber} confirmed!\nItems: ${itemsList}\nTotal: GH₵${total.toFixed(2)}\nTrack your order in the app.`;
    await sendSMS(req.user.phone, confirmMsg);

    return res.status(201).json({
      success: true,
      message: 'Order placed successfully!',
      order: {
        id: order._id,
        orderNumber: order.orderNumber,
        status: order.status,
        total: order.total,
        items: order.items,
      },
    });
  } catch (error) {
    console.error('placeOrder error:', error);
    return res.status(500).json({ success: false, message: 'Failed to place order.' });
  }
};

// @desc    Get customer's orders
// @route   GET /api/orders
// @access  Protected (Customer)
export const getMyOrders = async (req, res) => {
  try {
    const orders = await Order.find({ customer: req.user._id })
      .sort({ createdAt: -1 })
      .populate('items.product', 'name emoji');

    return res.status(200).json({ success: true, count: orders.length, orders });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch orders.' });
  }
};

// @desc    Get single order (customer)
// @route   GET /api/orders/:id
// @access  Protected (Customer)
export const getMyOrder = async (req, res) => {
  try {
    const order = await Order.findOne({ _id: req.params.id, customer: req.user._id });
    if (!order) return res.status(404).json({ success: false, message: 'Order not found.' });
    return res.status(200).json({ success: true, order });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch order.' });
  }
};

// ─── ADMIN ───────────────────────────────────────────────

// @desc    Get all orders (admin)
// @route   GET /api/admin/orders
// @access  Admin
export const getAllOrders = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const filter = status ? { status } : {};

    const total = await Order.countDocuments(filter);
    const orders = await Order.find(filter)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .populate('customer', 'name phone');

    return res.status(200).json({
      success: true,
      total,
      page: parseInt(page),
      pages: Math.ceil(total / limit),
      orders,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch orders.' });
  }
};

// @desc    Update order delivery status (admin)
// @route   PUT /api/admin/orders/:id/status
// @access  Admin
export const updateOrderStatus = async (req, res) => {
  try {
    const { status, note } = req.body;

    const validStatuses = ['confirmed', 'being_prepared', 'out_for_delivery', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status.' });
    }

    const order = await Order.findById(req.params.id).populate('customer', 'phone name');
    if (!order) return res.status(404).json({ success: false, message: 'Order not found.' });

    order.status = status;
    order.deliveryHistory.push({
      stage: status,
      note: note || `Status updated to: ${STATUS_LABELS[status]}`,
    });

    if (status === 'delivered') {
      order.estimatedDelivery = new Date();
    }

    await order.save();

    // Notify customer via SMS
    const statusMsg = `🥐 LaCreamy: Order #${order.orderNumber} update!\nStatus: ${STATUS_LABELS[status]}${note ? `\n${note}` : ''}\nTrack in the app.`;
    if (order.customer?.phone) {
      await sendSMS(order.customer.phone, statusMsg);
    }

    return res.status(200).json({ success: true, message: 'Order status updated!', order });
  } catch (error) {
    console.error('updateOrderStatus error:', error);
    return res.status(500).json({ success: false, message: 'Failed to update order status.' });
  }
};

// @desc    Get admin dashboard stats
// @route   GET /api/admin/stats
// @access  Admin
export const getDashboardStats = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [totalOrders, todayOrders, pendingOrders, deliveredOrders, revenue] = await Promise.all([
      Order.countDocuments(),
      Order.countDocuments({ createdAt: { $gte: today } }),
      Order.countDocuments({ status: { $in: ['order_placed', 'confirmed', 'being_prepared', 'out_for_delivery'] } }),
      Order.countDocuments({ status: 'delivered' }),
      Order.aggregate([
        { $match: { status: 'delivered' } },
        { $group: { _id: null, total: { $sum: '$total' } } },
      ]),
    ]);

    return res.status(200).json({
      success: true,
      stats: {
        totalOrders,
        todayOrders,
        pendingOrders,
        deliveredOrders,
        totalRevenue: revenue[0]?.total || 0,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch stats.' });
  }
};

'@ | Set-Content -Path 'src\controllers\orderController.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\middleware" | Out-Null
@'
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

'@ | Set-Content -Path 'src\middleware\auth.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\routes" | Out-Null
@'
import express from 'express';
import { sendOTP, verifyOTP, updateProfile, getMe } from '../controllers/authController.js';
import { protect } from '../middleware/auth.js';
import rateLimit from 'express-rate-limit';

const router = express.Router();

// Rate limit OTP sending (max 3 per 10 minutes per IP)
const otpLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 3,
  message: { success: false, message: 'Too many OTP requests. Please wait 10 minutes.' },
});

router.post('/send-otp', otpLimiter, sendOTP);
router.post('/verify-otp', verifyOTP);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);

export default router;

'@ | Set-Content -Path 'src\routes\auth.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\routes" | Out-Null
@'
import express from 'express';
import { adminLogin, getAdminMe } from '../controllers/adminAuthController.js';
import { createProduct, updateProduct, deleteProduct } from '../controllers/productController.js';
import { getAllOrders, updateOrderStatus, getDashboardStats } from '../controllers/orderController.js';
import { protectAdmin } from '../middleware/auth.js';

const router = express.Router();

// Auth
router.post('/login', adminLogin);
router.get('/me', protectAdmin, getAdminMe);

// Dashboard
router.get('/stats', protectAdmin, getDashboardStats);

// Products
router.post('/products', protectAdmin, createProduct);
router.put('/products/:id', protectAdmin, updateProduct);
router.delete('/products/:id', protectAdmin, deleteProduct);

// Orders
router.get('/orders', protectAdmin, getAllOrders);
router.put('/orders/:id/status', protectAdmin, updateOrderStatus);

export default router;

'@ | Set-Content -Path 'src\routes\admin.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\routes" | Out-Null
@'
import express from 'express';
import { getProducts, getProduct } from '../controllers/productController.js';
import { placeOrder, getMyOrders, getMyOrder } from '../controllers/orderController.js';
import { protect } from '../middleware/auth.js';

const router = express.Router();

// Public product routes
router.get('/products', getProducts);
router.get('/products/:id', getProduct);

// Protected order routes
router.post('/orders', protect, placeOrder);
router.get('/orders', protect, getMyOrders);
router.get('/orders/:id', protect, getMyOrder);

export default router;

'@ | Set-Content -Path 'src\routes\api.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\utils" | Out-Null
@'
import axios from 'axios';

/**
 * Send SMS via Payloqa
 * Docs: https://payloqa.com/docs
 */
export const sendSMS = async (phone, message) => {
  try {
    const response = await axios.post(
      'https://api.payloqa.com/v1/sms/send',
      {
        to: phone,
        from: process.env.PAYLOQA_SENDER_ID || 'LaCreamy',
        message,
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.PAYLOQA_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Payloqa SMS Error:', error.response?.data || error.message);
    return { success: false, error: error.response?.data || error.message };
  }
};

/**
 * Generate a 6-digit OTP
 */
export const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Format phone number to international format
 * Converts 0241234567 → 233241234567
 */
export const formatPhone = (phone) => {
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.startsWith('0')) {
    return '233' + cleaned.slice(1);
  }
  if (cleaned.startsWith('233')) {
    return cleaned;
  }
  return cleaned;
};

'@ | Set-Content -Path 'src\utils\sms.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src\utils" | Out-Null
@'
import jwt from 'jsonwebtoken';

export const generateUserToken = (userId) => {
  return jwt.sign({ id: userId, role: 'customer' }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

export const generateAdminToken = (adminId) => {
  return jwt.sign({ id: adminId, role: 'admin' }, process.env.JWT_ADMIN_SECRET, {
    expiresIn: process.env.JWT_ADMIN_EXPIRES_IN || '1d',
  });
};

export const verifyUserToken = (token) => {
  return jwt.verify(token, process.env.JWT_SECRET);
};

export const verifyAdminToken = (token) => {
  return jwt.verify(token, process.env.JWT_ADMIN_SECRET);
};

'@ | Set-Content -Path 'src\utils\jwt.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src" | Out-Null
@'
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Admin from './models/Admin.js';
import Product from './models/Product.js';

dotenv.config();

const sampleProducts = [
  {
    name: 'Classic Butter Croissant',
    category: 'croissants',
    price: 8.50,
    description: 'Seventy-two layers of hand-laminated dough with French butter, baked until deeply golden with a shatteringly crisp exterior.',
    badge: 'Bestseller',
    emoji: '🥐',
    gradient: 'linear-gradient(135deg, #F5E9C8 0%, #E8CC8A 100%)',
    isFeatured: true,
  },
  {
    name: 'Almond & Frangipane Croissant',
    category: 'croissants',
    price: 11.00,
    description: 'Double-baked with house-made almond cream, finished with toasted flaked almonds and a dusting of powdered sugar.',
    badge: 'Fan Favourite',
    emoji: '🥐',
    gradient: 'linear-gradient(135deg, #FAEEDA 0%, #D4A017 100%)',
    isFeatured: true,
  },
  {
    name: 'Strawberry Dream Cake',
    category: 'cakes',
    price: 45.00,
    description: 'Light vanilla génoise layered with fresh strawberry compote and whipped crème diplomate.',
    badge: 'Seasonal',
    emoji: '🍓',
    gradient: 'linear-gradient(135deg, #FFE0E6 0%, #FFB3C1 100%)',
    isFeatured: true,
  },
  {
    name: 'Salted Caramel Opera',
    category: 'cakes',
    price: 52.00,
    description: 'Eight alternating layers of espresso-soaked joconde, salted caramel buttercream and dark chocolate ganache.',
    badge: "Chef's Special",
    emoji: '🎂',
    gradient: 'linear-gradient(135deg, #D4A017 0%, #6B3F1F 100%)',
  },
  {
    name: 'Brown Butter Chocolate Chip Cookies',
    category: 'cookies',
    price: 5.50,
    description: 'Nutty brown butter dough studded with Valrhona 64% discs, finished with fleur de sel.',
    badge: 'Bestseller',
    emoji: '🍪',
    gradient: 'linear-gradient(135deg, #F5DEB3 0%, #8B4513 100%)',
  },
  {
    name: 'Lemon Verbena Tart',
    category: 'tarts',
    price: 28.00,
    description: 'Crisp pâte sucrée shell filled with silky lemon verbena curd, topped with Italian meringue.',
    emoji: '🍋',
    gradient: 'linear-gradient(135deg, #FFFDE7 0%, #F9E04B 100%)',
  },
];

const seed = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB Atlas');

    // Create default admin
    const existingAdmin = await Admin.findOne({ email: process.env.ADMIN_EMAIL });
    if (!existingAdmin) {
      await Admin.create({
        name: 'LaCreamy Admin',
        email: process.env.ADMIN_EMAIL || 'admin@lacreamy.com',
        password: process.env.ADMIN_PASSWORD || 'Admin@1234',
        role: 'superadmin',
      });
      console.log(`✅ Admin created: ${process.env.ADMIN_EMAIL}`);
    } else {
      console.log('ℹ️  Admin already exists, skipping.');
    }

    // Seed products if none exist
    const productCount = await Product.countDocuments();
    if (productCount === 0) {
      await Product.insertMany(sampleProducts);
      console.log(`✅ ${sampleProducts.length} sample products added.`);
    } else {
      console.log(`ℹ️  ${productCount} products already exist, skipping.`);
    }

    console.log('\n🎉 Seed complete! You can now run: npm run dev');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seed failed:', error);
    process.exit(1);
  }
};

seed();

'@ | Set-Content -Path 'src\seed.js' -Encoding utf8

New-Item -ItemType Directory -Force -Path "src" | Out-Null
@'
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import rateLimit from 'express-rate-limit';
import connectDB from './config/db.js';
import authRoutes from './routes/auth.js';
import adminRoutes from './routes/admin.js';
import apiRoutes from './routes/api.js';

dotenv.config();

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
  origin: process.env.FRONTEND_URL || 'http://localhost:5173',
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: '🥐 LaCreamy API is running',
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
  console.log(`\n🚀 LaCreamy Backend running on http://localhost:${PORT}`);
  console.log(`📌 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`\nAvailable endpoints:`);
  console.log(`  POST   /api/auth/send-otp`);
  console.log(`  POST   /api/auth/verify-otp`);
  console.log(`  GET    /api/auth/me`);
  console.log(`  POST   /api/admin/login`);
  console.log(`  GET    /api/admin/stats`);
  console.log(`  GET    /api/products`);
  console.log(`  POST   /api/orders\n`);
});

'@ | Set-Content -Path 'src\server.js' -Encoding utf8

@'
# Server
PORT=5000
NODE_ENV=development

# MongoDB Atlas
MONGODB_URI=mongodb+srv://YOUR_USERNAME:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/lacreamy?retryWrites=true&w=majority

# JWT Secrets (use long random strings)
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_ADMIN_SECRET=your_admin_jwt_secret_change_this_too
JWT_EXPIRES_IN=7d
JWT_ADMIN_EXPIRES_IN=1d

# Payloqa SMS
PAYLOQA_API_KEY=your_payloqa_api_key
PAYLOQA_SENDER_ID=LaCreamy

# Admin credentials (first admin account)
ADMIN_EMAIL=admin@lacreamy.com
ADMIN_PASSWORD=Admin@1234

# Frontend URL (for CORS)
FRONTEND_URL=http://localhost:5173

# OTP Settings
OTP_EXPIRES_MINUTES=5

'@ | Set-Content -Path '.env.example' -Encoding utf8

@'
node_modules/
.env
*.log
dist/

'@ | Set-Content -Path '.gitignore' -Encoding utf8

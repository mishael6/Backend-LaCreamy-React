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
    const confirmMsg = `ðŸ¥ LaCreamy: Order #${order.orderNumber} confirmed!\nItems: ${itemsList}\nTotal: GHâ‚µ${total.toFixed(2)}\nTrack your order in the app.`;
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

// â”€â”€â”€ ADMIN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    const statusMsg = `ðŸ¥ LaCreamy: Order #${order.orderNumber} update!\nStatus: ${STATUS_LABELS[status]}${note ? `\n${note}` : ''}\nTrack in the app.`;
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


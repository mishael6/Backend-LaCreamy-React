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


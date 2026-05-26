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
    default: 'ðŸ¥',
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


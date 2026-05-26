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


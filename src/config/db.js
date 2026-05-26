import mongoose from 'mongoose';

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`âœ… MongoDB Atlas Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`âŒ MongoDB Connection Error: ${error.message}`);
    process.exit(1);
  }
};

export default connectDB;


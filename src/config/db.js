import mongoose from 'mongoose';

const connectDB = async () => {
  try {
    console.log('MONGODB_URI:', process.env.MONGODB_URI ? 'FOUND' : 'NOT FOUND');
    console.log('NODE_ENV:', process.env.NODE_ENV);
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`MongoDB Atlas Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`MongoDB Connection Error: ${error.message}`);
    process.exit(1);
  }
};

export default connectDB;


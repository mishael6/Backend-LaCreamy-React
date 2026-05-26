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
    emoji: 'ðŸ¥',
    gradient: 'linear-gradient(135deg, #F5E9C8 0%, #E8CC8A 100%)',
    isFeatured: true,
  },
  {
    name: 'Almond & Frangipane Croissant',
    category: 'croissants',
    price: 11.00,
    description: 'Double-baked with house-made almond cream, finished with toasted flaked almonds and a dusting of powdered sugar.',
    badge: 'Fan Favourite',
    emoji: 'ðŸ¥',
    gradient: 'linear-gradient(135deg, #FAEEDA 0%, #D4A017 100%)',
    isFeatured: true,
  },
  {
    name: 'Strawberry Dream Cake',
    category: 'cakes',
    price: 45.00,
    description: 'Light vanilla gÃ©noise layered with fresh strawberry compote and whipped crÃ¨me diplomate.',
    badge: 'Seasonal',
    emoji: 'ðŸ“',
    gradient: 'linear-gradient(135deg, #FFE0E6 0%, #FFB3C1 100%)',
    isFeatured: true,
  },
  {
    name: 'Salted Caramel Opera',
    category: 'cakes',
    price: 52.00,
    description: 'Eight alternating layers of espresso-soaked joconde, salted caramel buttercream and dark chocolate ganache.',
    badge: "Chef's Special",
    emoji: 'ðŸŽ‚',
    gradient: 'linear-gradient(135deg, #D4A017 0%, #6B3F1F 100%)',
  },
  {
    name: 'Brown Butter Chocolate Chip Cookies',
    category: 'cookies',
    price: 5.50,
    description: 'Nutty brown butter dough studded with Valrhona 64% discs, finished with fleur de sel.',
    badge: 'Bestseller',
    emoji: 'ðŸª',
    gradient: 'linear-gradient(135deg, #F5DEB3 0%, #8B4513 100%)',
  },
  {
    name: 'Lemon Verbena Tart',
    category: 'tarts',
    price: 28.00,
    description: 'Crisp pÃ¢te sucrÃ©e shell filled with silky lemon verbena curd, topped with Italian meringue.',
    emoji: 'ðŸ‹',
    gradient: 'linear-gradient(135deg, #FFFDE7 0%, #F9E04B 100%)',
  },
];

const seed = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('âœ… Connected to MongoDB Atlas');

    // Create default admin
    const existingAdmin = await Admin.findOne({ email: process.env.ADMIN_EMAIL });
    if (!existingAdmin) {
      await Admin.create({
        name: 'LaCreamy Admin',
        email: process.env.ADMIN_EMAIL || 'admin@lacreamy.com',
        password: process.env.ADMIN_PASSWORD || 'Admin@1234',
        role: 'superadmin',
      });
      console.log(`âœ… Admin created: ${process.env.ADMIN_EMAIL}`);
    } else {
      console.log('â„¹ï¸  Admin already exists, skipping.');
    }

    // Seed products if none exist
    const productCount = await Product.countDocuments();
    if (productCount === 0) {
      await Product.insertMany(sampleProducts);
      console.log(`âœ… ${sampleProducts.length} sample products added.`);
    } else {
      console.log(`â„¹ï¸  ${productCount} products already exist, skipping.`);
    }

    console.log('\nðŸŽ‰ Seed complete! You can now run: npm run dev');
    process.exit(0);
  } catch (error) {
    console.error('âŒ Seed failed:', error);
    process.exit(1);
  }
};

seed();


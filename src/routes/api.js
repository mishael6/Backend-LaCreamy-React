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


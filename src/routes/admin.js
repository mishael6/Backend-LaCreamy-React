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


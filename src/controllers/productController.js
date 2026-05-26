import Product from '../models/Product.js';

// @desc    Get all products (public)
// @route   GET /api/products
// @access  Public
export const getProducts = async (req, res) => {
  try {
    const { category, available } = req.query;
    const filter = {};
    if (category && category !== 'all') filter.category = category;
    if (available === 'true') filter.isAvailable = true;

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
      emoji: emoji || 'ðŸ¥',
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


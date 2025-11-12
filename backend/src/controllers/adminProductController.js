import Product from '../models/Product.js';
import fs from 'fs';
import path from 'path';

// Create new product
export const createProduct = async (req, res) => {
    try {
        const { vendorId, name, description, price, quantity, category, unit, available } = req.body;

        // Validate required fields
        if (!vendorId || !name || !price || quantity === undefined) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: vendorId, name, price, quantity'
            });
        }

        const productData = {
            vendorId,
            name,
            description: description || '',
            price: parseFloat(price),
            quantity: parseInt(quantity),
            category: category || 'Other',
            unit: unit || 'piece',
            available: available !== 'false' && available !== false,
            image: req.file ? `/uploads/products/${req.file.filename}` : null
        };

        const product = await Product.create(productData);

        res.status(201).json({
            success: true,
            message: 'Product created successfully',
            product
        });
    } catch (error) {
        console.error('Create product error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to create product'
        });
    }
};

// Update existing product
export const updateProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, description, price, quantity, category, unit, available } = req.body;

        const product = await Product.findById(id);
        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        // Update fields
        if (name) product.name = name;
        if (description !== undefined) product.description = description;
        if (price) product.price = parseFloat(price);
        if (quantity !== undefined) product.quantity = parseInt(quantity);
        if (category) product.category = category;
        if (unit) product.unit = unit;
        if (available !== undefined) product.available = available !== 'false' && available !== false;

        // Handle image update
        if (req.file) {
            // Delete old image if exists
            if (product.image) {
                const oldImagePath = path.join(process.cwd(), 'public', product.image);
                if (fs.existsSync(oldImagePath)) {
                    fs.unlinkSync(oldImagePath);
                }
            }
            product.image = `/uploads/products/${req.file.filename}`;
        }

        await product.save();

        res.json({
            success: true,
            message: 'Product updated successfully',
            product
        });
    } catch (error) {
        console.error('Update product error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to update product'
        });
    }
};

// Delete product
export const deleteProduct = async (req, res) => {
    try {
        const { id } = req.params;

        const product = await Product.findById(id);
        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        // Delete image file if exists
        if (product.image) {
            const imagePath = path.join(process.cwd(), 'public', product.image);
            if (fs.existsSync(imagePath)) {
                fs.unlinkSync(imagePath);
            }
        }

        await Product.findByIdAndDelete(id);

        res.json({
            success: true,
            message: 'Product deleted successfully'
        });
    } catch (error) {
        console.error('Delete product error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to delete product'
        });
    }
};

// Toggle product availability
export const updateProductAvailability = async (req, res) => {
    try {
        const { id } = req.params;
        const { available } = req.body;

        const product = await Product.findById(id);
        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        product.available = available;
        await product.save();

        res.json({
            success: true,
            message: `Product ${available ? 'enabled' : 'disabled'} successfully`,
            product
        });
    } catch (error) {
        console.error('Update availability error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to update availability'
        });
    }
};

// Update product stock with tracking
export const updateProductStock = async (req, res) => {
    try {
        const { id } = req.params;
        const { quantity, action, amount, reason } = req.body;

        const product = await Product.findById(id);
        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        const oldQuantity = product.quantity;

        // Update quantity
        product.quantity = parseInt(quantity);

        // Track stock adjustment (you can create a StockLog model for this)
        const adjustment = {
            productId: id,
            oldQuantity,
            newQuantity: product.quantity,
            action,
            amount: parseInt(amount),
            reason: reason || 'Manual adjustment',
            adjustedBy: req.user._id,
            timestamp: new Date()
        };

        // You can save this to a StockLog collection if needed
        console.log('Stock adjustment:', adjustment);

        await product.save();

        res.json({
            success: true,
            message: 'Stock updated successfully',
            product,
            adjustment
        });
    } catch (error) {
        console.error('Update stock error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to update stock'
        });
    }
};

// Get all products with optional vendor filter
export const getAllProducts = async (req, res) => {
    try {
        const { vendorId } = req.query;
        
        const filter = vendorId ? { vendorId } : {};
        const products = await Product.find(filter)
            .populate('vendorId', 'name email')
            .sort({ createdAt: -1 });

        res.json({
            success: true,
            products
        });
    } catch (error) {
        console.error('Get products error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to get products'
        });
    }
};

// Get single product
export const getProductById = async (req, res) => {
    try {
        const { id } = req.params;

        const product = await Product.findById(id).populate('vendorId', 'name email');
        
        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        res.json({
            success: true,
            product
        });
    } catch (error) {
        console.error('Get product error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to get product'
        });
    }
};

// Auto-reduce stock when order is placed (called from order controller)
export const reduceStock = async (items) => {
    try {
        for (const item of items) {
            const product = await Product.findById(item.productId);
            if (product && product.quantity >= item.quantity) {
                product.quantity -= item.quantity;
                await product.save();
                console.log(`Reduced stock for ${product.name}: ${item.quantity} units`);
            } else {
                console.warn(`Insufficient stock for product: ${item.productId}`);
            }
        }
    } catch (error) {
        console.error('Auto-reduce stock error:', error);
    }
};

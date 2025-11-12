import express from 'express';
import multer from 'multer';
import path from 'path';
import { authRequired } from '../middleware/auth.js';
import {
    createProduct,
    updateProduct,
    deleteProduct,
    updateProductAvailability,
    updateProductStock,
    getAllProducts,
    getProductById
} from '../controllers/adminProductController.js';

const router = express.Router();

// Configure multer for image upload
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'public/uploads/products');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'product-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
    fileFilter: (req, file, cb) => {
        const allowedTypes = /jpeg|jpg|png|gif|webp/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mimetype = allowedTypes.test(file.mimetype);

        if (mimetype && extname) {
            return cb(null, true);
        } else {
            cb(new Error('Only image files are allowed!'));
        }
    }
});

// All routes require admin authentication
router.use(authRequired('admin'));

// Create new product
router.post('/products', upload.single('image'), createProduct);

// Update product
router.put('/products/:id', upload.single('image'), updateProduct);

// Delete product
router.delete('/products/:id', deleteProduct);

// Toggle product availability
router.patch('/products/:id/availability', updateProductAvailability);

// Update product stock (add/reduce/set)
router.patch('/products/:id/stock', updateProductStock);

// Get all products (with optional vendor filter)
router.get('/products', getAllProducts);

// Get single product
router.get('/products/:id', getProductById);

export default router;

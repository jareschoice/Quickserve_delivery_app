import express from 'express';
import {
  getAllVendors,
  getVendorProducts,
  createOrder,
  trackOrder,
  getVendorOrders,
  updateOrderStatus,
  getVendorEarnings,
  getReadyOrders,
  claimOrder,
  confirmDelivery,
  getDispatcherStats,
  getAllOrders,
  getEventSummary,
  verifyPayment
} from '../controllers/eventController.js';
import { protect, authorize } from '../middleware/auth.js';

const router = express.Router();

// =======================
// PUBLIC ROUTES (Consumer)
// =======================
router.get('/vendors', getAllVendors);
router.get('/vendors/:vendorId/products', getVendorProducts);
router.post('/orders', createOrder);
router.get('/orders/:orderId', trackOrder);
router.post('/orders/verify-payment', verifyPayment);

// =======================
// VENDOR ROUTES
// =======================
router.get('/vendor/orders', protect, authorize('vendor'), getVendorOrders);
router.patch('/vendor/orders/:orderId/status', protect, authorize('vendor'), updateOrderStatus);
router.get('/vendor/earnings', protect, authorize('vendor'), getVendorEarnings);

// =======================
// DISPATCHER ROUTES
// =======================
router.get('/dispatcher/ready-orders', protect, authorize('dispatcher'), getReadyOrders);
router.post('/dispatcher/claim', protect, authorize('dispatcher'), claimOrder);
router.post('/dispatcher/confirm', protect, authorize('dispatcher'), confirmDelivery);
router.get('/dispatcher/stats', protect, authorize('dispatcher'), getDispatcherStats);

// =======================
// ADMIN ROUTES
// =======================
router.get('/admin/orders', protect, authorize('admin'), getAllOrders);
router.get('/admin/summary', protect, authorize('admin'), getEventSummary);

export default router;

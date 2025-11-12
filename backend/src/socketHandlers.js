import { Server } from 'socket.io';

/**
 * Initialize Socket.IO event handlers.
 * @param {Server} io - The Socket.IO server instance.
 */
export function initializeSocketHandlers(io) {
  io.on('connection', (socket) => {
    console.log(`🟢 Socket connected: ${socket.id}`);

    // Welcome message
    socket.emit('welcome', { message: 'Connected to QuickServe socket!' });

    // Handle order events
    socket.on('order:placed', (order) => {
      console.log('📦 New order placed:', order);
      io.emit('order:update', { type: 'placed', order });
    });

    socket.on('order:status', (statusUpdate) => {
      const { orderId, status } = statusUpdate;
      console.log(`🔄 Order ${orderId} status updated to ${status}`);
      io.to(`order:${orderId}`).emit('order:status', statusUpdate);
    });

    // Handle wallet updates
    socket.on('wallet:update', (walletUpdate) => {
      const { userId, amount } = walletUpdate;
      console.log(`💰 Wallet updated for user ${userId}: ₦${amount}`);
      io.to(`user:${userId}`).emit('wallet:update', walletUpdate);
    });

    // Handle chat messages
    socket.on('chat:message', (message = {}) => {
      try {
        const { to, toRole, from, fromRole, content } = message || {};
        if (!content) return;
        if (toRole) {
          console.log(`💬 Message from ${from || 'anon'} -> role:${toRole}: ${content}`);
          io.to(`role:${toRole}`).emit('chat:message', { from, fromRole, content, toRole, ts: Date.now() });
        } else if (to) {
          console.log(`💬 Message from ${from || 'anon'} -> user:${to}: ${content}`);
          io.to(`user:${to}`).emit('chat:message', { from, fromRole, content, to, ts: Date.now() });
        } else {
          // fallback broadcast to admins
          io.to('role:admin').emit('chat:message', { from, fromRole, content, ts: Date.now() });
        }
      } catch {}
    });

    // Disconnect event
    socket.on('disconnect', () => {
      console.log(`🔴 Socket disconnected: ${socket.id}`);
    });
  });
}
#!/usr/bin/env node
/**
 * Simple Socket.IO client to watch order lifecycle events locally.
 * Usage: node watch-order-events.js --url http://localhost:5555
 *
 * It'll log incoming events for these namespaces:
 * - order:placed, order:accepted, order:preparing, order:ready
 * - order:assigned, order:in_transit, order:arrived, order:delivered
 * - order:update, order:notification, order:dispatch_requested
 */

import { io as Client } from "socket.io-client";
import yargs from 'yargs/yargs';
import { hideBin } from 'yargs/helpers';

const argv = yargs(hideBin(process.argv))
  .option('url', { type: 'string', default: 'http://localhost:5555' })
  .option('identify', { type: 'string', describe: 'Identify as a user id to join that user room (e.g., vendor id)' })
  .argv;
const URL = argv.url;

console.log(`Connecting to Socket.IO server at ${URL} ...`);

const socket = Client(URL, { transports: ['websocket'], reconnectionAttempts: 5 });

const watchEvents = [
  'order:placed','order:accepted','order:preparing','order:ready',
  'order:assigned','order:in_transit','order:arrived','order:delivered',
  'order:update','order:notification','order:dispatch_requested','order:ready','order:dispatch_requested'
];

socket.on('connect', () => {
  console.log('Connected as client id', socket.id);
  if (argv.identify) {
    console.log('Identifying as user:', argv.identify);
    socket.emit('identify', String(argv.identify));
  }
});

socket.on('connect_error', (err) => {
  console.error('Connection error', err.message || err);
});

socket.on('disconnect', (reason) => {
  console.log('Disconnected:', reason);
});

for (const ev of watchEvents) {
  socket.on(ev, (payload) => {
    console.log(`EVENT: ${ev}`);
    console.dir(payload, { depth: 4 });
  });
}

// Also listen to all events (for debugging)
socket.onAny((event, ...args) => {
  // filter out frequent heartbeats
  if (watchEvents.indexOf(event) === -1) return;
});

process.on('SIGINT', () => {
  console.log('Shutting down client');
  socket.close();
  process.exit(0);
});

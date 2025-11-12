const http = require('http');
const fs = require('fs');

const data = JSON.stringify({
  phone: '+2348000000001',
  seatNumber: 1,
  vendorId: '690ddfa67dbd3980879a2c8e',
  items: [{ name: 'Demo Plate', qty: 1, price: 500 }]
});

const options = {
  hostname: 'localhost',
  port: 5555,
  path: '/api/event/orders',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data)
  }
};

const req = http.request(options, (res) => {
  let body = '';
  res.setEncoding('utf8');
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => {
    console.log('STATUS', res.statusCode);
    fs.writeFileSync('created_order.json', body);
    console.log('Saved created_order.json');
  });
});

req.on('error', (e) => {
  console.error('Request error', e.message);
});

req.write(data);
req.end();

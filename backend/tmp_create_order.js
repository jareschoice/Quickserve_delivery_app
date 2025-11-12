import fetch from 'node-fetch';

async function run(){
  const url = 'http://localhost:5555/api/event/orders';
  const body = {
    phone: '+2348000000001',
    seatNumber: 1,
    vendorId: '690ddfa67dbd3980879a2c8e',
    items: [{ name: 'Demo Plate', qty: 1, price: 500 }]
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });

  const data = await res.text();
  console.log('STATUS', res.status);
  console.log(data);
}

run().catch(e => { console.error(e); process.exit(1); });

import { expect } from 'chai';
import request from 'supertest';
import { app } from '../server.js'; // Adjust path if needed

describe('API smoke tests', () => {
  it('GET /health should return 200 OK', async () => {
    const res = await request(app).get('/health');
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('status', 'ok');
  });
});

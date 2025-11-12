import { expect } from 'chai'
import buildOrderRedirect from '../src/utils/redirect.js'

describe('buildOrderRedirect', () => {
  const backendHost = 'http://localhost:5555'
  const frontendUrl = 'http://127.0.0.1:5500/event-frontend'

  it('uses metadata redirect when allowed and contains frontend path', () => {
    const metadata = 'http://127.0.0.1:5500/event-frontend/track.html'
    const r = buildOrderRedirect({ metadataRedirect: metadata, referer: null, frontendUrl, backendHost, orderId: 'ORD1', token: 'T' })
    expect(r).to.contain('127.0.0.1:5500')
    expect(r).to.contain('orderId=ORD1')
    expect(r).to.contain('token=')
  })

  it('falls back to backendHost when referer is disallowed and no FRONTEND_URL', () => {
    const referer = 'http://malicious.example'
    const r = buildOrderRedirect({ metadataRedirect: null, referer, frontendUrl: null, backendHost, orderId: 'ORD2' })
    // referer not allowed and no frontendUrl provided: should fallback to backendHost
    expect(r).to.contain('localhost:5555')
    expect(r).to.contain('orderId=ORD2')
  })

  it('uses FRONTEND_URL when referer and metadata absent', () => {
    const r = buildOrderRedirect({ metadataRedirect: null, referer: null, frontendUrl, backendHost, orderId: 'ORD3' })
    expect(r).to.contain('127.0.0.1:5500')
    expect(r).to.contain('orderId=ORD3')
  })

  it('sanitizes trailing slashes and adds track.html when needed', () => {
    const base = 'http://127.0.0.1:5500/'
    const r = buildOrderRedirect({ metadataRedirect: null, referer: base, frontendUrl: null, backendHost, orderId: 'ORD4' })
    expect(r).to.contain('/event-frontend/track.html')
    expect(r).to.contain('orderId=ORD4')
  })
})

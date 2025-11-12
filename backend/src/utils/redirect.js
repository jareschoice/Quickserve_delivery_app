import url from 'url'

// Build a safe redirect URL for order tracking.
// Prefers: metadataRedirect -> referer -> frontendUrl -> backendHost
// Falls back to backendHost when candidate base is not allowed.
export function buildOrderRedirect({ metadataRedirect, referer, frontendUrl, backendHost, orderId, token, allowedOrigins = [] }) {
  const candidates = [metadataRedirect, referer, frontendUrl, backendHost].filter(Boolean)

  // Normalize candidate (remove trailing slash)
  const normalize = (s) => String(s).replace(/\/$/, '')

  const isAllowed = (candidate) => {
    if (!candidate) return false
    const c = normalize(candidate)
    // If allowedOrigins provided, check startsWith any
    if (allowedOrigins && allowedOrigins.length) {
      for (const a of allowedOrigins) {
        if (!a) continue
        if (c.startsWith(normalize(a))) return true
      }
      return false
    }
    // Default allow localhost and backendHost
    try {
      const parsed = url.parse(c)
      const host = parsed.host || ''
      if (host.includes('localhost') || host.startsWith('127.') || host === url.parse(backendHost).host) return true
    } catch {}
    return false
  }

  let base = null
  for (const cand of candidates) {
    if (isAllowed(cand)) { base = normalize(cand); break }
  }

  // If none allowed, fallback to backendHost
  if (!base) base = normalize(backendHost)

  const hasFrontendPath = base.includes('/event-frontend/') || base.includes('track.html')
  let redirectTarget = hasFrontendPath ? base : `${base}/event-frontend/track.html`
  const sep = redirectTarget.includes('?') ? '&' : '?'
  const parts = [`orderId=${orderId}`]
  if (token) parts.push(`token=${encodeURIComponent(token)}`)
  return `${redirectTarget}${sep}${parts.join('&')}`
}

export default buildOrderRedirect

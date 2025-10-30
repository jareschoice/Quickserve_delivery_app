import axios from 'axios'

export const getDistanceKm = async (origin, destination) => {
  // origin/destination: { lat, lng }
  const gkey = process.env.GOOGLE_MAPS_API_KEY
  const mkey = process.env.MAPBOX_API_KEY
  try {
    if (gkey) {
      const url = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${origin.lat},${origin.lng}&destinations=${destination.lat},${destination.lng}&key=${gkey}`
      const { data } = await axios.get(url)
      const meters = data?.rows?.[0]?.elements?.[0]?.distance?.value
      if (meters) return meters / 1000
    } else if (mkey) {
      const url = `https://api.mapbox.com/directions-matrix/v1/mapbox/driving/${origin.lng},${origin.lat};${destination.lng},${destination.lat}?access_token=${mkey}`
      const { data } = await axios.get(url)
      const meters = data?.distances?.[0]?.[1]
      if (meters) return meters / 1000
    }
  } catch (e) {
    console.warn('Distance API error:', e.message)
  }
  // fallback to straight-line approximation
  const R = 6371
  const dLat = (destination.lat - origin.lat) * Math.PI / 180
  const dLon = (destination.lng - origin.lng) * Math.PI / 180
  const a = Math.sin(dLat/2) ** 2 + Math.cos(origin.lat*Math.PI/180) * Math.cos(destination.lat*Math.PI/180) * Math.sin(dLon/2) ** 2
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  return R * c
}

export const calculateDeliveryFee = (distanceKm = 0, currency = 'NGN') => {
  // basic zonal scaling; can be extended per-city via env
  const base = Number(process.env.FARE_BASE || 300)
  const perKm = Number(process.env.FARE_PER_KM || 120)
  const amount = Math.round(base + perKm * Math.max(0, distanceKm))
  // currency conversion placeholder: currently returns NGN amount
  return amount
};

export const quickserveFee = () => 50; // constant for now

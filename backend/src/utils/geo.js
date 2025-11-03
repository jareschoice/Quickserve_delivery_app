// ===============================
// FILE: backend/src/utils/geo.js
// ===============================
export const isValidLatLng = (lat, lng) => {
  if (lat === undefined || lng === undefined) return false;
  const la = Number(lat);
  const ln = Number(lng);
  if (Number.isNaN(la) || Number.isNaN(ln)) return false;
  if (la < -90 || la > 90) return false;
  if (ln < -180 || ln > 180) return false;
  return true;
}

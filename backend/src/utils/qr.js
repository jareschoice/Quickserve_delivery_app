import QRCode from "qrcode";
import jwt from "jsonwebtoken";

const QR_TTL_SEC = 60 * 60; // 1 hour

export const signQrToken = (orderId, role) => {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error("JWT_SECRET missing for QR");
  const token = jwt.sign({ sub: `qr:${orderId}:${role}`, orderId, role }, secret, {
    expiresIn: QR_TTL_SEC,
  });
  return token;
};

export const verifyQrToken = (token, orderId, role) => {
  const secret = process.env.JWT_SECRET;
  const decoded = jwt.verify(token, secret);
  if (decoded.orderId !== String(orderId) || decoded.role !== role) {
    throw new Error("QR token mismatch");
  }
  return decoded;
};

export const generateQrPngBase64 = async (data) => {
  const pngDataUrl = await QRCode.toDataURL(data);
  // strip prefix 'data:image/png;base64,'
  const base64 = pngDataUrl.split(",")[1];
  return base64;
};

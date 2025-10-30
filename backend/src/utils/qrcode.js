import QRCode from 'qrcode'
export async function generateQR(text){ return QRCode.toDataURL(text) }

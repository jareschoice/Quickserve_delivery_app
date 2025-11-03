export const generatePaymentReceiptHTML = ({ name, amount, reference, balance, date }) => {
  return `
  <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;border-radius:10px;border:1px solid #e2e8f0;overflow:hidden">
    <div style="background-color:#16a34a;padding:20px;text-align:center;color:#fff;">
      <h2>QuickServe Payment Receipt</h2>
    </div>
    <div style="padding:20px;background-color:#fff;">
      <p style="font-size:15px;color:#333;">Hi <b>${name}</b>,</p>
      <p>Your wallet has been successfully funded on <b>${new Date(date).toLocaleString()}</b>.</p>
      <table style="width:100%;margin-top:15px;border-collapse:collapse;">
        <tr style="background:#f9fafb;">
          <td style="padding:10px;">Amount</td>
          <td style="padding:10px;font-weight:bold;">₦${Number(amount).toLocaleString()}</td>
        </tr>
        <tr>
          <td style="padding:10px;">Transaction Reference</td>
          <td style="padding:10px;">${reference}</td>
        </tr>
        <tr style="background:#f9fafb;">
          <td style="padding:10px;">Updated Wallet Balance</td>
          <td style="padding:10px;">₦${Number(balance).toLocaleString()}</td>
        </tr>
      </table>
      <p style="margin-top:20px;font-size:14px;color:#555;">
        Thank you for trusting <b>QuickServe</b> 💚. You can use your wallet balance for orders, deliveries, or vendor services.
      </p>
    </div>
    <div style="background:#facc15;padding:15px;text-align:center;font-size:13px;color:#111;">
      © ${new Date().getFullYear()} QuickServe — All rights reserved.
    </div>
  </div>
  `
}

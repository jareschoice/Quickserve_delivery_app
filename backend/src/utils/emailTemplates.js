export const baseEmail = (title, bodyHtml) => `
  <div style="font-family:Arial,sans-serif;background:#f7f7f7;padding:24px">
    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="max-width:600px;margin:auto;background:white;border-radius:12px;overflow:hidden">
      <tr><td style="background:#0f9d58;color:white;padding:18px 24px;font-size:18px;font-weight:700">QuickServe</td></tr>
      <tr><td style="padding:24px">
        <h2 style="margin:0 0 8px 0;color:#222">${title}</h2>
        <div style="font-size:14px;color:#444;line-height:1.6">${bodyHtml}</div>
      </td></tr>
      <tr><td style="padding:16px 24px;color:#666;font-size:12px;background:#fafafa">
        This is an automated message from QuickServe • © ${new Date().getFullYear()}
      </td></tr>
    </table>
  </div>
`

export const verificationEmail = (verifyUrl) => baseEmail(
  'Verify your email',
  `Please verify your email by clicking the button below:<br/><br/>
   <a href="${verifyUrl}" style="display:inline-block;padding:10px 16px;background:#0f9d58;color:white;text-decoration:none;border-radius:6px">Verify Email</a>`
)

export const orderStatusEmail = (status, orderId) => baseEmail(
  'Order update',
  `Your order <b>#${orderId}</b> status is now: <b>${status}</b>.`
)

import { sendMail } from "../lib/email.js";

export const notifyAdmin = async (subject, html) => {
  const admin = process.env.EMAIL_USER;
  try {
    await sendMail({ to: admin, subject, html });
  } catch (e) {
    console.error("Failed to notify admin:", e.message);
  }
};

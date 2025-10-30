// src/utils/emailClient.js
import nodemailer from "nodemailer";

let lastVerifyOk = null;

export const sendEmail = async ({ to, subject, html, text }) => {
  try {
    const transporter = nodemailer.createTransport({
      host: process.env.EMAIL_HOST || "smtp.gmail.com",
      port: parseInt(process.env.EMAIL_PORT || "587"),
      secure: process.env.EMAIL_SECURE === "true", // false for 587, true for 465
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
      tls: { rejectUnauthorized: false }, // ✅ Helps on shared hosts; keep false to avoid cert issues
    });

    // First-time or periodic transporter verification (non-fatal)
    if (lastVerifyOk === null) {
      try {
        await transporter.verify();
        lastVerifyOk = true;
        console.log(`📮 SMTP ready: ${process.env.EMAIL_HOST}:${process.env.EMAIL_PORT} secure=${process.env.EMAIL_SECURE}`);
      } catch (verr) {
        lastVerifyOk = false;
        console.warn("⚠️ SMTP verification failed (will still attempt send):", verr?.message || verr);
      }
    }

    const mailOptions = {
      from: `QuickServe <${process.env.EMAIL_FROM || process.env.EMAIL_USER}>`,
      to,
      subject,
      html,
      text,
    };

    const info = await transporter.sendMail(mailOptions);

    console.log(`✅ Email sent successfully to ${to}`);
    console.log(`📧 Subject: ${subject}`);
    console.log(`🪪 Message ID: ${info.messageId}`);

    return info;
  } catch (error) {
    console.error("❌ Email sending failed:", error?.response || error?.message || error);
    throw new Error("Email sending failed. Please check SMTP settings or credentials.");
  }
};

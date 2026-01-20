import { Resend } from "resend";

const resendApiKey = process.env.RESEND_API_KEY;
const resend = resendApiKey ? new Resend(resendApiKey) : null;
if (!resendApiKey) {
  console.warn("⚠️ RESEND_API_KEY is missing. Email sending is disabled.");
}

const FROM =
  process.env.RESEND_FROM || "onboarding@resend.dev"; // switch to hello@soiree.app after domain verification

const DEV_TO = process.env.RESEND_DEV_TO || null;
const isProd = process.env.NODE_ENV === "production";

function resolveTo(to) {
  return !isProd && DEV_TO ? DEV_TO : to;
}

export async function sendWelcomeEmail({ to, firstName }) {
  if (!resend) {
    console.warn("📧 Skipping welcome email (Resend not configured):", to);
    return { success: false, error: "Missing RESEND_API_KEY" };
  }
  const resolvedTo = resolveTo(to);
  if (!isProd && DEV_TO) {
    console.log("📧 Dev override active; redirecting email to:", resolvedTo);
  }
  return resend.emails.send({
    from: FROM,
    to: resolvedTo,
    subject: "Welcome to Soiree 👋",
    html: `
      <p>hi ${firstName || "there"},</p>
      <p>welcome to <strong>soiree</strong> — you’re officially in.</p>
      <p>find events, grab tickets, and save your favorites.</p>
      <p><a href="https://soiree.app">get started</a></p>
      <p>— soiree</p>
    `,
  });
}

export async function sendPaymentEmail({ to, firstName, itemName, amountUsd }) {
  if (!resend) {
    console.warn("📧 Skipping payment email (Resend not configured):", to);
    return { success: false, error: "Missing RESEND_API_KEY" };
  }
  const resolvedTo = resolveTo(to);
  if (!isProd && DEV_TO) {
    console.log("📧 Dev override active; redirecting email to:", resolvedTo);
  }
  return resend.emails.send({
    from: FROM,
    to: resolvedTo,
    subject: "Payment confirmed — you’re in 🎟️",
    html: `
      <p>hi ${firstName || "there"},</p>
      <p>nice — your payment went through.</p>
      <p><strong>you’re signed up for:</strong> ${itemName}<br/>
         <strong>amount:</strong> $${amountUsd}</p>
      <p>see you there,<br/>soiree</p>
    `,
  });
}


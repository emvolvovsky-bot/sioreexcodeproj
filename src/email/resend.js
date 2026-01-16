import { Resend } from "resend";

const resend = new Resend(process.env.RESEND_API_KEY);

const FROM =
  process.env.RESEND_FROM || "onboarding@resend.dev"; // switch to hello@soiree.app after domain verification

const DEV_TO = "soiree.app@outlook.com";
const isProd = process.env.NODE_ENV === "production";

function resolveTo(to) {
  return isProd ? to : DEV_TO;
}

export async function sendWelcomeEmail({ to, firstName }) {
  return resend.emails.send({
    from: FROM,
    to: resolveTo(to),
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
  return resend.emails.send({
    from: FROM,
    to: resolveTo(to),
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


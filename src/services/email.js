import nodemailer from "nodemailer";

// Create reusable transporter object using SMTP transport
// For development, we'll use Ethereal Email (fake SMTP for testing)
// For production, configure with real SMTP credentials

let transporter = null;

// Initialize email transporter
async function initEmailTransporter() {
  // If SMTP credentials are provided, use them
  if (process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS) {
    transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: process.env.SMTP_PORT || 587,
      secure: process.env.SMTP_SECURE === "true", // true for 465, false for other ports
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
    console.log("✅ Email service initialized with SMTP");
  } else {
    // Use Ethereal Email for development/testing (creates fake inbox)
    try {
      const testAccount = await nodemailer.createTestAccount();
      transporter = nodemailer.createTransport({
        host: "smtp.ethereal.email",
        port: 587,
        secure: false,
        auth: {
          user: testAccount.user,
          pass: testAccount.pass,
        },
      });
      console.log("✅ Email service initialized with Ethereal (test account)");
      console.log("📧 Test emails will be sent to: https://ethereal.email");
      console.log("📧 Test account:", testAccount.user);
    } catch (err) {
      console.error("❌ Failed to create Ethereal test account:", err);
      console.log("⚠️ Email service disabled - emails will not be sent");
      transporter = null;
    }
  }
}

// Initialize on module load (non-blocking)
// Don't wait for initialization - it will happen when first email is sent
let isInitializing = false;
initEmailTransporter()
  .then(() => {
    console.log("✅ Email service ready");
  })
  .catch(err => {
    console.error("❌ Failed to initialize email service:", err);
    console.log("⚠️ Email service will retry on first email send");
  });

/**
 * Send welcome email after signup
 */
export async function sendWelcomeEmail(email, name) {
  try {
    // Initialize transporter if not already initialized (non-blocking)
    if (!transporter && !isInitializing) {
      isInitializing = true;
      await initEmailTransporter().catch(err => {
        console.error("❌ Email initialization failed:", err);
        isInitializing = false;
      });
      isInitializing = false;
    }
    
    // If still no transporter, skip email (don't block signup)
    if (!transporter) {
      console.log("⚠️ Email service not available - skipping welcome email");
      return { success: false, error: "Email service not initialized" };
    }

    const mailOptions = {
      from: process.env.SMTP_FROM || "Sioree <noreply@sioree.com>",
      to: email,
      subject: "Welcome to Sioree! 🎉",
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
              line-height: 1.6;
              color: #333;
              max-width: 600px;
              margin: 0 auto;
              padding: 20px;
              background-color: #000;
            }
            .container {
              background-color: #1a1a1a;
              border-radius: 12px;
              padding: 40px;
              border: 1px solid #333;
            }
            h1 {
              color: #00d4ff;
              font-size: 28px;
              margin-bottom: 20px;
            }
            p {
              color: #e0e0e0;
              font-size: 16px;
              margin-bottom: 15px;
            }
            .highlight {
              color: #00d4ff;
              font-weight: 600;
            }
            .footer {
              margin-top: 30px;
              padding-top: 20px;
              border-top: 1px solid #333;
              color: #888;
              font-size: 14px;
              text-align: center;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>Welcome to Sioree! 🎉</h1>
            <p>Hi ${name || "there"},</p>
            <p>Thank you for signing up for <span class="highlight">Sioree</span> - your nightlife infrastructure platform!</p>
            <p>We're excited to have you join our community. Whether you're a host, partier, talent, or brand, Sioree is here to help you connect and create amazing experiences.</p>
            <p>Get started by:</p>
            <ul style="color: #e0e0e0;">
              <li>Exploring events near you</li>
              <li>Creating your first event (if you're a host)</li>
              <li>Connecting with talent and brands</li>
              <li>Building your network</li>
            </ul>
            <p>If you have any questions, feel free to reach out to our support team.</p>
            <p>Welcome aboard!</p>
            <p style="margin-top: 30px;">Best regards,<br>The Sioree Team</p>
            <div class="footer">
              <p>This is an automated message. Please do not reply to this email.</p>
            </div>
          </div>
        </body>
        </html>
      `,
      text: `
Welcome to Sioree! 🎉

Hi ${name || "there"},

Thank you for signing up for Sioree - your nightlife infrastructure platform!

We're excited to have you join our community. Whether you're a host, partier, talent, or brand, Sioree is here to help you connect and create amazing experiences.

Get started by:
- Exploring events near you
- Creating your first event (if you're a host)
- Connecting with talent and brands
- Building your network

If you have any questions, feel free to reach out to our support team.

Welcome aboard!

Best regards,
The Sioree Team

---
This is an automated message. Please do not reply to this email.
      `,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log("✅ Welcome email sent to:", email);
    console.log("📧 Message ID:", info.messageId);
    
    // If using Ethereal, log the preview URL
    if (process.env.NODE_ENV !== "production" && !process.env.SMTP_HOST) {
      console.log("📧 Preview URL:", nodemailer.getTestMessageUrl(info));
    }
    
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error("❌ Error sending welcome email:", error);
    // Don't throw error - email failure shouldn't break signup
    return { success: false, error: error.message };
  }
}

/**
 * Send login notification email
 */
export async function sendLoginEmail(email, name) {
  try {
    // Initialize transporter if not already initialized (non-blocking)
    if (!transporter && !isInitializing) {
      isInitializing = true;
      await initEmailTransporter().catch(err => {
        console.error("❌ Email initialization failed:", err);
        isInitializing = false;
      });
      isInitializing = false;
    }
    
    // If still no transporter, skip email (don't block login)
    if (!transporter) {
      console.log("⚠️ Email service not available - skipping login email");
      return { success: false, error: "Email service not initialized" };
    }

    const mailOptions = {
      from: process.env.SMTP_FROM || "Sioree <noreply@sioree.com>",
      to: email,
      subject: "Welcome back to Sioree! 👋",
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
              line-height: 1.6;
              color: #333;
              max-width: 600px;
              margin: 0 auto;
              padding: 20px;
              background-color: #000;
            }
            .container {
              background-color: #1a1a1a;
              border-radius: 12px;
              padding: 40px;
              border: 1px solid #333;
            }
            h1 {
              color: #00d4ff;
              font-size: 28px;
              margin-bottom: 20px;
            }
            p {
              color: #e0e0e0;
              font-size: 16px;
              margin-bottom: 15px;
            }
            .highlight {
              color: #00d4ff;
              font-weight: 600;
            }
            .footer {
              margin-top: 30px;
              padding-top: 20px;
              border-top: 1px solid #333;
              color: #888;
              font-size: 14px;
              text-align: center;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>Welcome back! 👋</h1>
            <p>Hi ${name || "there"},</p>
            <p>Thank you for signing in to <span class="highlight">Sioree</span>!</p>
            <p>We're glad to have you back. Continue exploring events, connecting with others, and creating amazing experiences.</p>
            <p>If this wasn't you, please contact our support team immediately.</p>
            <p style="margin-top: 30px;">Best regards,<br>The Sioree Team</p>
            <div class="footer">
              <p>This is an automated message. Please do not reply to this email.</p>
            </div>
          </div>
        </body>
        </html>
      `,
      text: `
Welcome back! 👋

Hi ${name || "there"},

Thank you for signing in to Sioree!

We're glad to have you back. Continue exploring events, connecting with others, and creating amazing experiences.

If this wasn't you, please contact our support team immediately.

Best regards,
The Sioree Team

---
This is an automated message. Please do not reply to this email.
      `,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log("✅ Login email sent to:", email);
    console.log("📧 Message ID:", info.messageId);
    
    // If using Ethereal, log the preview URL
    if (process.env.NODE_ENV !== "production" && !process.env.SMTP_HOST) {
      console.log("📧 Preview URL:", nodemailer.getTestMessageUrl(info));
    }
    
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error("❌ Error sending login email:", error);
    // Don't throw error - email failure shouldn't break login
    return { success: false, error: error.message };
  }
}


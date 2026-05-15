// functions/email.js

const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

async function getEmailConfigFromFirestore() {
    console.log("Fetching email config from Firestore...");
    const doc = await admin.firestore().collection('app_accounts').doc('q35FN8T1MUBjb7XokFjl').get();

    if (!doc.exists) {
        throw new Error("Email config not found in app_account/mail_config");
    }

    const data = doc.data();
    console.log("Email config data:", data);
    console.log("Email config user:", data["email"], "password:", data["password"]);
    return {
        user: data["email"],       // e.g. "your@gmail.com"
        pass: data["password"],    // e.g. App Password or SMTP key
    };
}

async function sendEmail({ to, subject, text }) {
    const config = await getEmailConfigFromFirestore();

    const transporter = nodemailer.createTransport({
        service: "gmail",
        auth: {
            user: config.user,
            pass: config.pass,
        },
    });

    const mailOptions = {
        from: config.user,
        to,
        subject,
        text,
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log("✅ Email sent to:", to);
    } catch (error) {
        console.error("❌ Email sending error:", error);
        throw error;
    }
}

module.exports = {
    sendEmail,
};

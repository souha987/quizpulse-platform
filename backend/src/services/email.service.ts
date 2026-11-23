import nodemailer, { Transporter } from 'nodemailer';

export class EmailService {
  private getTransporter(): Transporter | null {
    const service = process.env.SMTP_SERVICE || process.env.EMAIL_SERVICE;
    const user = process.env.SMTP_USER || process.env.GMAIL_USER;
    const pass = process.env.SMTP_PASS || process.env.GMAIL_APP_PASSWORD;
    const host = process.env.SMTP_HOST;
    const port = parseInt(process.env.SMTP_PORT || '587', 10);

    if (!user || !pass) {
      return null;
    }

    try {
      // Configuration optimisée pour Gmail
      if (service?.toLowerCase() === 'gmail' || host?.includes('gmail') || user.endsWith('@gmail.com')) {
        return nodemailer.createTransport({
          service: 'gmail',
          auth: {
            user,
            pass: pass.replace(/\s+/g, ''), // Nettoyer les espaces éventuels des mots de passe d'application Google (ex: 'abcd efgh ijkl mnop')
          },
          connectionTimeout: 15000,
          greetingTimeout: 15000,
          socketTimeout: 15000,
        });
      }

      // Configuration SMTP générique (ex: Brevo, Mailgun, Sendgrid, etc.)
      if (host) {
        return nodemailer.createTransport({
          host,
          port,
          secure: port === 465,
          auth: { user, pass },
          connectionTimeout: 15000,
          greetingTimeout: 15000,
          socketTimeout: 15000,
        });
      }
    } catch (err) {
      console.error('[EMAIL SERVICE] Erreur lors de la création du transporteur SMTP:', err);
      return null;
    }

    return null;
  }

  async sendVerificationEmail(to: string, prenom: string, code: string): Promise<boolean> {
    const user = process.env.SMTP_USER || process.env.GMAIL_USER;
    const pass = process.env.SMTP_PASS || process.env.GMAIL_APP_PASSWORD;
    const transporter = this.getTransporter();

    // 1. Toujours afficher le code dans la console du serveur pour les tests et la traçabilité
    console.log(`\n======================================================`);
    console.log(`[EMAIL SERVICE] Tentative d'envoi d'e-mail de vérification`);
    console.log(`[EMAIL SERVICE] Destinataire: ${prenom} <${to}>`);
    console.log(`[EMAIL SERVICE] CODE DE CONFIRMATION: ${code}`);
    if (!user || !pass) {
      console.log(`[EMAIL SERVICE INFO] SMTP non configuré dans .env (SMTP_USER ou SMTP_PASS manquant).`);
      console.log(`[EMAIL SERVICE ASTUCE] Pour activer l'envoi réel via Gmail, configurez SMTP_USER et SMTP_PASS (Mot de passe d'application Google 16 caractères) dans backend/.env.`);
    } else {
      console.log(`[EMAIL SERVICE INFO] Envoi réel en cours via le compte Gmail: ${user}...`);
    }
    console.log(`======================================================\n`);

    const subject = 'Confirmez votre adresse e-mail - QuizPulse';
    const text = `Bonjour ${prenom},\n\nMerci de vous être inscrit sur QuizPulse !\nVotre code de confirmation est : ${code}\nCe code est valable pendant 24 heures.\n\nL'équipe QuizPulse`;
    const html = `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 28px; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #4f46e5; margin: 0; font-size: 30px; letter-spacing: -0.5px;">QuizPulse</h1>
          <p style="color: #64748b; margin-top: 4px; font-size: 14px;">Plateforme d'évaluation & quiz interactifs</p>
        </div>
        <div style="padding: 24px; background-color: #f8fafc; border-radius: 12px; border: 1px solid #e2e8f0;">
          <h2 style="color: #0f172a; margin-top: 0; font-size: 20px;">Activez votre compte</h2>
          <p style="color: #334155; font-size: 15px; line-height: 1.6;">Bonjour <strong>${prenom}</strong>,</p>
          <p style="color: #334155; font-size: 15px; line-height: 1.6;">
            Merci de rejoindre <strong>QuizPulse</strong> ! Pour activer votre compte et sécuriser vos évaluations, veuillez saisir le code de confirmation suivant :
          </p>
          <div style="text-align: center; margin: 32px 0;">
            <span style="display: inline-block; font-size: 34px; font-weight: 800; letter-spacing: 10px; color: #4f46e5; background: #eef2ff; padding: 16px 32px; border-radius: 12px; border: 2px dashed #6366f1;">
              ${code}
            </span>
          </div>
          <p style="color: #64748b; font-size: 13px; text-align: center; margin-bottom: 0;">
            Ce code expirera dans <strong>24 heures</strong>.
          </p>
        </div>
        <p style="color: #94a3b8; font-size: 12px; margin-top: 24px; text-align: center;">
          Si vous n'êtes pas à l'origine de cette inscription, ignorez simplement cet e-mail.
        </p>
      </div>
    `;

    // 0. Solution Google Apps Script (Relais Gmail Universel) - Envoie à TOUTES les adresses du monde sans restriction de domaine ni SMS
    const gmailWebhookUrl = process.env.GMAIL_WEBHOOK_URL || process.env.GOOGLE_SCRIPT_URL;
    if (gmailWebhookUrl) {
      try {
        console.log(`[EMAIL SERVICE] Envoi via Google Apps Script (Relais Gmail HTTPS)...`);
        const res = await fetch(gmailWebhookUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            to,
            prenom,
            code,
            subject,
            html,
            text,
          }),
          redirect: 'follow',
        });

        if (res.ok) {
          console.log(`[EMAIL SERVICE SUCCÈS] E-mail envoyé avec succès via Google Apps Script à ${to} !`);
          return true;
        } else {
          const errText = await res.text();
          console.error(`[EMAIL SERVICE ERREUR] Échec Google Apps Script:`, errText);
        }
      } catch (err: any) {
        console.error(`[EMAIL SERVICE ERREUR] Exception Google Apps Script:`, err.message);
      }
    }

    // 1. Solution API HTTP (Brevo / Sendinblue) - Priorité 1 : permet d'envoyer à TOUTES les adresses du monde sans restriction de domaine
    const brevoApiKey = process.env.BREVO_API_KEY;
    if (brevoApiKey) {
      try {
        console.log(`[EMAIL SERVICE] Envoi via Brevo API (HTTPS)...`);
        const res = await fetch('https://api.brevo.com/v3/smtp/email', {
          method: 'POST',
          headers: {
            'api-key': brevoApiKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: JSON.stringify({
            sender: { name: 'QuizPulse', email: process.env.BREVO_SENDER || process.env.SMTP_USER || 'barounisouha28009@gmail.com' },
            to: [{ email: to, name: prenom }],
            subject,
            htmlContent: html,
            textContent: text,
          }),
        });

        if (res.ok) {
          console.log(`[EMAIL SERVICE SUCCÈS] E-mail envoyé avec succès via Brevo API !`);
          return true;
        } else {
          const errText = await res.text();
          console.error(`[EMAIL SERVICE ERREUR] Échec Brevo API:`, errText);
        }
      } catch (err: any) {
        console.error(`[EMAIL SERVICE ERREUR] Exception Brevo:`, err.message);
      }
    }

    // 2. Solution API HTTP (Resend) - Fonctionne sur Render (restreint au propriétaire en mode gratuit)
    const resendApiKey = process.env.RESEND_API_KEY;
    if (resendApiKey) {
      try {
        console.log(`[EMAIL SERVICE] Envoi via Resend API (HTTPS)...`);
        const res = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${resendApiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            from: process.env.RESEND_FROM || 'QuizPulse <onboarding@resend.dev>',
            to: [to],
            subject,
            html,
            text,
          }),
        });

        if (res.ok) {
          const json = await res.json() as any;
          console.log(`[EMAIL SERVICE SUCCÈS] E-mail envoyé avec succès via Resend API ! ID: ${json.id}`);
          return true;
        } else {
          const errText = await res.text();
          console.error(`[EMAIL SERVICE ERREUR] Échec Resend API:`, errText);
        }
      } catch (err: any) {
        console.error(`[EMAIL SERVICE ERREUR] Exception Resend:`, err.message);
      }
    }

    if (!transporter) {
      return false;
    }

    try {
      const from = process.env.SMTP_FROM || `"QuizPulse" <${user}>`;
      const sendPromise = transporter.sendMail({
        from,
        to,
        subject,
        text,
        html,
      });

      const timeoutPromise = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error('SMTP timeout (15s limit reached)')), 15000)
      );

      const info = (await Promise.race([sendPromise, timeoutPromise])) as any;

      console.log(`[EMAIL SERVICE SUCCÈS] E-mail Gmail envoyé avec succès ! ID: ${info.messageId}`);
      return true;
    } catch (err: any) {
      console.error('[EMAIL SERVICE ERREUR] Échec de l\'envoi via Gmail SMTP:', err.message);
      if (err.message && (err.message.includes('535') || err.message.includes('Username and Password not accepted'))) {
        console.error('\n[GMAIL CONFIG AIDE] Google a refusé le mot de passe !');
        console.error('1. Activez la validation en 2 étapes sur votre compte Google si ce n\'est pas fait.');
        console.error('2. Générez un "Mot de passe d\'application" sur: https://myaccount.google.com/apppasswords');
        console.error('3. Collez ce mot de passe de 16 caractères dans backend/.env dans la variable SMTP_PASS.\n');
      }
      return false;
    }
  }
}

export const emailService = new EmailService();

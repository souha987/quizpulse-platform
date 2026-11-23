import dotenv from 'dotenv';
dotenv.config();

import { emailService } from '../src/services/email.service';

async function main() {
  const recipient = process.argv[2] || process.env.SMTP_USER || 'barounisouha28009@gmail.com';
  console.log(`[TEST EMAIL] Envoi d'un e-mail de test à : ${recipient}`);
  console.log(`[TEST EMAIL] SMTP_SERVICE: ${process.env.SMTP_SERVICE}`);
  console.log(`[TEST EMAIL] SMTP_USER: ${process.env.SMTP_USER}`);
  console.log(`[TEST EMAIL] SMTP_PASS configuré: ${process.env.SMTP_PASS ? 'OUI (' + process.env.SMTP_PASS.length + ' caractères)' : 'NON (VIDE)'}`);

  if (!process.env.SMTP_PASS) {
    console.log('\n❌ ERREUR : La variable SMTP_PASS est VIDE dans backend/.env !');
    console.log('Google exige un "Mot de passe d\'application" pour envoyer des e-mails via Gmail.');
    console.log('Veuillez générer un mot de passe d\'application sur https://myaccount.google.com/apppasswords et le renseigner dans backend/.env.\n');
    return;
  }

  const success = await emailService.sendVerificationEmail(recipient, 'Utilisateur Test', '123456');
  if (success) {
    console.log('✅ SUCCÈS : L\'e-mail a bien été envoyé et accepté par Gmail !');
  } else {
    console.log('❌ ÉCHEC : Gmail n\'a pas pu envoyer l\'e-mail. Vérifiez les logs ci-dessus.');
  }
}

main();

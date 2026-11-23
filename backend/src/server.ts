import app from './app';
import { env } from './config/env';

const PORT = env.PORT || 5000;
const HOST = '0.0.0.0';

app.listen(PORT, HOST, () => {
  console.log(`=========================================`);
  console.log(`🚀 Serveur QuizPulse Déployé & Prêt`);
  console.log(`📡 URL Locale: http://localhost:${PORT}`);
  console.log(`📱 Accès depuis un autre appareil (Wi-Fi): http://10.135.214.89:${PORT}`);
  console.log(`🌍 Environnement: ${env.NODE_ENV}`);
  console.log(`=========================================`);
});


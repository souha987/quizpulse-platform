const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const WEB_DIR = path.join(__dirname, 'frontend', 'build', 'web');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

const server = http.createServer((req, res) => {
  let reqPath = req.url.split('?')[0];
  if (reqPath === '/' || reqPath === '') reqPath = '/index.html';

  let filePath = path.join(WEB_DIR, reqPath);

  // Fallback vers index.html pour les routes SPA (Single Page Application)
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    const maybeIndex = path.join(filePath, 'index.html');
    if (fs.existsSync(maybeIndex)) {
      filePath = maybeIndex;
    } else {
      filePath = path.join(WEB_DIR, 'index.html');
    }
  }

  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, content) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end(`Erreur serveur: ${err.code}`);
    } else {
      res.writeHead(200, {
        'Content-Type': contentType,
        'Cache-Control': 'no-cache',
        'Access-Control-Allow-Origin': '*',
      });
      res.end(content);
    }
  });
});

server.listen(PORT, () => {
  console.log(`=========================================`);
  console.log(`🌐 Application Flutter Web Démarrée`);
  console.log(`🔗 Ouvrez dans votre navigateur : http://localhost:${PORT}`);
  console.log(`=========================================`);
});


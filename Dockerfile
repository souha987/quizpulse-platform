# Dockerfile multi-stage pour déploiement complet (Flutter Web + Express Backend)
FROM node:20-alpine AS backend-build
WORKDIR /app/backend
COPY backend/package*.json ./
RUN npm install
COPY backend/ ./
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
COPY backend/package*.json ./backend/
RUN cd backend && npm install --omit=dev
COPY --from=backend-build /app/backend/dist ./backend/dist
COPY --from=backend-build /app/backend/prisma ./backend/prisma
COPY --from=backend-build /app/backend/node_modules/.prisma ./backend/node_modules/.prisma
COPY frontend/build/web ./frontend/build/web

EXPOSE 5000
ENV NODE_ENV=production
ENV PORT=5000

CMD ["node", "backend/dist/server.js"]

FROM node:24-bookworm-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY index.html vite.config.ts tsconfig.json ./
COPY src ./src
COPY public ./public
RUN npm run build
FROM node:24-bookworm-slim
WORKDIR /app
ENV NODE_ENV=production HOST=0.0.0.0 PORT=3001
COPY --from=build /app/dist ./dist
COPY server ./server
COPY src/lib/catalog.json ./src/lib/catalog.json
USER node
EXPOSE 3001
CMD ["node","server/index.mjs"]

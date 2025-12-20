# syntax=docker/dockerfile:1

# =========================
# Build stage
# =========================
FROM node:20-alpine AS builder

# Create app directory
WORKDIR /app

# Copy package.json и lock
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Копируем весь код
COPY . .


# Генерируем Prisma client
RUN npx prisma generate

# Собираем проект (nx build)
RUN npx nx reset
RUN npx nx build api --skip-nx-cache

# =========================
# Production stage
# =========================
FROM node:20-slim AS runner

WORKDIR /app

# Копируем зависимости prod
COPY package.json package-lock.json ./

RUN npm ci --omit=dev

# Копируем билд и Prisma client из builder
COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/node_modules /app/node_modules

# ENV
ENV NODE_ENV=production

# Port, на котором API слушает
EXPOSE 3000

# Запускаем
CMD ["node", "dist/api/main.js"]

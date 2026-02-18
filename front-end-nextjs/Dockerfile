#multi-stage container build for Next.js front-end application
#stage 1: Deps
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

#stage 2: builder 
FROM node:18-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build
#stage 3 : runner
FROM node:18-alpine AS runner
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
CMD ["npm", "start"]
FROM node:20-alpine

WORKDIR /app

COPY app/package*.json ./

RUN npm ci --omit=dev

COPY app/ .

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

USER appuser

ENV PORT=3000

EXPOSE $PORT

CMD ["node", "index.js"]

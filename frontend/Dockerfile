FROM node:20-bookworm-slim

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

COPY package*.json ./

RUN npm install

COPY . .

CMD ["npm", "run", "dev", "--", "--hostname", "0.0.0.0", "--port", "3000"]
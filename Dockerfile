FROM node:20-alpine

WORKDIR /app

COPY . .

RUN npm ci
RUN npx medusa build

WORKDIR /app/.medusa/server

RUN npm ci

# For server mode, run migrations before start
CMD ["sh", "-c", "if [ \"$MEDUSA_WORKER_MODE\" = \"server\" ]; then npm run predeploy && npm run start; else npm run start; fi"]
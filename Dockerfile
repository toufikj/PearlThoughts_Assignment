FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy full application (including node_modules if already present)
COPY . .

# Build Medusa (optional depending on your setup)
RUN npx medusa build

# For server mode, run migrations before starting the server
CMD ["sh", "-c", "if [ \"$MEDUSA_WORKER_MODE\" = \"server\" ]; then npm run predeploy && npm run start; else npm run start; fi"]

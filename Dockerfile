FROM node:20-alpine

WORKDIR /app

# Install Medusa CLI globally
RUN npm install -g @medusajs/medusa-cli

# Copy all app code (including node_modules if already present)
COPY . .

# Skip build if not required
# RUN medusa build  # <-- Only if your project explicitly needs it

# Start with proper mode handling
CMD ["sh", "-c", "if [ \"$MEDUSA_WORKER_MODE\" = \"server\" ]; then npm run predeploy && npm run start; else npm run start; fi"]

FROM node:18-alpine

# Set working directory
WORKDIR /app

# Download Medusa backend source code
RUN apk add --no-cache git \
    && git clone --depth 1 https://github.com/medusajs/medusa.git . \
    && rm -rf .git

# Install dependencies
RUN npm install

# (Optional) Copy your custom files or configuration here
# COPY .env ./

# Expose Medusa backend port
EXPOSE 9000

# Start Medusa
CMD ["npm", "run", "start"]

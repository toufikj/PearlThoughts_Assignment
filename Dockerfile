FROM node:18-alpine

WORKDIR /app

# Install git and build dependencies for native modules
RUN apk add --no-cache git python3 make g++

# Clone MedusaJS backend
RUN git clone --depth 1 https://github.com/medusajs/medusa.git . \
    && rm -rf .git

# (Optional) List files for debugging
RUN ls -la

# Install dependencies
RUN npm install

EXPOSE 9000

CMD ["npm", "run", "start"]

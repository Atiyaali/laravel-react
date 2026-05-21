FROM node:16-alpine as Builder

WORKDIR /app
COPY ./package.json ./
COPY ./package-lock.json ./
RUN npm install --legacy-peer-deps 

FROM node:16-alpine as Runner

WORKDIR /app
COPY --from=Builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]

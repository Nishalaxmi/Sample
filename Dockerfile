# Use official Node.js runtime as base image
FROM node:16

# Set the working directory inside the container
WORKDIR /app

# Copy the package.json and package-lock.json to the container
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application files to the container
COPY . .

# Expose the port the app will run on
EXPOSE 3000

# Command to run the app
CMD ["npm", "start"]

# Build Base Image as ubuntu
FROM ubuntu:latest as builder

# Working directory
WORKDIR /app

# Environment variable to specify node version
ARG NODE_VERSION=14.16.0
ARG NPM_VERSION=6.14.12

# Install specific nodejs and npm versions,  and  dependencies
RUN apt-get update && apt-get install -y curl
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN npm install -g npm@${NPM_VERSION}
RUN node --version &&  npm --version
RUN apt-get install build-essential git python3 -y


# Bitbucket credentials
ARG USERNAME
ARG PASSWORD
# Clone parameter-store repository
RUN git  clone https://${USERNAME}:${PASSWORD}@bitbucket.org/surveysparrow/parameter-store.git

# Clone comprinno-servuysparrow repository
RUN git  clone https://${USERNAME}:${PASSWORD}@bitbucket.org/surveysparrow/surveysparrow-comprinno.git

# Update parameters
RUN cd parameter-store/constants/ && \
    sed -i 's@worker: false@'"worker: false"'@' defaults.js && \
    sed -i 's@BASE_SUB_DOMAIN@'"app"'@' defaults.js && \
    sed -i 's@DOMAIN@'"surveytools"'@' defaults.js && \
    sed -i 's@WORK_DIR@'"../surveysparrow-comprinno/config"'@' defaults.js 
	

# Run the parameter-store script and update configuration in surveysparrow-comprinno repository
RUN cd parameter-store/ && \
    npm i && \
    node app_config.js 

# Environment varaible to specify environment
ENV NODE_ENV=staging

# Create log directory to store logs
RUN cd surveysparrow-comprinno/ && \
    mkdir -pv ./log && \
    touch ./log/server.log && \
    npm i && npm run prod  && \
    rm -rf ./client/dist 


# #--------------STAGING -------------------------
# FROM node:18-alpine3.14

# # Create app directory
# WORKDIR /app

# # Copy content from Base
# COPY --from=builder /app/surveysparrow-comprinno .
# # Environment varaible to specify environment
ENV NODE_ENV=staging

# Endpoint localhost:8080
EXPOSE 8080

# Start the application
CMD ["node", "./server/server.js"]

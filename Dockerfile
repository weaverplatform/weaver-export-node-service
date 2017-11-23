FROM node:6-alpine

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY . /usr/src/app

RUN npm install -g yarn && yarn && npm uninstall -g yarn
CMD npm start

EXPOSE 2525

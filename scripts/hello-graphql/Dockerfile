FROM cypress/browsers:chrome65-ff57
WORKDIR /hello-graphql
ADD . /hello-graphql/
# Install postgresql-client because we need createdb command
RUN apt-get update && \
    apt-get install postgresql-client-9.4 postgresql-client-common
# Install vim
RUN apt-get install libgpm2 vim vim-common vim-runtime
RUN yarn global add cypress
RUN cypress verify
RUN yarn global add create-react-app
RUN yarn global add pm2
RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"
RUN cd /usr/bin && curl -L https://github.com/netlify/netlifyctl/releases/download/v0.3.3/netlifyctl-linux-amd64-0.3.3.tar.gz | tar xz
RUN yarn global add heroku-cli
RUN ./setup-heroku.sh
EXPOSE 3000
EXPOSE 3001
# Update the image tag in docker-compose.yml whenever you make a change here.
FROM eu.gcr.io/tmt-public-docker-images/ruby2:1.190906

COPY Gemfile Gemfile.lock ./

ARG BUNDLE_RUBYGEMS__PKG__GITHUB__COM
ARG BUNDLE_ENTERPRISE__CONTRIBSYS__COM
ENV BUNDLE_RUBYGEMS__PKG__GITHUB__COM=$BUNDLE_RUBYGEMS__PKG__GITHUB__COM \
    BUNDLE_ENTERPRISE__CONTRIBSYS__COM=$BUNDLE_ENTERPRISE__CONTRIBSYS__COM

RUN bundle install

COPY . .

ARG APP_RELEASE="develop"
ARG APP_ENV="production"

ENV APP_ENV=${APP_ENV} \
    APP_RELEASE=${APP_RELEASE} \
    PORT=3000

CMD ["rails", "server", "-b", "0.0.0.0"]

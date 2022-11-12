FROM ruby:3.1
WORKDIR /work
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install --verbose

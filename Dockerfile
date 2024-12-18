FROM ruby:3.2

WORKDIR /app
COPY . .

RUN gem install bundler jekyll
RUN bundle install

EXPOSE 4000

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0"]

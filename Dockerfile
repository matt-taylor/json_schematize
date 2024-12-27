FROM ruby:3.3.6
RUN cd /tmp && curl -L --output ghr.tar.gz https://github.com/tcnksm/ghr/releases/download/v0.12.0/ghr_v0.12.0_linux_amd64.tar.gz && \
    tar -xzvf ghr.tar.gz && chmod +x ghr_v0.12.0_linux_amd64/ghr && mv ghr_v0.12.0_linux_amd64/ghr /usr/local/bin/ghr && rm -rf /tmp/*

WORKDIR /gem
COPY Gemfile /gem/Gemfile

COPY json_schematize.gemspec /gem/json_schematize.gemspec
COPY lib/json_schematize/version.rb /gem/lib/json_schematize/version.rb


RUN gem update --system && gem install bundler && bundle install --jobs=3 --retry=3 && \
    rm -rf /usr/local/bundle/cache

COPY . /gem
RUN gem build json_schematize

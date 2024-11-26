ARG RUBY_VERSION=3.2
FROM ruby:${RUBY_VERSION}-slim as base

# Install build dependencies
RUN apt-get update && apt-get install -y \
    golang \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set Go environment variables
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

# Create app directory
WORKDIR /app

# Development stage
FROM base as development

# Copy gemspec and version file first (for caching purposes)
COPY go_snowflake_ruby.gemspec /app/
COPY lib/go_snowflake_ruby/version.rb /app/lib/go_snowflake_ruby/

# Install bundler
RUN gem install bundler

# Copy Gemfile and install dependencies
COPY Gemfile* /app/
RUN bundle install

# Copy the rest of the gem files
COPY . /app/

# Create volume mount points
VOLUME ["/app/pkg", "/usr/local/bundle"]

# Build stage
FROM development as builder

# Build the gem
RUN rake build

# Optional: Run tests
# RUN rake test

CMD ["ls", "-l", "pkg"]

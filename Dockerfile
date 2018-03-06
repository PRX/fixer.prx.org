FROM ruby:2.3-alpine

MAINTAINER PRX <sysadmin@prx.org>
LABEL org.prx.app="yes"

# install git, aws-cli
RUN apk --no-cache add \
    ca-certificates \
    git \
    groff \
    less \
    libxml2 \
    libxslt \
    linux-headers \
    nodejs \
    postgresql-client \
    python py-pip py-setuptools \
    tzdata \
    sqlite \
    libsndfile \
    file \
    imagemagick \
    lame \
    sox \
    # madplay \
    # twolame \
    flac \
    && pip --no-cache-dir install awscli

# install PRX aws-secrets scripts
RUN git clone -o github https://github.com/PRX/aws-secrets
RUN cp ./aws-secrets/bin/* /usr/local/bin

ENV TINI_VERSION v0.9.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini
RUN chmod +x /tini

ENV RAILS_ENV production
ENV APP_HOME /app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile ./
ADD Gemfile.lock ./

RUN apk --update add --virtual build-dependencies \
    build-base \
    curl curl-dev \
    openssl-dev \
    postgresql-dev \
    sqlite-dev \
    zlib-dev \
    libxml2-dev \
    libxslt-dev \
    libffi-dev \
    libgcrypt-dev \
    libsndfile-dev \
    xz tar && \
    curl -o mp3val-0.1.8-src.tar.gz https://prx-tech.s3.amazonaws.com/archives/mp3val-0.1.8-src.tar.gz && \
    tar xvf mp3val-0.1.8-src.tar.gz && \
    cd mp3val-0.1.8-src && \
    make -f Makefile.linux && \
    mkdir -p /usr/local/bin && \
    cp mp3val /usr/local/bin && \
    cd .. && \
    rm -rf mp3val-0.1.8-src && \
    rm mp3val-0.1.8-src.tar.gz && \
    curl -o ffmpeg-release-64bit-static.tar.xz https://prx-tech.s3.amazonaws.com/archives/ffmpeg-release-64bit-static.tar.xz && \
    tar xJf ffmpeg-release-64bit-static.tar.xz && \
    mv ffmpeg-*-64bit-static/ffmpeg /usr/local/bin/ && \
    mv ffmpeg-*-64bit-static/ffprobe /usr/local/bin/ && \
    rm -rf ffmpeg-*-64bit-static && \
    rm ffmpeg-release-64bit-static.tar.xz && \
    cd $APP_HOME && \
    bundle config --global build.nokogiri  "--use-system-libraries" && \
    bundle config --global build.nokogumbo "--use-system-libraries" && \
    bundle config --global build.ffi  "--use-system-libraries" && \
    bundle install --jobs 10 --retry 10 && \
    apk del build-dependencies && \
    (find / -type f -iname \*.apk-new -delete || true) && \
    rm -rf /var/cache/apk/* && \
    rm -rf /usr/lib/ruby/gems/*/cache/* && \
    rm -rf /tmp/* /var/tmp/* && \
    rm -rf ~/.gem

ADD . ./
RUN chown -R nobody:nogroup /app
USER nobody

ENTRYPOINT ["/tini", "--", "./bin/application"]
CMD ["web"]

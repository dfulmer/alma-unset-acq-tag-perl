FROM debian:bullseye
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  build-essential\
  ssh\
  perl\
  libwww-perl \
  libio-socket-ssl-perl\
  cpanminus
RUN cpanm Sys::Hostname
RUN cpanm URI::Escape; 
RUN cpanm Data::Dumper
RUN cpanm File::Basename
RUN cpanm Getopt::Std
RUN cpanm Encode;
RUN cpanm Class::Date 
RUN cpanm JSON
RUN cpanm LWP::UserAgent
RUN cpanm HTTP::Request
RUN cpanm Dotenv
RUN cpanm Test::Spec

WORKDIR /app
ENV PERL5LIB=/app/lib
LABEL maintainer="dfulmer@umich.edu"
FROM nginx:latest
LABEL maintainer="public@dpal.hu"

RUN apt-get update -qq && \
    apt-get install software-properties-common -y
 
RUN add-apt-repository ppa:certbot/certbot

RUN apt-get install cron python-certbot-nginx -y

COPY example.com.conf /
COPY crontab /
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
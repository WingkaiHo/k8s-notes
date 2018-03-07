FROM centos:7

COPY del-esindex.sh /usr/bin/del-esindex.sh
COPY timer /usr/bin/timer
RUN chmod +x /usr/bin/timer
RUN chmod +x /usr/bin/del-esindex.sh

CMD ["timer", "-interval=3600", "-command=/usr/bin/del-esindex.sh"]

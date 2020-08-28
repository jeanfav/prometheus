FROM prom/prometheus:v2.19.0

#### ENVS ####
# global envs
ENV SCRAPE_INTERVAL '30s'
ENV EVALUATION_INTERVAL '30s'
ENV SCRAPE_TIMEOUT '30s'
# tsdb storage envs
ENV TSDB_RETENTION '30d'
# REGION defines the deployment region (blue|green)
ENV REGION 'desenv'
# PROMETHEUS_NAME identifies the prometheus instance
ENV PROMETHEUS_NAME 'pn1'
# CANAL
ENV CHANNEL 'desenv'
# TARGETS
ENV STATIC_SCRAPE_TARGETS ''
# HTTP OR HTTPS SCHEME
ENV SCHEME_SCRAPE_TARGETS ''
#ALERTMANAGER
ENV ALERT_MANAGER_TARGET ''
#### CONFIG ####

USER root

COPY alerts/horario_fuso.yml /etc/prometheus/horario_fuso.yml

COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY build.sh /
COPY startup.sh /

RUN chmod -R 777 /etc/prometheus/
RUN chmod -R 777 /startup.sh
RUN chmod +x /build.sh

RUN sh /build.sh /etc/prometheus/

ENTRYPOINT [ "/bin/sh" ]
CMD [ "/startup.sh" ]
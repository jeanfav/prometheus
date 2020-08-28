#!/bin/bash

# WARNING: This code has ugly implementations because Prometheus base image doesn't have bash, just sh!

echo "Generating prometheus.yml according to ENV variables..."
echo "Informed variables:"
echo "SCRAPE_INTERVAL= $SCRAPE_INTERVAL"
echo "EVALUATION_INTERVAL=$EVALUATION_INTERVAL"
echo "SCRAPE_TIMEOUT=$SCRAPE_TIMEOUT"
echo "TSDB_RETENTION=$TSDB_RETENTION"
echo "REGION=$REGION"
echo "PROMETHEUS_NAME=$PROMETHEUS_NAME"
echo "CHANNEL=$CHANNEL"
echo "ALERT_MANAGER_TARGET=$ALERT_MANAGER_TARGET"

# SANITY CHECK
if [ "$SCRAPE_INTERVAL" == "" ]; then
  echo "SCRAPE_INTERVAL ENV is required" 1>&2
  exit 1
fi

if [ "$EVALUATION_INTERVAL" == "" ]; then
  echo "EVALUATINO_INTERVAL ENV is required" 1>&2
  exit 1
fi

if [ "$SCRAPE_TIMEOUT" == "" ]; then
  echo "SCRAPE_TIMEOUT ENV is required" 1>&2
  exit 1
fi

if [ "$TSDB_RETENTION" == "" ]; then
  echo "TSDB_RETENTION ENV is required" 1>&2
  exit 1
fi

if [ "$REGION" == "" ]; then
  echo "REGION ENV is required" 1>&2
  exit 1
fi

if [ "$PROMETHEUS_NAME" == "" ]; then
  echo "PROMETHEUS_NAME ENV is required" 1>&2
  exit 1
fi

FILE=/etc/prometheus/prometheus.yml

#### GLOBAL DEFINITIONS ####
cat > $FILE <<- EOM
global:
  scrape_interval: $SCRAPE_INTERVAL
  evaluation_interval: $EVALUATION_INTERVAL
  scrape_timeout: $SCRAPE_TIMEOUT

EOM

RULES=""
NEWLINE=$'\n'
for file in /etc/prometheus/*.yml; do
    FILENAME="$(expr "$file" : '/etc/prometheus/\(.*\)')"
    if [ ! "$FILENAME" == "prometheus.yml" ]; then
        RULES="${RULES}${NEWLINE}  - ${FILENAME}"
        sed -i -e 's/$REGION/'"$REGION"'/g' '/etc/prometheus/'$FILENAME
        sed -i -e 's/$PROMETHEUS_NAME/'"$PROMETHEUS_NAME"'/g' '/etc/prometheus/'$FILENAME
        sed -i -e 's/$CHANNEL/'"$CHANNEL"'/g' '/etc/prometheus/'$FILENAME
        sed -i -e 's/$EVALUATION_INTERVAL/'"$EVALUATION_INTERVAL"'/g' '/etc/prometheus/'$FILENAME
    fi
done

cat >> $FILE <<- EOM
rule_files: $RULES

EOM
#alert managers
if [ "$ALERT_MANAGER_TARGET" != "" ]; then
    cat >> $FILE <<- EOM
alerting:
  alertmanagers:
  - static_configs:
    - targets:
EOM
    #add each alert manager target
    for i in $(echo $ALERT_MANAGER_TARGET | tr " " "\n")
    do
    cat >> $FILE <<- EOM
      - $i
EOM
    done
fi      
cat >> $FILE <<- EOM
    scheme: https
    tls_config:
     insecure_skip_verify: true      

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']
EOM
#static scrapers
if [ "$STATIC_SCRAPE_TARGETS" != "" ]; then
    #add each static scrape target
        echo $SCHEME_SCRAPE_TARGETS
         if [ "$SCHEME_SCRAPE_TARGETS" == "http" ] || [ "$SCHEME_SCRAPE_TARGETS" == "" ] ; then
          SCHEME_SCRAPE_TARGETS="http"
        fi

         if [ "$SCHEME_SCRAPE_TARGETS" == "https" ]; then
          SCHEME_SCRAPE_TARGETS="https"
          TLS_IGNORE="tls_config:"
          TRUE="insecure_skip_verify: true"

        fi

for SL in $(echo $STATIC_SCRAPE_TARGETS | tr ";" "\n")
    do
        #this has to be done this ugly way because we don't have bash here, just sh!
        NAME=''
        HOST=''
        i=0
        for ST in $(echo $SL | tr "@" "\n")
        do
          if [ $i -eq 0 ]; then
            NAME=$ST
            i=1
          else
            HOST=$ST
          fi
        done



cat >> $FILE <<- EOM     
       
  - job_name: '$NAME'
    metrics_path: /metrics
    scheme: $SCHEME_SCRAPE_TARGETS
    $TLS_IGNORE
       $TRUE
    static_configs:
    - targets: ['$HOST']

EOM
  done
fi



echo "==prometheus.yml=="
cat $FILE
echo "=================="

echo "Starting Prometheus..."

/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/prometheus \
    --storage.tsdb.retention.time="$TSDB_RETENTION" \
    --web.console.libraries=/usr/share/prometheus/console_libraries \
    --web.console.templates=/usr/share/prometheus/consoles

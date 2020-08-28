# Prometheus Server

Prometheus server with configurable settings through ENV parameters.

By using this image you would avoid creating prometheus.yml manually, so that you indicate in ENV parameters the scrape targets and this container will start already configured to scrape them.

If you need more advanced Prometheus usage (custom alerting or more configurations), the best way is to create another container with those configurations embedded into it.

## ENVs

- SCRAPE_INTERVAL: global time between scrappings

- EVALUATION_INTERVAL: 

- SCRAPE_TIMEOUT: time after which the scraped target will be considered 'down'

- STATIC_SCRAPE_TARGETS: space separated list of "[name]@[host]:[port]</[metrics_path]>" Prometheus will try to get metrics from http://[host]:[port]/metrics. [name] will be used to label all metrics gotten from this target optionally, one can explicitly define the path to the metrics api via [metrics_path]
        
- SCHEME_SCRAPE_TARGETS: sets the http scheme for scraping: http|https. In case of https, the variable will be set to ignore the TLS certificate, using the tls_config option, setting true to insecure_skip_verify.

- TSDB_RETENTION: metrics retention time

- REGION: region to identify target environment

- CHANNEL: channel to identify target metrics

- PROMETHEUS_NAME: name for prometheus

- ALERT_MANAGER_TARGET: targets for alerts
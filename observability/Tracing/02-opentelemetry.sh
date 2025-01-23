#!/bin/bash

# Error handling setup
function handle_error {
    echo "An error occurred: $1"
    exit 1
}
trap 'handle_error "Error on line $LINENO"' ERR

kubectl apply -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel
  namespace: app-jaeger
spec:
  config:
    exporters:
      debug: {}
      otlp:
        endpoint: "jaeger-collector.observability.svc.cluster.local:4317"
        tls:
          insecure: true
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: '0.0.0.0:4317'
          http:
            endpoint: '0.0.0.0:4318'
    service:
      pipelines:
        traces:
          exporters:
            - debug
            - otlp
          receivers:
            - otlp
EOF


# kubectl apply -f - <<EOF
# apiVersion: opentelemetry.io/v1alpha1
# kind: Instrumentation
# metadata:
#   name: instrumentation
#   namespace: app-jaeger
# spec:
#   propagators:
#     - tracecontext
#     - baggage
#     - b3
#   sampler:
#     type: parentbased_traceidratio
#     argument: "1"
#   env:
#     - name: OTEL_EXPORTER_OTLP_ENDPOINT
#       value: http://otel-collector:4318
#   nodejs:    
#     env:
#       - name: OTEL_EXPORTER_OTLP_ENDPOINT
#         value: http://otel-collector:4317   
# EOF
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# FROM golang:1.17.7-alpine as builder
FROM registry.access.redhat.com/ubi8/go-toolset:1.16.12-7 as builder
# RUN apk add --no-cache ca-certificates git
# RUN apk add build-base
# WORKDIR /src
USER default

# restore dependencies
WORKDIR /opt/app-root/src

COPY --chown=default:root go.mod .
COPY --chown=default:root go.sum .

RUN go mod download

COPY . .

# Skaffold passes in debug-oriented compiler flags
ARG SKAFFOLD_GO_GCFLAGS

USER root

RUN go mod download golang.org/x/term

RUN go build -gcflags="${SKAFFOLD_GO_GCFLAGS}" -o /go/bin/checkoutservice .

# FROM alpine as release

FROM registry.access.redhat.com/ubi8/go-toolset:1.16.12-7

# RUN apk add --no-cache ca-certificates
# RUN GRPC_HEALTH_PROBE_VERSION=v0.4.6 && \
    # wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    # chmod +x /bin/grpc_health_probe
WORKDIR /opt/app-root/src

COPY --from=builder /go/bin/checkoutservice checkoutservice
COPY products.json .

ENV APP_PORT=3550

# Definition of this variable is used by 'skaffold debug' to identify a golang binary.
# Default behavior - a failure prints a stack trace for the current goroutine.
# See https://golang.org/pkg/runtime/
ENV GOTRACEBACK=single

EXPOSE 5050
ENTRYPOINT ["/opt/app-root/src/checkoutservice"]
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

FROM golang:1.16-alpine AS builder
RUN apk add --no-cache ca-certificates git
ENV PROJECT github.com/GoogleCloudPlatform/microservices-demo/src/productcatalogservice
WORKDIR /go/src/$PROJECT

# restore dependencies
COPY server.go go.mod go.sum ./
COPY genproto ./genproto/
RUN go mod vendor -v

COPY . .
RUN go build -o /server

FROM alpine AS release
RUN apk add --no-cache ca-certificates
RUN GRPC_HEALTH_PROBE_VERSION=v0.4.2 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe
WORKDIR /productcatalogservice
COPY --from=builder /server /productcatalogservice/server
COPY products.json .
EXPOSE 3550
ENTRYPOINT ["/productcatalogservice/server"]


FROM kong:0.12

MAINTAINER Cristian Chiru <cristian.chiru@revomatico.com>

ENV PACKAGES="openssl-devel gcc git"

RUN yum install -y unzip ${PACKAGES} \
## Install additional plugins
#    && luarocks install lua-resty-openidc \
    && luarocks install kong-oidc \
## Cleanup
    && yum remove -y ${PACKAGES} \
    && yum clean all \
    && rm -rf /var/cache/yum

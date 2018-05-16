FROM kong:0.12

MAINTAINER Cristian Chiru <cristian.chiru@revomatico.com>

# Install additional plugins
RUN luarocks install lua-resty-openidc \
    && luarocks install kong-oidc

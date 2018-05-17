FROM kong:0.12

MAINTAINER Cristian Chiru <cristian.chiru@revomatico.com>

ENV PACKAGES="openssl-devel gcc git" \
    KONG_OIDC_VER="1.0.5-0" \
    LUA_RESTY_OIDC_VER="1.5.4-1" \
    KHTHR_VER="0.13.1-0"

RUN yum install -y unzip ${PACKAGES} \
## Install plugins
    # Build lua-resty-openidc
    && wget https://raw.githubusercontent.com/zmartzone/lua-resty-openidc/master/lua-resty-openidc-${LUA_RESTY_OIDC_VER}.rockspec \
    && luarocks build lua-resty-openidc-${LUA_RESTY_OIDC_VER}.rockspec \
    # Build kong-oidc \
    && wget https://raw.githubusercontent.com/nokia/kong-oidc/master/kong-oidc-${KONG_OIDC_VER}.rockspec -O - | \
	sed -E -e 's/(tag =)[^,]+/\1 "master"/' -e "s/(lua-resty-openidc ~>)[^\"]+/\1 ${LUA_RESTY_OIDC_VER}/" | tee kong-oidc-${KONG_OIDC_VER}.rockspec \
    && luarocks build kong-oidc-${KONG_OIDC_VER}.rockspec \
    # Build kong-http-to-https-redirect
    && wget https://raw.githubusercontent.com/HappyValleyIO/kong-http-to-https-redirect/master/kong-http-to-https-redirect-${KHTHR_VER}.rockspec \
    && luarocks build kong-http-to-https-redirect-${KHTHR_VER}.rockspec \
## Cleanup
    && rm -fr *.rock* \
    && yum remove -y ${PACKAGES} \
    && yum clean all \
    && rm -rf /var/cache/yum

FROM kong:0.14-centos

MAINTAINER Cristian Chiru <cristian.chiru@revomatico.com>

ENV PACKAGES="openssl-devel kernel-headers gcc git openssh" \
    KONG_OIDC_VER="1.1.0-0" \
    # Stick to 1.6.0, as the latest version have issues with memcached stored sessions: very slow, times out, to investigate.
    LUA_RESTY_OIDC_VER="1.6.0" \
    KHTHR_VER="0.13.1-0"

RUN yum update -y && yum install -y unzip ${PACKAGES} \
## Install plugins
 # Build kong-oidc and patch the rockspec because is not keeping up with lua-resty-openidc
    && wget https://raw.githubusercontent.com/nokia/kong-oidc/master/kong-oidc-${KONG_OIDC_VER}.rockspec -O - | \
	sed -E -e 's/(tag =)[^,]+/\1 "master"/' -e "s/(lua-resty-openidc ~>)[^\"]+/\1 ${LUA_RESTY_OIDC_VER}/" > kong-oidc-${KONG_OIDC_VER}.rockspec \
    && luarocks build kong-oidc-${KONG_OIDC_VER}.rockspec \
    # NOT WORKING YET: Get the latest lua-resty-openidc from master, until the fix for https://github.com/zmartzone/lua-resty-openidc/issues/219 is released
    #&& wget https://raw.githubusercontent.com/zmartzone/lua-resty-openidc/master/lib/resty/openidc.lua -O /usr/local/share/lua/`lua <<< "print(_VERSION)" | awk '{print $2}'`/resty/openidc.lua \
 # Patch nginx_kong.lua for kong-oidc session_secret
    && TPL=/usr/local/share/lua/`lua <<< "print(_VERSION)" | awk '{print $2}'`/kong/templates/nginx_kong.lua \
    # May cause side effects when using another nginx under this kong, unless set to the same value
    && sed -i "/server_name kong;/a\ \n    set_decode_base64 \$session_secret \${{X_SESSION_SECRET}};\n" "$TPL" \
 # Patch nginx_kong.lua to add for memcached sessions
    && sed -i "/server_name kong;/a\ \n\
    set \$session_storage \${{X_SESSION_STORAGE}};\n\
    # Memcached specific
    set \$session_memcache_prefix sessions;\n\
    set \$session_memcache_host \${{X_SESSION_MEMCACHE_HOST}};\n\
    set \$session_memcache_port \${{X_SESSION_MEMCACHE_PORT}};\n\
    set \$session_memcache_uselocking on;\n\
    set \$session_memcache_spinlockwait 10000;\n\
    set \$session_memcache_maxlockwait 30;\n\
    set \$session_memcache_pool_timeout 10;\n\
    set \$session_memcache_pool_size 10;\n\
" "$TPL" \
 # Patch kong_defaults.lua to add custom variables that are replaced dynamically in the template above when kong is started
    && TPL=/usr/local/share/lua/`lua <<< "print(_VERSION)" | awk '{print $2}'`/kong/templates/kong_defaults.lua \
    && sed -i "/\]\]/i x_session_storage = cookie\nx_session_memcache_host = mcd-memcached\nx_session_memcache_port = '11211'\nx_session_secret = ''" "$TPL" \
 # Build kong-http-to-https-redirect
    && wget https://raw.githubusercontent.com/Revomatico/kong-http-to-https-redirect/master/kong-http-to-https-redirect-${KHTHR_VER}.rockspec \
    && luarocks build kong-http-to-https-redirect-${KHTHR_VER}.rockspec \
## Cleanup
    && rm -fr *.rock* \
    && yum remove -y ${PACKAGES} \
    && yum autoremove -y \
    && yum clean all \
    && rm -rf /var/cache/yum \
## Create the user kong
    && useradd kong \
    && mkdir -p /usr/local/kong \
    && chown kong:kong /usr/local/kong \
    # Allow regular users to run these programs and bind to ports < 1024
    && setcap 'cap_net_bind_service=+ep' /usr/local/bin/kong \
    && setcap 'cap_net_bind_service=+ep' /usr/local/openresty/nginx/sbin/nginx

USER kong

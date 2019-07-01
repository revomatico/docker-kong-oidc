FROM kong:1.2.1-centos

MAINTAINER Cristian Chiru <cristian.chiru@revomatico.com>

ENV PACKAGES="openssl-devel kernel-headers gcc git openssh" \
    KONG_OIDC_VER="1.1.0-1" \
    LUA_RESTY_OIDC_VER="1.7.1-1" \
    KHTHR_VER="0.14.1-0"

RUN set -x \
    && yum update -y && yum install -y unzip hostname ${PACKAGES} \
## Install plugins
 # Build kong-oidc from forked repo because is not keeping up with lua-resty-openidc
#    && curl -s https://raw.githubusercontent.com/nokia/kong-oidc/master/kong-oidc-${KONG_OIDC_VER}.rockspec | \
#	sed -E -e 's/(tag =)[^,]+/\1 "master"/' -e "s/(lua-resty-openidc ~>)[^\"]+/\1 ${LUA_RESTY_OIDC_VER}/" > kong-oidc-${KONG_OIDC_VER}.rockspec \
    && curl -s https://raw.githubusercontent.com/Revomatico/kong-oidc/master/kong-oidc-${KONG_OIDC_VER}.rockspec | tee kong-oidc-${KONG_OIDC_VER}.rockspec \
    && luarocks build kong-oidc-${KONG_OIDC_VER}.rockspec \
 # Patch nginx_kong.lua for kong-oidc session_secret
    && TPL=/usr/local/share/lua/`lua <<< "print(_VERSION)" | awk '{print $2}'`/kong/templates/nginx_kong.lua \
    # May cause side effects when using another nginx under this kong, unless set to the same value
    && sed -i "/server_name kong;/a\ \n\
    set_decode_base64 \$session_secret \${{X_SESSION_SECRET}};\n" "$TPL" \
 # Patch nginx_kong.lua to add for memcached sessions
    && sed -i "/server_name kong;/a\ \n\
    set \$session_storage \${{X_SESSION_STORAGE}};\n\
    # Memcached specific
    set \$session_memcache_prefix sessions;\n\
    set \$session_memcache_host \${{X_SESSION_MEMCACHE_HOST}};\n\
    set \$session_memcache_port \${{X_SESSION_MEMCACHE_PORT}};\n\
    set \$session_memcache_uselocking on;\n\
    set \$session_memcache_spinlockwait \${{X_SESSION_MEMCACHE_SPINLOCKWAIT}};\n\
    set \$session_memcache_maxlockwait \${{X_SESSION_MEMCACHE_MAXLOCKWAIT}};\n\
    set \$session_memcache_pool_timeout \${{X_SESSION_MEMCACHE_POOL_TIMEOUT}};\n\
    set \$session_memcache_pool_size \${{X_SESSION_MEMCACHE_POOL_SIZE}};\n\
" "$TPL" \
 # Patch kong_defaults.lua to add custom variables that are replaced dynamically in the template above when kong is started
    && TPL=/usr/local/share/lua/`lua <<< "print(_VERSION)" | awk '{print $2}'`/kong/templates/kong_defaults.lua \
    && sed -i "/\]\]/i x_session_storage = cookie\n\
x_session_memcache_host = mcd-memcached\n\
x_session_memcache_port = '11211'\n\
x_session_secret = ''\n\
x_session_memcache_spinlockwait = '10000'\n\
x_session_memcache_maxlockwait = '30'\n\
x_session_memcache_pool_timeout = '10'\n\
x_session_memcache_pool_size = '10'\n\
" "$TPL" \
 # Build kong-http-to-https-redirect
    && curl -s https://raw.githubusercontent.com/dsteinkopf/kong-http-to-https-redirect/repo-dsteinkopf/kong-http-to-https-redirect-${KHTHR_VER}.rockspec > kong-http-to-https-redirect-${KHTHR_VER}.rockspec \
    && luarocks build kong-http-to-https-redirect-${KHTHR_VER}.rockspec \
## Cleanup
    && rm -fr *.rock* \
    && yum remove -y ${PACKAGES} \
    && yum autoremove -y \
    && yum clean all \
    && rm -rf /var/cache/yum \
## Create kong and working directory (https://github.com/Kong/kong/issues/2690)
    && mkdir -p /usr/local/kong \
    && chown -R kong:kong /usr/local/kong \
    # Allow regular users to run these programs and bind to ports < 1024
    && setcap 'cap_net_bind_service=+ep' /usr/local/bin/kong \
    && setcap 'cap_net_bind_service=+ep' /usr/local/openresty/nginx/sbin/nginx

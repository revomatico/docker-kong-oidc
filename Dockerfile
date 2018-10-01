FROM kong:0.13-centos

MAINTAINER Cristian Chiru <cristian.chiru@revomatico.com>

ENV PACKAGES="openssl-devel gcc git" \
    KONG_OIDC_VER="1.1.0-0" \
    LUA_RESTY_OIDC_VER="1.6.1-1" \
    KHTHR_VER="0.13.1-0"

RUN yum install -y unzip ${PACKAGES} \
## Install plugins
 # Build lua-resty-openidc
    && wget https://raw.githubusercontent.com/zmartzone/lua-resty-openidc/master/lua-resty-openidc-${LUA_RESTY_OIDC_VER}.rockspec \
    && luarocks build lua-resty-openidc-${LUA_RESTY_OIDC_VER}.rockspec \
 # Build kong-oidc \
    && wget https://raw.githubusercontent.com/nokia/kong-oidc/master/kong-oidc-${KONG_OIDC_VER}.rockspec -O - | \
	sed -E -e 's/(tag =)[^,]+/\1 "master"/' -e "s/(lua-resty-openidc ~>)[^\"]+/\1 ${LUA_RESTY_OIDC_VER}/" > kong-oidc-${KONG_OIDC_VER}.rockspec \
    && luarocks build kong-oidc-${KONG_OIDC_VER}.rockspec \
 # Patch nginx_kong.lua for kong-oidc session_secret
    && TPL=/usr/local/share/lua/`lua <<< "print(_VERSION)" | awk '{print $2}'`/kong/templates/nginx_kong.lua \
    && sed -i "/server_name kong;/a\ \n    set_decode_base64 \$session_secret '`openssl rand -base64 32`';\n" "$TPL" \
 # Patch nginx_kong.lua to add for memcached sessions
    && sed -i "/server_name kong;/a\ \n\
    set \$session_storage \${{X_SESSION_STORAGE}};\n\
    set \$session_memcache_prefix sessions;\n\
    set \$session_memcache_host \${{X_SESSION_MEMCACHE_HOST}};\n\
    set \$session_memcache_port \${{X_SESSION_MEMCACHE_PORT}};\n\
    set \$session_memcache_uselocking on;\n\
    set \$session_memcache_spinlockwait 10000;\n\
    set \$session_memcache_maxlockwait 30;\n\
    set \$session_memcache_pool_timeout 45;\n\
    set \$session_memcache_pool_size 10;\n\
" "$TPL" \
 # Patch kong_defaults.lua to add custom variables that are replaced dynamically in the template above when kong is started
    && TPL=/usr/local/share/lua/`lua <<< "print(_VERSION)" | awk '{print $2}'`/kong/templates/kong_defaults.lua \
    && sed -i "/\]\]/i x_session_storage = cookie\nx_session_memcache_host = mcd-memcached\nx_session_memcache_port = '11211'" "$TPL" \
 # Build kong-http-to-https-redirect
    && wget https://raw.githubusercontent.com/Laylo-abu/kong-http-to-https-redirect/master/kong-http-to-https-redirect-${KHTHR_VER}.rockspec \
    && luarocks build kong-http-to-https-redirect-${KHTHR_VER}.rockspec \
## Cleanup
    && rm -fr *.rock* \
    && yum remove -y ${PACKAGES} \
    && yum clean all \
    && rm -rf /var/cache/yum

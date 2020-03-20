FROM kong:2.0.2

USER root

LABEL maintainer.1="Rami Abusereya <rami.abusereya@revomatico.com>" \
  maintainer.2="Cristian Chiru <cristian.chiru@revomatico.com>"

ENV PACKAGES="openssl-devel kernel-headers gcc git openssh" \
    KONG_OIDC_VER="1.2.0-1" \
    LUA_RESTY_OIDC_VER="1.7.2-1"

RUN set -ex \
  && apk --no-cache add \
    libssl1.1 \
    openssl \
    curl \
    unzip \
    git \
  && apk --no-cache add --virtual .build-dependencies \
    make \
    gcc \
    openssl-dev \
  \
## Install plugins
 # Build kong-oidc from forked repo because is not keeping up with lua-resty-openidc
    && curl -s https://raw.githubusercontent.com/Revomatico/kong-oidc/master/kong-oidc-${KONG_OIDC_VER}.rockspec | tee kong-oidc-${KONG_OIDC_VER}.rockspec | \
        sed -E -e 's/(tag =)[^,]+/\1 "master"/' -e "s/(lua-resty-openidc ~>)[^\"]+/\1 ${LUA_RESTY_OIDC_VER}/" > kong-oidc-${KONG_OIDC_VER}.rockspec \
    && luarocks build kong-oidc-${KONG_OIDC_VER}.rockspec \
 # Patch nginx_kong.lua for kong-oidc session_secret
    && TPL=/usr/local/share/lua/5.1/kong/templates/nginx_kong.lua \
    # May cause side effects when using another nginx under this kong, unless set to the same value
    && sed -i "/server_name kong;/a\ \n\
set_decode_base64 \$session_secret \${{X_SESSION_SECRET}};\n" "$TPL" \
 # Patch nginx_kong.lua to set dictionaries
    && sed -i -E '/^lua_shared_dict kong\s+.+$/i\ \n\
variables_hash_max_size 2048;\n\
> if x_session_storage == "shm" then\n\
lua_shared_dict \${{X_SESSION_SHM_STORE}} \${{X_SESSION_SHM_STORE_SIZE}};\n\
> end\n\
> if not \(x_proxy_cache_storage_name == "kong_cache"\) then\n\
lua_shared_dict \${{X_PROXY_CACHE_STORAGE_NAME}} \${{X_PROXY_CACHE_STORAGE_SIZE}};\n\
> end\n\
' "$TPL" \
 # Patch nginx_kong.lua to add for memcached sessions
    && sed -i "/server_name kong;/a\ \n\
    ## Session:
    set \$session_storage \${{X_SESSION_STORAGE}};\n\
    set \$session_name \${{X_SESSION_NAME}};\n\
    ## Session: Memcached specific
    set \$session_memcache_prefix \${{X_SESSION_MEMCACHE_PREFIX}};\n\
    set \$session_memcache_host \${{X_SESSION_MEMCACHE_HOST}};\n\
    set \$session_memcache_port \${{X_SESSION_MEMCACHE_PORT}};\n\
    set \$session_memcache_uselocking \${{X_SESSION_MEMCACHE_USELOCKING}};\n\
    set \$session_memcache_spinlockwait \${{X_SESSION_MEMCACHE_SPINLOCKWAIT}};\n\
    set \$session_memcache_maxlockwait \${{X_SESSION_MEMCACHE_MAXLOCKWAIT}};\n\
    set \$session_memcache_pool_timeout \${{X_SESSION_MEMCACHE_POOL_TIMEOUT}};\n\
    set \$session_memcache_pool_size \${{X_SESSION_MEMCACHE_POOL_SIZE}};\n\
    ## Session: SHM Specific
    set \$session_shm_store \${{X_SESSION_SHM_STORE}};\n\
    set \$session_shm_uselocking \${{X_SESSION_SHM_USELOCKING}};\n\
    set \$session_shm_lock_exptime \${{X_SESSION_SHM_LOCK_EXPTIME}};\n\
    set \$session_shm_lock_timeout \${{X_SESSION_SHM_LOCK_TIMEOUT}};\n\
    set \$session_shm_lock_step \${{X_SESSION_SHM_LOCK_STEP}};\n\
    set \$session_shm_lock_ratio \${{X_SESSION_SHM_LOCK_RATIO}};\n\
    set \$session_shm_lock_max_step \${{X_SESSION_SHM_LOCK_MAX_STEP}};\n\
" "$TPL" \
 # Patch kong_defaults.lua to add custom variables that are replaced dynamically in the template above when kong is started
    && TPL=/usr/local/share/lua/5.1/kong/templates/kong_defaults.lua \
    && sed -i "/\]\]/i\ \n\
x_proxy_cache_storage_size = 5m\n\
x_proxy_cache_storage_name = kong_cache\n\
\n\
x_session_storage = cookie\n\
x_session_name = oidc_session\n\
x_session_secret = ''\n\
\n\
x_session_memcache_prefix = oidc_sessions\n\
x_session_memcache_host = memcached\n\
x_session_memcache_port = '11211'\n\
x_session_memcache_uselocking = off\n\
x_session_memcache_spinlockwait = '10000'\n\
x_session_memcache_maxlockwait = '30'\n\
x_session_memcache_pool_timeout = '10'\n\
x_session_memcache_pool_size = '10'\n\
\n\
x_session_shm_store_size = 5m\n\
x_session_shm_store = oidc_sessions\n\
x_session_shm_uselocking = off\n\
x_session_shm_lock_exptime = '30'\n\
x_session_shm_lock_timeout = '5'\n\
x_session_shm_lock_step = '0.001'\n\
x_session_shm_lock_ratio = '2'\n\
x_session_shm_lock_max_step = '0.5'\n\
\n\
" "$TPL" \
## Cleanup
    && rm -fr *.rock* \
    && apk del .build-dependencies 2>/dev/null \
## Create kong and working directory (https://github.com/Kong/kong/issues/2690)
    && mkdir -p /usr/local/kong \
    && chown -R kong:`id -gn kong` /usr/local/kong \
    # Allow regular users to run these programs and bind to ports < 1024
    && setcap 'cap_net_bind_service=+ep' /usr/local/bin/kong \
    && setcap 'cap_net_bind_service=+ep' /usr/local/openresty/nginx/sbin/nginx

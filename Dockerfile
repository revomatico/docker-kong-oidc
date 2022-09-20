FROM kong:3.0.0-alpine

USER root

LABEL authors="Cristian Chiru <cristian.chiru@revomatico.com>"

ENV PACKAGES="openssl-devel kernel-headers gcc git openssh" \
    LUA_BASE_DIR="/usr/local/share/lua/5.1" \
    KONG_PLUGIN_OIDC_VER="1.3.0-2" \
    KONG_PLUGIN_COOKIES_TO_HEADERS_VER="1.1-1" \
    LUA_RESTY_OIDC_VER="1.7.5-1" \
    NGX_DISTRIBUTED_SHM_VER="1.0.7"

RUN set -ex \
    && apk --no-cache add libssl1.1 openssl curl unzip git \
    && apk --no-cache add --virtual .build-dependencies \
    make \
    gcc \
    openssl-dev \
    \
    ## Install plugins
    # Download ngx-distributed-shm dshm library
    && curl -sL https://raw.githubusercontent.com/grrolland/ngx-distributed-shm/${NGX_DISTRIBUTED_SHM_VER}/lua/dshm.lua > ${LUA_BASE_DIR}/resty/dshm.lua \
    # Remove old lua-resty-session
    && luarocks remove --force lua-resty-session \
    # Add Pluggable Compressors dependencies
    && luarocks install lua-ffi-zlib \
    && luarocks install penlight \
    # Build kong-oidc from forked repo because is not keeping up with lua-resty-openidc
    && curl -sL https://raw.githubusercontent.com/revomatico/kong-oidc/v${KONG_PLUGIN_OIDC_VER}/kong-oidc.rockspec | \
        sed -E -e 's/(tag =)[^,]+/\1 "'v${KONG_PLUGIN_OIDC_VER}'"/' -e "s/(lua-resty-openidc ~>)[^\"]+/\1 ${LUA_RESTY_OIDC_VER}/" | \
        tee kong-oidc-${KONG_PLUGIN_OIDC_VER}.rockspec \
    && luarocks build kong-oidc-${KONG_PLUGIN_OIDC_VER}.rockspec \
    # Build kong-plugin-cookies-to-headers
    && curl -sL https://raw.githubusercontent.com/revomatico/kong-plugin-cookies-to-headers/master/kong-plugin-cookies-to-headers-${KONG_PLUGIN_COOKIES_TO_HEADERS_VER}.rockspec > kong-plugin-cookies-to-headers-${KONG_PLUGIN_COOKIES_TO_HEADERS_VER}.rockspec \
    && luarocks build kong-plugin-cookies-to-headers-${KONG_PLUGIN_COOKIES_TO_HEADERS_VER}.rockspec \
    # Patch nginx_kong.lua for kong-oidc session_secret
    && TPL=${LUA_BASE_DIR}/kong/templates/nginx_kong.lua \
    # May cause side effects when using another nginx under this kong, unless set to the same value
    && sed -i "/server_name kong;/a\ \n\
set_decode_base64 \$session_secret \${{X_SESSION_SECRET}};\n" "$TPL" \
    # Patch nginx_kong.lua to set dictionaries
    && sed -i -E '/^lua_shared_dict kong\s+.+$/i\ \n\
variables_hash_max_size 2048;\n\
lua_shared_dict discovery \${{X_OIDC_CACHE_DISCOVERY_SIZE}};\n\
lua_shared_dict jwks \${{X_OIDC_CACHE_JWKS_SIZE}};\n\
lua_shared_dict introspection \${{X_OIDC_CACHE_INTROSPECTION_SIZE}};\n\
> if x_session_storage == "shm" then\n\
lua_shared_dict \${{X_SESSION_SHM_STORE}} \${{X_SESSION_SHM_STORE_SIZE}};\n\
> end\n\
    ' "$TPL" \
    # Patch nginx_kong.lua to add for memcached sessions
    && sed -i "/server_name kong;/a\ \n\
## Session:
set \$session_storage \${{X_SESSION_STORAGE}};\n\
set \$session_name \${{X_SESSION_NAME}};\n\
set \$session_compressor \${{X_SESSION_COMPRESSOR}};\n\
## Session: Memcached specific
set \$session_memcache_connect_timeout \${{X_SESSION_MEMCACHE_CONNECT_TIMEOUT}};\n\
set \$session_memcache_send_timeout \${{X_SESSION_MEMCACHE_SEND_TIMEOUT}};\n\
set \$session_memcache_read_timeout \${{X_SESSION_MEMCACHE_READ_TIMEOUT}};\n\
set \$session_memcache_prefix \${{X_SESSION_MEMCACHE_PREFIX}};\n\
set \$session_memcache_host \${{X_SESSION_MEMCACHE_HOST}};\n\
set \$session_memcache_port \${{X_SESSION_MEMCACHE_PORT}};\n\
set \$session_memcache_uselocking \${{X_SESSION_MEMCACHE_USELOCKING}};\n\
set \$session_memcache_spinlockwait \${{X_SESSION_MEMCACHE_SPINLOCKWAIT}};\n\
set \$session_memcache_maxlockwait \${{X_SESSION_MEMCACHE_MAXLOCKWAIT}};\n\
set \$session_memcache_pool_timeout \${{X_SESSION_MEMCACHE_POOL_TIMEOUT}};\n\
set \$session_memcache_pool_size \${{X_SESSION_MEMCACHE_POOL_SIZE}};\n\
## Session: DHSM specific
set \$session_dshm_region \${{X_SESSION_DSHM_REGION}};\n\
set \$session_dshm_connect_timeout \${{X_SESSION_DSHM_CONNECT_TIMEOUT}};\n\
set \$session_dshm_send_timeout \${{X_SESSION_DSHM_SEND_TIMEOUT}};\n\
set \$session_dshm_read_timeout \${{X_SESSION_DSHM_READ_TIMEOUT}};\n\
set \$session_dshm_host \${{X_SESSION_DSHM_HOST}};\n\
set \$session_dshm_port \${{X_SESSION_DSHM_PORT}};\n\
set \$session_dshm_pool_name \${{X_SESSION_DSHM_POOL_NAME}};\n\
set \$session_dshm_pool_timeout \${{X_SESSION_DSHM_POOL_TIMEOUT}};\n\
set \$session_dshm_pool_size \${{X_SESSION_DSHM_POOL_SIZE}};\n\
set \$session_dshm_pool_backlog \${{X_SESSION_DSHM_POOL_BACKLOG}};\n\
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
    && TPL=${LUA_BASE_DIR}/kong/templates/kong_defaults.lua \
    && sed -i "/\]\]/i\ \n\
x_session_storage = cookie\n\
x_session_name = oidc_session\n\
x_session_compressor = 'none'\n\
x_session_secret = ''\n\
\n\
x_session_memcache_prefix = oidc_sessions\n\
x_session_memcache_connect_timeout = '1000'\n\
x_session_memcache_send_timeout = '1000'\n\
x_session_memcache_read_timeout = '1000'\n\
x_session_memcache_host = memcached\n\
x_session_memcache_port = '11211'\n\
x_session_memcache_uselocking = 'off'\n\
x_session_memcache_spinlockwait = '150'\n\
x_session_memcache_maxlockwait = '30'\n\
x_session_memcache_pool_timeout = '1000'\n\
x_session_memcache_pool_size = '10'\n\
\n\
x_session_dshm_region = oidc_sessions\n\
x_session_dshm_connect_timeout = '1000'\n\
x_session_dshm_send_timeout = '1000'\n\
x_session_dshm_read_timeout = '1000'\n\
x_session_dshm_host = hazelcast\n\
x_session_dshm_port = '4321'\n\
x_session_dshm_pool_name = oidc_sessions\n\
x_session_dshm_pool_timeout = '1000'\n\
x_session_dshm_pool_size = '10'\n\
x_session_dshm_pool_backlog = '10'\n\
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
x_oidc_cache_discovery_size = 128k\n\
x_oidc_cache_jwks_size = 128k\n\
x_oidc_cache_introspection_size = 128k\n\
\n\
" "$TPL" \
    ## Cleanup
    && rm -fr *.rock* \
    && apk del .build-dependencies 2>/dev/null \
    ## Create kong and working directory (https://github.com/Kong/kong/issues/2690)
    && mkdir -p /usr/local/kong \
    && chown -R kong:`id -gn kong` /usr/local/kong
USER kong

# docker-kong-oidc
> Builds a Docker image from base Kong + nokia/kong-oidc (based on zmartzone/lua-resty-openidc)

# Kong v1.2.1
- [Dockerfile](https://github.com/Revomatico/docker-kong-oidc/blob/master/Dockerfile)


# Kong v1.1.2
- [Dockerfile](https://github.com/Revomatico/docker-kong-oidc/blob/1.1.2-1/Dockerfile)


# Kong v1.0.3
- [Dockerfile](https://github.com/Revomatico/docker-kong-oidc/blob/1.0.3-1/Dockerfile)


# Kong v0.14
- [Dockerfile](https://github.com/Revomatico/docker-kong-oidc/blob/0.14-2/Dockerfile)


# Kong v0.13
- [Dockerfile](https://github.com/Revomatico/docker-kong-oidc/blob/0.13-3/Dockerfile)
- Added [kong-http-to-https-redirect plugin](https://github.com/HappyValleyIO/kong-http-to-https-redirect)


# Kong v0.12 (not maintained anymore)
- [Dockerfile](https://github.com/Revomatico/docker-kong-oidc/blob/0.12/Dockerfile)
- OpenID Connect plugin: [kong-oidc](https://github.com/nokia/kong-oidc)
    - Based on: [lua-resty-openidc](https://github.com/zmartzone/lua-resty-openidc)


# Memcached
- Reference: https://github.com/bungle/lua-resty-session#pluggable-storage-adapters
- To replace the default sesion storage: **cookie** with memcached, set
    - `KONG_X_SESSION_STORAGE=memcache`
- Memcached hostname is by default **mcd-memcached** (in my case installed via helm in a Kubernetes cluster)
    - Set `KONG_X_SESSION_MEMCACHE_HOST=mynewhost`
    - Alternatively, set up DNS entry for **mcd-memcached** to be resolved from within the container
- Memcached port is by default **11211**, override by setting:
    - `KONG_X_SESSION_MEMCACHE_PORT=12345`
- KONG_X_SESSION_MEMCACHE_SPINLOCKWAIT, default: 10000
- KONG_X_SESSION_MEMCACHE_MAXLOCKWAIT, default: 30
- KONG_X_SESSION_MEMCACHE_POOL_TIMEOUT, default: 10
- KONG_X_SESSION_MEMCACHE_POOL_SIZE, default: 10


# Notes
- Dockerfile will patch `nginx_kong.lua` template at build time, to include `set_decode_base64 $session_secret 'some_base64_string';`
    - This is needed for the kong-oidc plugin to set a session secret that will later override the template string
    - See: https://github.com/nokia/kong-oidc/issues/1
- To enable the plugins, set the env variable for the container with comma separated plugin values:
    - [Kong < 0.14] `KONG_CUSTOM_PLUGINS=oidc,kong-http-to-https-redirect`
    - [Kong >= 0.14] `KONG_PLUGINS=bundled,oidc,kong-http-to-https-redirect`
- A common default session_secret should be defined by setting env KONG_X_SESSION_SECRET


# Release notes
- 2019-07-04 [1.2.1-2]:
    - Correctly added **hostname** package in Dockerfile
    - Forced a commit to rebuild the image on docker hub, because of changes in kong-oidc plugin
- 2019-07-01 [1.2.1-1]:
    - Bump to Kong 1.2.1-centos image
- 2019-06-13 [1.2.0-1]:
    - Bump to Kong 1.2.0-centos image
- 2019-04-27 [1.1.2-1]:
    - Used Kong 1.1.2-centos image
    - Changed kong-oidc plugin repo from Nokia to [Revomatico](https://github.com/Revomatico/kong-oidc) for various improvements and compatibility with lua-resty-openidc 1.7
- 2019-04-02 [1.1.1-1]:
    - Using Kong 1.1.1-centos image
- 2019-02-22 [1.0.3-1]:
    - Kept creation of `/usr/local/kong` in Dockerfile
    - Removed Dockerfile's `USER` directive is incompatible with su-exec. See https://github.com/ncopa/su-exec/issues/2#issuecomment-336670196
- 2019-02-21 [1.0.3]:
    - Replaced **Revomatico/kong-http-to-https-redirect** with [dsteinkopf/kong-http-to-https-redirect](https://github.com/dsteinkopf/kong-http-to-https-redirect) as it has more fixes and improvements
    - Upgraded rockspec [zmartzone/lua-resty-openidc](https://github.com/zmartzone/lua-resty-openidc) to 1.7.1-1
    - Using Kong 1.0.3 image
    - Added new environment variables to configure memcached
- 2018-11-27 [0.14-2]:
    - ~~Upgraded rockspec [zmartzone/lua-resty-openidc](https://github.com/zmartzone/lua-resty-openidc) to 1.7.0-2~~ this causes issues, staying with 1.6.1-1 for now
    - Added env variable KONG_X_SESSION_SECRET to populate $session_secret variable with the same variable for all pods in the cluster
    - Removed explicitly building lua-resty-openidc in Dockerfile, since is automatically done by luarocks build, since is a dependency of kong-oidc
    - Set everything to run under regular user kong instead of root
- 2018-10-09 [0.14-1]:
    - Upgraded to Kong 0.14
- 2018-10-09 [0.13-3]:
    - Changed repo for kong-http-to-https-redirect to [Revomatico/kong-http-to-https-redirect](https://github.com/Revomatico/kong-http-to-https-redirect)
- 2018-08-10 [0.13-2]:
    - Forced a rebuild to update rockspec [HappyValleyIO/kong-http-to-https-redirect](https://github.com/HappyValleyIO/kong-http-to-https-redirect)
- 2018-07-07 [0.13-1]:
    - Updated rockspec [zmartzone/lua-resty-openidc](https://github.com/zmartzone/lua-resty-openidc) to 1.6.1-1
- 2018-07-04 [0.13]:
    - Updated rockspec [nokia/kong-oidc](https://github.com/nokia/kong-oidc) to 1.1.0-0
    - Updated rockspec [zmartzone/lua-resty-openidc](https://github.com/zmartzone/lua-resty-openidc) to 1.6.0-1

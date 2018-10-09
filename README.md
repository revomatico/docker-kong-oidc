# docker-kong-oidc
> Builds a Docker image from base Kong + nokia/kong-oidc (based on zmartzone/lua-resty-openidc)

# Kong v0.14
- [Dockerfile](https://github.com/Revomatico/docker-kong-oidc/blob/master/Dockerfile)

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

# Notes
- Dockerfile will patch `nginx_kong.lua` template at build time, to include `set_decode_base64 $session_secret 'somerandomstring';`
    - This is needed for the kong-oidc plugin to set a session secret that will later override the template string
    - See: https://github.com/nokia/kong-oidc/issues/1
- To enable the plugins, set the env variable for the container with comma separated plugin values:
    - `KONG_CUSTOM_PLUGINS=oidc,kong-http-to-https-redirect`

# Release notes
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

# docker-kong-oidc
> Builds a Docker image from base Kong + nokia/kong-oidc

# Kong v0.13
- [Dockerfile](https://github.com/Revomatico/docker-kong-oidc/blob/master/Dockerfile)
- Added [kong-http-to-https-redirect plugin](https://github.com/HappyValleyIO/kong-http-to-https-redirect)

# Kong v0.12
- [Dockerfile](https://github.com/Revomatico/docker-kong-oidc/blob/0.12/Dockerfile)
- OpenID Connect plugin: [kong-oidc](https://github.com/nokia/kong-oidc)
    - Based on: [lua-resty-openidc](https://github.com/zmartzone/lua-resty-openidc)

# Build
- Run `./build.sh` to generate `nginx_kong.lua` template, to include `set_decode_base64 $session_secret 'XX';`
    - This is needed for the kong-oidc plugin to set a session secret.
- See: https://github.com/nokia/kong-oidc/issues/1

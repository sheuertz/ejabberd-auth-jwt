# ejabberd JWT authentication

This module enables [JWT](https://jwt.io/introduction/) authentication on [ejabberd](https://www.ejabberd.im/).

## Installation

The easiest way to install this module is using `ejabberdctl`:

```
# 1. Create the target directory.
mkdir -p ~/.ejabberd-modules/sources

# 2. Copy the source code into the target directory.
#
# Here we are using git, but you can copy it manually in case git is not available in your host.
#
# You should also edit the configuration file located at conf/ejabberd_auth_jwt (examples below).
git clone git@github.com:yokomizor/ejabberd-auth-jwt.git ~/.ejabberd-modules/sources/ejabberd_auth_jwt/

# 3. Load module
ejabberdctl module_install ejabberd_auth_jwt

# 4. Set auth_method to use this module.
# 
# Add the following config into your conf/ejabberd.yml
#
#  auth_method: jwt
#
# And reload ejabberd config.
ejabberdctl reload_config
```


## Configuration examples

**Symetric HMAC key**

```
jwtauth_key: "bXkgc2FmZSBrZXk=" # Base64 encoded key
jwtauth_strict_alg: "HS256"
```


**Asymetric RSA key**

```
jwtauth_pem_file: "/home/ejabberd/conf/jwt.pem" # Public key
jwtauth_strict_alg: "RS256"
```


**Custom user claim**

This module checks if the JWT claim `sub` matches the user jid.
To use a custom JWT claim:

```
jwtauth_user_claim: "myjid"
```


## TODO

- [ ] Support [JWKS](https://auth0.com/docs/jwks)


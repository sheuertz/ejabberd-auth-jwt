%%%----------------------------------------------------------------------
%%% File    : ejabberd_auth_jwt.erl
%%% Author  : Rogerio da Silva Yokomizo <me@ro.ger.io>
%%% Purpose : Authentification via JWT token
%%% Created : 10 May 2018 by Rogerio da Silva Yokomizo <me@ro.ger.io>
%%%
%%%
%%% Copyright 2018 Rogerio da Silva Yokomizo
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%----------------------------------------------------------------------

-module(ejabberd_auth_jwt).

-behaviour(ejabberd_config).

-author('me@ro.ger.io').

-behaviour(ejabberd_auth).

-export([check_password/4, opt_type/1,
	 plain_password_required/1, reload/1, remove_user/2,
	 set_password/3, start/1, stop/1, store_type/1,
	 try_register/3, use_cache/1, user_exists/2]).

-include("ejabberd.hrl").

-include("logger.hrl").

%-include("jose_jwt.hrl").

-record(jose_jwt, {fields = #{}  :: map()}).

%%%----------------------------------------------------------------------
%%% API
%%%----------------------------------------------------------------------
start(_Host) -> ok.

stop(_Host) -> ok.

reload(_Host) -> ok.

plain_password_required(_) -> true.

use_cache(_) -> false.

store_type(_) -> external.

check_password(User, AuthzId, Server, Password) ->
    if AuthzId /= <<>> andalso AuthzId /= User -> false;
       true -> check_password_jwt(User, Server, Password)
    end.

set_password(_User, _Server, _Password) ->
    {error, not_allowed}.

try_register(_User, _Server, _Password) ->
    {error, not_allowed}.

user_exists(_User, _Server) -> true.

remove_user(_User, _Server) -> {error, not_allowed}.

opt_type(jwtauth_strict_alg) -> fun iolist_to_binary/1;
opt_type(jwtauth_user_claim) -> fun iolist_to_binary/1;
opt_type(jwtauth_key) -> fun iolist_to_binary/1;
opt_type(jwtauth_pem_file) -> fun iolist_to_binary/1;
opt_type(_) ->
    [jwtauth__key, jwtauth_pem_file, jwtauth_user_claim,
     jwtauth_strict_alg].

%%%----------------------------------------------------------------------
%%% Internal functions
%%%----------------------------------------------------------------------
check_password_jwt(User, Server, Fields)
    when is_map(Fields) ->
    UserClaim =
	ejabberd_config:get_option({jwtauth_user_claim, Server},
				   <<"sub">>),
    case maps:find(UserClaim, Fields) of
      {ok, User} -> true;
      _ -> false
    end;
check_password_jwt(User, Server, Password) ->
    JWK = get_jwk(Server),
    Alg = ejabberd_config:get_option({jwtauth_strict_alg,
				      Server}),
    try verify_token(JWK, Alg, Password) of
      {true, #jose_jwt{fields = Fields}, _} ->
	  check_password_jwt(User, Server, Fields);
      _ -> false
    catch
      _:_ -> false
    end.

verify_token(JWK, undefined, Token) ->
    jose_jwt:verify(JWK, Token);
verify_token(JWK, Alg, Token) ->
    jose_jwt:verify_strict(JWK, [Alg], Token).

get_jwk(Server) ->
    case ejabberd_config:get_option({jwtauth_pem_file,
				     Server})
	of
      RSAKeyFile -> jose_jwk:from_pem_file(RSAKeyFile);
      undefined ->
	  HS256Key = ejabberd_config:get_option({jwtauth_key,
						 Server}),
	  #{<<"kty">> => <<"oct">>, <<"k">> => HS256Key}
    end.

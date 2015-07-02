-module(turtle_publisher).
-behaviour(gen_server).
-include_lib("amqp_client/include/amqp_client.hrl").

%% Lifetime
-export([
	start_link/3
]).

%% API
-export([
	publish/5
]).

%% API
-export([
]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-record(state, {
	channel
 }).

%% LIFETIME MAINTENANCE
%% ----------------------------------------------------------
start_link(Name, Connection, Declarations) ->
    gen_server:start_link({local, Name}, ?MODULE, [Connection, Declarations], []).

publish(Publisher, Exch, Key, ContentType, Payload) ->
    Pub = #'basic.publish' {
        exchange = Exch,
        routing_key = Key
    },
    Props = #'P_basic' { content_type = ContentType },
    gen_server:cast(Publisher, {publish, Pub, Props, Payload}).

%% CALLBACKS
%% -------------------------------------------------------------------

%% @private
init([Connection, Declarations]) ->
    {ok, Channel} = turtle:open_channel(Connection),
    ok = turtle:declare(Channel, Declarations),
    {ok, #state { channel = Channel }}.

%% @private
handle_call(Call, From, State) ->
    lager:warning("Unknown call from ~p: ~p", [From, Call]),
    {reply, {error, unknown_call}, State}.

%% @private
handle_cast({publish, Pub, Props, Payload}, #state { channel = Ch } = State) ->
    ok = amqp_channel:cast(Ch, Pub, #amqp_msg { props = Props, payload = Payload }),
    {noreply, State};
handle_cast(Cast, State) ->
    lager:warning("Unknown cast: ~p", [Cast]),
    {noreply, State}.

%% @private
handle_info(Info, State) ->
    lager:warning("Received unknown info msg: ~p", [Info]),
    {noreply, State}.

%% @private
terminate(_Reason, _State) ->
    ok.

%% @private
code_change(_, State, _) ->
    {ok, State}.

%%
%% INTERNAL FUNCTIONS
%%

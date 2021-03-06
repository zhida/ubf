%%%----------------------------------------------------------------------
%%% File    : stateless_plugin_sup.erl
%%% Purpose : test UBF top-level supervisor
%%%----------------------------------------------------------------------

-module(stateless_plugin_sup).

-behaviour(supervisor).

%% External exports
-export([start_link/1]).

%% supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%%----------------------------------------------------------------------
%%% API
%%%----------------------------------------------------------------------
start_link(_Args) ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%%----------------------------------------------------------------------
%%% Callback functions from supervisor
%%%----------------------------------------------------------------------

%%----------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}
%%----------------------------------------------------------------------
%% @spec(Args::term()) -> {ok, {supervisor_flags(), child_spec_list()}}
%% @doc The main TEST UBF supervisor.

init(Args) ->
    %% seq_trace:set_token(send, true), seq_trace:set_token('receive', true),

    %% Child_spec = [Name, {M, F, A},
    %%               Restart, Shutdown_time, Type, Modules_used]

    DefaultMaxConn = 10000,
    DefaultTimeout = 60000,
    DefaultPlugins = proplists:get_value(plugins, Args, [stateless_plugin]),

    CUBF = case proplists:get_value(test_ubf_tcp_port, Args, 0) of
               undefined ->
                   [];
               UBFPort ->
                   UBFMaxConn = proplists:get_value(test_ubf_maxconn, Args, DefaultMaxConn),
                   UBFIdleTimer = proplists:get_value(test_ubf_timeout, Args, DefaultTimeout),
                   UBFOptions = [{serverhello, "test_meta_server"}
                                 , {statelessrpc,true}
                                 , {proto,ubf}
                                 , {maxconn,UBFMaxConn}
                                 , {idletimer,UBFIdleTimer}
                                 , {registeredname,test_ubf_tcp_port}
                                ],
                   UBFServer =
                       {ubf_server, {ubf_server, start_link, [test_ubf, DefaultPlugins, UBFPort, UBFOptions]},
                        permanent, 2000, worker, [ubf_server]},

                   [UBFServer]
           end,

    CEBF = case proplists:get_value(test_ebf_tcp_port, Args, 0) of
               undefined ->
                   [];
               EBFPort ->
                   EBFMaxConn = proplists:get_value(test_ebf_maxconn, Args, DefaultMaxConn),
                   EBFIdleTimer = proplists:get_value(test_ebf_timeout, Args, DefaultTimeout),
                   EBFOptions = [{serverhello, "test_meta_server"}
                                 , {statelessrpc,true}
                                 , {proto,ebf}
                                 , {maxconn,EBFMaxConn}
                                 , {idletimer,EBFIdleTimer}
                                 , {registeredname,test_ebf_tcp_port}
                                ],
                   EBFServer =
                       {ebf_server, {ubf_server, start_link, [test_ebf, DefaultPlugins, EBFPort, EBFOptions]},
                        permanent, 2000, worker, [ebf_server]},

                   [EBFServer]
           end,

    {ok, {{one_for_one, 2, 60}, CUBF++CEBF}}.

%%%----------------------------------------------------------------------
%%% Internal functions
%%%----------------------------------------------------------------------

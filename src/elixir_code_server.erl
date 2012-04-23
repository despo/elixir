-module(elixir_code_server).
-export([start_link/0, init/1, handle_call/3, handle_cast/2,
  handle_info/2, terminate/2, code_change/3]).
-behavior(gen_server).
-record(elixir_code_server, {
  argv=[],
  loaded=[],
  at_exit=[],
  compiler_options=[
    {debug_info,false},
    {discovery,[]},
    {docs,false},
    {ignore_module_conflict,false},
    {output_dir,nil}
  ]
}).

start_link() ->
  { ok, _ } = gen_server:start_link({local, elixir_code_server}, ?MODULE, [], []).

init(_args) ->
  { ok, #elixir_code_server{} }.

handle_call({loaded, Path}, _From, Config) ->
  { reply, ok, Config#elixir_code_server{loaded=[Path|Config#elixir_code_server.loaded]} };

handle_call({at_exit, AtExit}, _From, Config) ->
  { reply, ok, Config#elixir_code_server{at_exit=[AtExit|Config#elixir_code_server.at_exit]} };

handle_call({argv, Argv}, _From, Config) ->
  { reply, ok, Config#elixir_code_server{argv=Argv} };

handle_call({compiler_options, Options}, _From, Config) ->
  Old = Config#elixir_code_server.compiler_options,
  New = orddict:merge(fun(_K, _V1, V2) -> V2 end, Old, Options),
  { reply, ok, Config#elixir_code_server{compiler_options=normalize_compiler_options(New)} };

handle_call(loaded, _From, Config) ->
  { reply, Config#elixir_code_server.loaded, Config };

handle_call(at_exit, _From, Config) ->
  { reply, Config#elixir_code_server.at_exit, Config };

handle_call(argv, _From, Config) ->
  { reply, Config#elixir_code_server.argv, Config };

handle_call(compiler_options, _From, Config) ->
  { reply, Config#elixir_code_server.compiler_options, Config };

handle_call(_Request, _From, Config) ->
  { reply, undef, Config }.

handle_cast(_Request, Config) ->
  { noreply, Config }.

handle_info(_Request, Config) ->
  { noreply, Config }.

terminate(Reason, Config) ->
  io:format("[FATAL] ~p crashed:\n~p~n", [?MODULE, Reason]),
  io:format("[FATAL] ~p snapshot:\n~p~n", [?MODULE, Config]),
  ok.

code_change(_Old, Config, _Extra) ->
  { ok, Config }.

%% Helpers

normalize_compiler_options(New0) ->
  New1 = orddict:update(output_dir, fun to_char_list/1, New0),
  New2 = orddict:update(discovery, fun(X) -> lists:map(fun to_char_list/1, X) end, New1),
  New2.

to_char_list(nil) -> nil;
to_char_list(List) when is_list(List) -> List;
to_char_list(Binary) when is_binary(Binary) -> binary_to_list(Binary).
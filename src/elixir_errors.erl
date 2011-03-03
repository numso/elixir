% A bunch of helpers to help to deal with errors in Elixir source code.
% This is not exposed in the Elixir language.
% TODO Remove strings from internal errors
-module(elixir_errors).
-export([error/1, file_format/3, file_error/4, syntax_error/4,
  handle_file_warning/2, handle_file_error/2, format_error/2, format_error/1]).
-include("elixir.hrl").

error(Reason) -> erlang:error(Reason).

file_format(Line, Filename, Message) ->
  lists:flatten(io_lib:format("~ts:~w: ~ts", [Filename, Line, Message])).

file_error(Reason, Line, Filename, Message) ->
  elixir_errors:error({Reason, file_format(Line, Filename, Message)}).

syntax_error(Line, Filename, user, Token) ->
  syntax_error(Line, Filename, Token, "");

syntax_error(Line, Filename, Error, Token) when is_atom(Error) ->
  syntax_error(Line, Filename, [atom_to_list(Error), $\s], Token);

syntax_error(Line, Filename, Error, Token) ->
  file_error(badsyntax, Line, Filename, lists:flatten([Error, Token])).

% Handle warnings

handle_file_warning(Filename, {Line,_,{unused_var,self}}) ->
  [];

handle_file_warning(Filename, {Line,_,nomatch_clause_type}) ->
  [];

handle_file_warning(Filename, {Line,Module,Desc}) ->
  Message = format_error(Module, Desc),
  io:format(file_format(Line, Filename, Message) ++ [$\n]).

% Handle errors

handle_file_error(Filename, {Line, Module, {undefined_function, {Name, Arity} }}) ->
  Message = format_error(Module, { undefined_function, {Name, Arity} }),
  file_error(undefined_identifier, Line, Filename, Message);

handle_file_error(Filename, {Line,Module,Desc}) ->
  Message = format_error(Module, format_error(Desc)),
  file_error(reason_from_desc(Desc), Line, Filename, Message).

reason_from_desc(Desc) when is_tuple(Desc) ->
  element(1, Desc);

reason_from_desc(Desc) ->
  Desc.

% Format each error

format_error(_, {undefined_function, {Name, Arity}}) ->
  case Arity - 1 of
    0 -> io_lib:format("undefined variable or local method ~s", [Name]);
    Else -> io_lib:format("undefined local method ~s/~w", [Name, Arity-1])
  end;

format_error(_, {changed_visibility,{Name,Visibility}}) ->
  io_lib:format("method ~s already defined with visibility ~s\n", [Name, Visibility]);

format_error(_, {unused_function, {Name, Arity}}) ->
  io_lib:format("unused local method ~s/~w\n", [Name, Arity-1]);

format_error([], Desc) ->
  io_lib:format("~p", [Desc]);

format_error(Module, Desc) ->
  Module:format_error(Desc).

format_error(Desc) -> format_error([], Desc).
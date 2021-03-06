%% ==========================================================================================================
%% PGPool - A PosgreSQL client that automatically uses connection pools and reconnects in case of errors.
%%
%% The MIT License (MIT)
%%
%% Copyright (c) 2016 Roberto Ostinelli <roberto@ostinelli.net> and Neato Robotics, Inc.
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.
%% ==========================================================================================================
-module(pgpool_SUITE).

%% callbacks
-export([all/0]).
-export([init_per_suite/1, end_per_suite/1]).
-export([groups/0, init_per_group/2, end_per_group/2]).
-export([init_per_testcase/2, end_per_testcase/2]).

%% tests
-export([
    squery_without_timeout/1,
    squery_with_timeout/1,
    equery_without_timeout/1,
    equery_with_timeout/1,
    batch/1
]).

%% include
-include_lib("common_test/include/ct.hrl").


%% ===================================================================
%% Callbacks
%% ===================================================================

%% -------------------------------------------------------------------
%% Function: all() -> GroupsAndTestCases | {skip,Reason}
%% GroupsAndTestCases = [{group,GroupName} | TestCase]
%% GroupName = atom()
%% TestCase = atom()
%% Reason = term()
%% -------------------------------------------------------------------
all() ->
    [
        {group, common_tests}
    ].

%% -------------------------------------------------------------------
%% Function: groups() -> [Group]
%% Group = {GroupName,Properties,GroupsAndTestCases}
%% GroupName = atom()
%% Properties = [parallel | sequence | Shuffle | {RepeatType,N}]
%% GroupsAndTestCases = [Group | {group,GroupName} | TestCase]
%% TestCase = atom()
%% Shuffle = shuffle | {shuffle,{integer(),integer(),integer()}}
%% RepeatType = repeat | repeat_until_all_ok | repeat_until_all_fail |
%%			   repeat_until_any_ok | repeat_until_any_fail
%% N = integer() | forever
%% -------------------------------------------------------------------
groups() ->
    [
        {common_tests, [shuffle], [
            squery_without_timeout,
            squery_with_timeout,
            equery_without_timeout,
            equery_with_timeout,
            batch
        ]}
    ].
%% -------------------------------------------------------------------
%% Function: init_per_suite(Config0) ->
%%				Config1 | {skip,Reason} |
%%              {skip_and_save,Reason,Config1}
%% Config0 = Config1 = [tuple()]
%% Reason = term()
%% -------------------------------------------------------------------
init_per_suite(Config) ->
    %% set environments
    pgpool_test_suite_helper:set_environment_variables(),
    %% start pgpool
    pgpool:start(),
    %% return
    Config.

%% -------------------------------------------------------------------
%% Function: end_per_suite(Config0) -> void() | {save_config,Config1}
%% Config0 = Config1 = [tuple()]
%% -------------------------------------------------------------------
end_per_suite(_Config) ->
    pgpool:stop().

%% -------------------------------------------------------------------
%% Function: init_per_group(GroupName, Config0) ->
%%				Config1 | {skip,Reason} |
%%              {skip_and_save,Reason,Config1}
%% GroupName = atom()
%% Config0 = Config1 = [tuple()]
%% Reason = term()
%% -------------------------------------------------------------------
init_per_group(_GroupName, Config) -> Config.

%% -------------------------------------------------------------------
%% Function: end_per_group(GroupName, Config0) ->
%%				void() | {save_config,Config1}
%% GroupName = atom()
%% Config0 = Config1 = [tuple()]
%% -------------------------------------------------------------------
end_per_group(_GroupName, _Config) -> ok.

% ----------------------------------------------------------------------------------------------------------
% Function: init_per_testcase(TestCase, Config0) ->
%				Config1 | {skip,Reason} | {skip_and_save,Reason,Config1}
% TestCase = atom()
% Config0 = Config1 = [tuple()]
% Reason = term()
% ----------------------------------------------------------------------------------------------------------
init_per_testcase(_TestCase, Config) ->
    %% create table films
    {ok, [], []} = pgpool:squery(pgpool_test, "DROP TABLE IF EXISTS films;"),
    {ok, [], []} = pgpool:squery(pgpool_test, "CREATE TABLE films(
        id          SERIAL    PRIMARY KEY,
        name        TEXT      NOT NULL,
        year        INT       NOT NULL
    );"),
    %% return
    Config.

% ----------------------------------------------------------------------------------------------------------
% Function: end_per_testcase(TestCase, Config0) ->
%				void() | {save_config,Config1} | {fail,Reason}
% TestCase = atom()
% Config0 = Config1 = [tuple()]
% Reason = term()
% ----------------------------------------------------------------------------------------------------------
end_per_testcase(_TestCase, _Config) ->
    %% drop table films
    {ok, [], []} = pgpool:squery(pgpool_test, "DROP TABLE IF EXISTS films;").

%% ===================================================================
%% Tests
%% ===================================================================
squery_without_timeout(_Config) ->
    {ok, 1} = pgpool:squery(pgpool_test, "INSERT INTO films (name, year) VALUES ('First Movie', 1972);"),
    {ok, [
        {column, <<"id">>, int4, _, _, _},
        {column, <<"name">>, text, _, _, _},
        {column, <<"year">>, int4, _, _, _}
    ], [
        {<<"1">>, <<"First Movie">>, <<"1972">>}
    ]} = pgpool:squery(pgpool_test, "SELECT * FROM films WHERE year = 1972;").

squery_with_timeout(_Config) ->
    {ok, 1} = pgpool:squery(pgpool_test, "INSERT INTO films (name, year) VALUES ('First Movie', 1972);", 1000),
    {ok, [
        {column, <<"id">>, int4, _, _, _},
        {column, <<"name">>, text, _, _, _},
        {column, <<"year">>, int4, _, _, _}
    ], [
        {<<"1">>, <<"First Movie">>, <<"1972">>}
    ]} = pgpool:squery(pgpool_test, "SELECT * FROM films WHERE year = 1972;", 1000).

equery_without_timeout(_Config) ->
    {ok, 1} = pgpool:equery(pgpool_test, "INSERT INTO films (name, year) VALUES ($1, $2);", ["First Movie", 1972]),
    {ok, [
        {column, <<"id">>, int4, _, _, _},
        {column, <<"name">>, text, _, _, _},
        {column, <<"year">>, int4, _, _, _}
    ], [
        {1, <<"First Movie">>, 1972}
    ]} = pgpool:equery(pgpool_test, "SELECT * FROM films WHERE year = $1;", [1972]).

equery_with_timeout(_Config) ->
    {ok, 1} = pgpool:equery(pgpool_test, "INSERT INTO films (name, year) VALUES ($1, $2);", ["First Movie", 1972], 1000),
    {ok, [
        {column, <<"id">>, int4, _, _, _},
        {column, <<"name">>, text, _, _, _},
        {column, <<"year">>, int4, _, _, _}
    ], [
        {1, <<"First Movie">>, 1972}
    ]} = pgpool:equery(pgpool_test, "SELECT * FROM films WHERE year = $1;", [1972], 1000).

batch(_Config) ->
    S1 = "INSERT INTO films (name, year) VALUES ($1, $2);",
    [{ok, 1}, {ok, 1}] = pgpool:batch(pgpool_test, [
        {S1, ["First Movie", 1972]},
        {S1, ["Second Movie", 1978]}
    ]),

    S2 = "SELECT * FROM films WHERE year = $1;",
    [
        {ok, [{1, <<"First Movie">>, 1972}]},
        {ok, [{2, <<"Second Movie">>, 1978}]}
    ] = pgpool:batch(pgpool_test, [
        {S2, [1972]},
        {S2, [1978]}
    ]).

-module(server).
-export([loop/1,start/0,terminate/0,clients/0]).
-include_lib("../include/defs.hrl").

start() ->
    Pid = spawn(fun() -> loop(#server_st{clients=orddict:new(),events=orddict:new()}) end),
	catch(unregister(?MODULE)),
	register(?MODULE,Pid).
	
terminate() ->
    server ! shutdown.
clients() ->
    Ref= make_ref(),
	server ! {self(),Ref,{clients}},
	receive
	   {Ref,C} -> C
	end.
	
loop(State) ->
	receive
		{Client,Ref,{subscribe}} ->
		   Ref_monitor = erlang:monitor(process,Client),
		   New = orddict:store(Ref_monitor,Client,State#server_st.clients),
		   Client ! {Ref,ok},
		   loop(State#server_st{clients=New});
		{Client,Waiting,Ref,{add,Name,Description,Delay}} ->
		   Pid = event:new_event(Name,Description,Delay),
		   case orddict:find(Name,State#server_st.events) of
		         {ok,_} ->
				     Client ! {Ref,error,"You have added the same one"},
					 loop(State);
				 _ -> ok
		   end,
		   
		   New = orddict:store(Name,#event_st{name=Name,description=Description,pid=Pid,client=Waiting,timeout=Delay},State#server_st.events),
		   Client ! {Ref,ok},
		   loop(State#server_st{events=New});
		{Client,Ref,{cancel,Name}} ->
		   New = case orddict:find(Name,State#server_st.events) of
					{ok,E} ->
						  event:cancel(E#event_st.pid),
						  Client ! {Ref,ok},
						  orddict:erase(Name,State#server_st.events);
				    error ->
					      Client ! {Ref,error,"You do not have this reminder"},
						  State#server_st.events
				end,
		   loop(State#server_st{events=New});
		{Client,Ref,{show_events}} -> 
		   Client ! {Ref,[900007680|State#server_st.events]},
		   loop(State);
		{Pid,Ref,{clients}} ->
		   Pid  ! {Ref,State#server_st.clients},
		   loop(State);
		{done,Name} ->
			New = case orddict:find(Name,State#server_st.events) of
				   {ok,E} ->
				        E#event_st.client ! {done,Name,E#event_st.description},
						orddict:erase(Name,State#server_st.events);
					error ->
						State#server_st.events
					end,
			loop(State#server_st{events=New});
		shutdown ->
		   exit(shutdown);
		upgrade ->
		   ?MODULE:loop(State);
		{'DOWN',Ref,process,_,_}->
		   loop(State#server_st{clients=orddict:erase(Ref,State#server_st.clients)})
        end.		   
-module(event).
-export([new_event/3,cancel/1]).
-include_lib("../include/defs.hrl").

new_event(Name,Description,Delay) ->
    Server = self(),
	spawn_link(fun() ->loop(#event_st{server=Server,name=Name,pid=self(),description=Description,timeout=Delay}) end).

cancel(Pid) ->
	Ref = erlang:monitor(process,Pid),
	Pid ! {self(),Ref,cancel},
	receive 
	   {Ref,ok} ->
			ok;
	   {'DOWN',_,process,_,_}->
	        ok
	end.
loop(State = #event_st{server=Server}) ->
	receive
	    {Server,Ref,cancel} ->
			Server ! {Ref,ok}
	after State#event_st.timeout*1000 ->
			Server ! {done,State#event_st.name}
	end.
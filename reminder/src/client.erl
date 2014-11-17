-module(client).
-export([login/0,add_event/3,cancel_event/1,display_events/0]).

login() ->
    Ref = make_ref(),
	case catch(server ! {self(),Ref,{'subscribe'}}) of
	     {'EXIT',_} -> erlang:error('server doesnot exist');
		 _ -> ok
    end,
	receive 
	    {Ref,ok} -> {success,"You have subscribed"}
		 
	after 3000 ->  {error,"unknow reason"}
	end.

add_event(Name,Description,Delay) ->
	Ref = make_ref(),
	case catch(server ! {self(),spawn(fun()-> receive {done,Name,Description} -> io:format("~p~p~p~n",[done,Name,Description]) end end),Ref,{'add',Name,Description,Delay}}) of
	     {'EXIT',_} -> erlang:error('server does not exist');
	     _ -> ok
	end,
    receive
	   {Ref,ok} -> {success,"You have already added one event"};
	   {Ref,error,Reason} -> {error,Reason}
	after 3000 -> {error,"unknown reason"}
	end.
	

cancel_event(Name) ->
    Ref = make_ref(),
	case catch(server ! {self(),Ref,{'cancel',Name}}) of
	    {'EXIT',_} -> erlang:error('server does not exist');
		 _ -> ok
	end,
	receive 
	   {Ref,ok} -> {success,"you have cancelled your reminder"};
	   {Ref,error,Reason} -> {error,Reason}
	after 3000 -> {error,"unknown reason"}
	end.

display_events() ->
    Ref = make_ref(),
	case catch(server ! {self(),Ref,{'show_events'}}) of
	     {'EXIT',_} -> erlang:error('server does not exist');
		 _ -> ok
	end,
	receive 
	   {Ref,E} -> {success,E} 
	after 3000 -> {error,"unknown reason"}
	
	end.
	
  
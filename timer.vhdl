library	IEEE;
use	IEEE.STD_LOGIC_1164.all;
use	IEEE.NUMERIC_STD.all;

entity	timer	is
	generic (	
				ClockFreq	:	integer				
			);
	port	(	
				clk			:	in	std_logic	;
				nRST		:	in	std_logic	;
				hours		:	out	integer		;
				minutes		:	out	integer		;
				seconds		:	out	integer		;
			);
end	entity;

architecture	RTL	of	timer	is
	procedure	IncrementWrap	(
								signal		counter			:	inout	integer	;
								constant	wrap_value		:	in	integer		;
								constant	enable			:	in	boolean		;
								variable	state_wrapped	:	in	boolean
							)	is
	begin
		if	enable	then
			if	(counter	=	wrap_value - 1)	then
				counter				<=	0;
				state_wrapped		:=	TRUE;
			else
				state_wrapped		:=	FALSE;
				counter				<=	counter + 1;
			end	if;
		end if;
	end	procedure;
							
		signal	ticks	:	integer;
begin
	
	process	(clk)	is
			variable	WRAPPED_tic	,	WRAPPED_sec		,	WRAPPED_min		,	WRAPPED_hr			:	boolean;
			variable	enable_tic	,	enable_seconds	,	enable_minutes	,	enable_hours		:	boolean;
	begin
	
		if	rising_edge(clk)	then
			
			if	(nRST	=	'0')	then
				ticks		<=	0;
				hours		<=	0;
				minutes		<=	0;
				seconds		<=	0;
			else
				enable_tic		:=	TRUE;
				
				IncrementWrap(ticks		,	ClockFreq	,	enable_tic		,	WRAPPED_tic);
				enable_seconds	:=	WRAPPED_tic;
				
				IncrementWrap(seconds	,		60		,	enable_seconds	,	WRAPPED_sec);
				enable_minutes	:=	WRAPPED_sec;
				
				IncrementWrap(minutes 	, 		60		, 	enable_minutes 	, 	WRAPPED_min);
				enable_hours	:=	WRAPPED_min;
				
				IncrementWrap(hours 	, 		24		, 	enable_hours	, 	WRAPPED_hr);
				
			end	if;				
		end	if;

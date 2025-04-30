library IEEE;
use	IEEE.STD_LOGIC_1164.all;
use	IEEE.NUMERIC_STD.all;

entity	even_parity	is
	generic(
				N		:	integer	:=	4;
			);
	port	(
				i_data	:	in	std_logic_vector(N-1 downto	0);
				o_odd	:	out	std_logic;
			);
end	even_parity;

architecture	RTL	of	even_parity	is
begin
	process	(data)
		variable	tmp	:	bit	:=	0;
	begin
		for	i	in	data'low	to	data'high	loop
			tmp		:=	tmp	xor	data(i);
		end	loop;
		odd		<=	tmp;
	end	process;
end	RTL;

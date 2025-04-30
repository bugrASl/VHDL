library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity full_adder_nbit	is
	generic	(	
				N			:	integer	:=	4
			);
	port	(	
				i_a			:	std_logic_vector(N-1 downto	0);
				i_b			:	std_logic_vector(N-1 downto	0);
				i_carry		:	std_logic;
				o_sum		:	std_logic_vector(N-1 downto	0);
				o_carry		:	std_logic
			);
end	entity;

architecture	STRUCT	of	full_adder_nbit	is

		signal	carry		:	std_logic_vector(N downto 0);
		
	component	full_adder	is	
		port	(
					A, B, Carry_in : in  std_logic;
					Sum, Carry     : out std_logic
				);
	end component;

begin
	
	carry(0)	<=	i_carry;
	
	gen_adders	:	for	i in 0 to N-1	generate
		FA_i	:	full_adder
			port	map(
							A        => i_a(i),
							B        => i_b(i),
							Carry_in => carry(i),
							Sum      => o_sum(i),
							Carry    => carry(i+1)
						);
	end	generate;
	
	o_carry		<=	carry(N);
	
end architecture;

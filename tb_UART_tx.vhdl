library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.parity_pkg.all;

entity tb_UART_tx is
end tb_UART_tx;

architecture Behavioral of tb_UART_tx is
    constant c_ClkFreq     	: integer 	:= 50_000_000;
    constant c_BaudRate    	: integer 	:= 1_843_200;
    constant c_DataBit     	: integer 	:= 8;
    constant c_clock_period	: time    	:= 20 ns;

    signal i_clk       		: std_logic := '0';
    signal i_nRST      		: std_logic := '1';
    signal i_tx_start  		: std_logic := '0';
    signal i_data      		: std_logic_vector(c_DataBit-1 downto 0) := (others => '0');

    -- Output signals for each DUT
    signal o_data_even_1sb, o_data_even_2sb     : std_logic;
    signal o_data_odd_1sb,  o_data_odd_2sb      : std_logic;
    signal o_data_none_1sb, o_data_none_2sb     : std_logic;
    signal o_tx_done_even_1sb, o_tx_done_even_2sb : std_logic;
    signal o_tx_done_odd_1sb,  o_tx_done_odd_2sb  : std_logic;
    signal o_tx_done_none_1sb, o_tx_done_none_2sb : std_logic;

    component UART_tx
        generic (
            c_ClkFreq    : integer;
            c_BaudRate   : integer;
            c_DataBit    : integer;
            c_StopBit    : integer;
            c_UseParity  : boolean;
            c_ParityType : parity_type
        );
        port (
            i_nRST     : in  std_logic;
            i_clk      : in  std_logic;
            i_tx_start : in  std_logic;
            i_data     : in  std_logic_vector(c_DataBit-1 downto 0);
            o_data     : out std_logic;
            o_tx_done  : out std_logic
        );
    end component;

begin
    -- Clock generation
    clk_proc : process
    begin
        while true loop
            i_clk <= '0'; wait for c_clock_period / 2;
            i_clk <= '1'; wait for c_clock_period / 2;
        end loop;
    end process;

    -- DUT Instantiations
	DUT_EVEN_1SB : UART_tx
        generic map (c_ClkFreq, c_BaudRate, c_DataBit, 1, true, EVEN)
        port map (i_nRST, i_clk, i_tx_start, i_data, o_data_even_1sb, o_tx_done_even_1sb);

    DUT_EVEN_2SB : UART_tx
        generic map (c_ClkFreq, c_BaudRate, c_DataBit, 2, true, EVEN)
        port map (i_nRST, i_clk, i_tx_start, i_data, o_data_even_2sb, o_tx_done_even_2sb);

    DUT_ODD_1SB : UART_tx
        generic map (c_ClkFreq, c_BaudRate, c_DataBit, 1, true, ODD)
        port map (i_nRST, i_clk, i_tx_start, i_data, o_data_odd_1sb, o_tx_done_odd_1sb);

    DUT_ODD_2SB : UART_tx
        generic map (c_ClkFreq, c_BaudRate, c_DataBit, 2, true, ODD)
        port map (i_nRST, i_clk, i_tx_start, i_data, o_data_odd_2sb, o_tx_done_odd_2sb);

    DUT_NONE_1SB : UART_tx
        generic map (c_ClkFreq, c_BaudRate, c_DataBit, 1, false, EVEN)
        port map (i_nRST, i_clk, i_tx_start, i_data, o_data_none_1sb, o_tx_done_none_1sb);

    DUT_NONE_2SB : UART_tx
        generic map (c_ClkFreq, c_BaudRate, c_DataBit, 2, false, EVEN)
        port map (i_nRST, i_clk, i_tx_start, i_data, o_data_none_2sb, o_tx_done_none_2sb);

    -- Stimuli process
    stim_proc : process
    begin
        -- IDLE Duration
		i_data		<= x"00";
		i_tx_start <= '0';
		i_nRST <= '1'; wait for 200 ns;
        -- Test vector 1
        i_data     <= x"55"; -- ASCII 'U' = 01010101
        i_tx_start <= '1'; wait for c_clock_period;
        i_tx_start <= '0';

        wait for  3 ms;
		
        -- Test vector 2
        i_data     <= x"A3";
        i_tx_start <= '1'; wait for c_clock_period;
        i_tx_start <= '0';

        wait for  3 ms;

        -- Test vector 3
        i_data     <= x"3C";
        i_tx_start <= '1'; wait for c_clock_period;
        i_tx_start <= '0';

        wait for  3 ms;

        assert false report "Simulation complete" severity failure;
    end process;
end Behavioral;
  

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity UART_tx is
    generic (
	--	HERE GENERIC IS USED IN ORDER TO BE MORE FLEXIBLE
	--	WHILE IMPLEMENTING THIS UART_TX MODULE
		
        c_ClkFreq      	: integer 		:= 50_000_000;
        c_BaudRate     	: integer 		:= 1_843_200;
        c_DataBit      	: integer 		:= 8;
        c_StopBit      	: integer 		:= 2;
		c_UseParity		: boolean 		:= true;
		c_ParityType 	: parity_type 	:= EVEN
    );
    port (
        i_nRST      : in  std_logic;	--NEGATIVE RESET INPUT IS USED
        i_clk       : in  std_logic;
        i_tx_start  : in  std_logic;
        i_data      : in  std_logic_vector(c_DataBit-1 downto 0);
        o_data      : out std_logic;
        o_tx_done   : out std_logic
    );
end UART_tx;

architecture Behavioral of UART_tx is
    type UART_TX_STATE is (TX_IDLE, TX_START, TX_DATA, TX_STOP);
		constant c_TicksPerBit  : integer := c_ClkFreq / c_BaudRate;
		constant TickCounterLim : integer := c_TicksPerBit - 1;
		constant StopBitLim     : integer := (c_StopBit * c_TicksPerBit) - 1;
		constant MAX_SHIFT_WIDTH : integer := c_DataBit + 1;
    
		signal parity_bit       : std_logic := '0';
		signal current_state    : UART_TX_STATE := TX_IDLE;
		signal TickCounter      : integer range 0 to TickCounterLim := 0;
		signal BitCounter       : integer range 0 to MAX_SHIFT_WIDTH-1 := 0;
		signal StopCounter      : integer range 0 to StopBitLim := 0;
		signal ShiftRegister    : std_logic_vector(MAX_SHIFT_WIDTH-1 downto 0) := (others => '0');
	component parity_gen is
		generic (
        		N		: integer	:= 8;
        		parity_type	: parity_type
		);
		port (
        		i_data   	: in  std_logic_vector(N-1 downto 0);
        		o_parity 	: out std_logic
		);
	end component;

	

    procedure reset_signals is
    begin
        TickCounter   <= 0;
        BitCounter    <= 0;
        StopCounter   <= 0;
        ShiftRegister <= (others => '0');
        o_data        <= '1';
        o_tx_done     <= '0';
        current_state <= TX_IDLE;
    end procedure;

    procedure shift_data is
    begin
        ShiftRegister <= ShiftRegister(ShiftRegister'high-1 downto 0) & '0';
    end procedure;

    procedure tx_idle_state is
    begin
        o_data    <= '1';
        o_tx_done <= '0';

        if i_tx_start = '1' then
            if c_UseParity then
                ShiftRegister(c_DataBit-1 downto 0) <= i_data;
                ShiftRegister(c_DataBit)           <= parity_bit;
                BitCounter <= 0;
            else
                ShiftRegister(c_DataBit-1 downto 0) <= i_data;
                ShiftRegister(c_DataBit)           <= '0';
                BitCounter <= 0;
            end if;
            current_state <= TX_START;
            TickCounter   <= 0;
        end if;
    end procedure;

    procedure tx_start_state is
    begin
        if TickCounter = TickCounterLim then
            TickCounter   <= 0;
            o_data        <= ShiftRegister(0);
            shift_data;
            current_state <= TX_DATA;
        else
            TickCounter	  <= TickCounter + 1;
        end if;
    end procedure;

    procedure tx_data_state is
    begin
        o_data <= ShiftRegister(0);
        if TickCounter = TickCounterLim then
            TickCounter <= 0;
            if (c_UseParity and BitCounter = c_DataBit) or
               (not c_UseParity and BitCounter = c_DataBit - 1) then
                current_state <= TX_STOP;
                StopCounter   <= 0;
                o_data        <= '1';
            else
                shift_data;
                BitCounter <= BitCounter + 1;
            end if;
        else
            TickCounter <= TickCounter + 1;
        end if;
    end procedure;

    procedure tx_stop_state is
    begin
        o_data <= '1';
        if StopCounter = StopBitLim then
            o_tx_done     <= '1';
            current_state <= TX_IDLE;
        else
            StopCounter   <= StopCounter + 1;
        end if;
    end procedure;
	
/***
	BELOW IS EXPLAINED WHICH STATE OF UART_TX TRIGGERS WHICH PROCEDURE
	THIS CHOICE OF CODING STRUCTURE IS INTENDED TO BE MORE READABLE AND BEGINNER FRIENDLY
	I HOPE BEGINNERS UNDERSTAND THE RELATIONSHIPS AND FSM STRUCTURE SO THAT
	THEY WILL NOT HAVE AS DIFFICULT AS I DID
***/
begin
	parity_gen_inst : parity_gen
        generic map (
            N 		=> c_DataBit,
            parity_type => c_ParityType
        )
        port map (
            i_data   	=> i_data,
            o_parity 	=> parity_bit
        );	
		
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_nRST = '0' then
                reset_signals;
            else
                case current_state is
                    when TX_IDLE  => tx_idle_state;
                    when TX_START => tx_start_state;
                    when TX_DATA  => tx_data_state;
                    when TX_STOP  => tx_stop_state;
                end case;
            end if;
        end if;
    end process;
end Behavioral;

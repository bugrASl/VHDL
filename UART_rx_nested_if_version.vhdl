library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.parity_pkg.all;

entity UART_rx is
    generic (
        c_ClkFreq    : integer := 50_000_000;
        c_BaudRate   : integer := 1_843_200;
        c_DataBit    : integer := 8;
        c_StopBit    : integer := 2;
        c_UseParity  : boolean := true;
        c_ParityType : parity_type := EVEN
    );
    port (
        i_nRST     : in  std_logic;
        i_clk      : in  std_logic;
        i_data     : in  std_logic;
        o_rx_done  : out std_logic;
        o_data     : out std_logic_vector(c_DataBit-1 downto 0);
        o_parity_err : out std_logic
    );
end UART_rx;

architecture Behavioral of UART_rx is
    type RX_STATE_TYPE is (RX_IDLE, RX_START, RX_DATA, RX_PARITY, RX_STOP);

    constant c_TicksPerBit  : integer := c_ClkFreq / c_BaudRate;
    constant c_HalfBitTick  : integer := c_TicksPerBit / 2;

    signal r_state          : RX_STATE_TYPE := RX_IDLE;
    signal r_TickCounter    : integer range 0 to c_TicksPerBit - 1 := 0;
    signal r_BitCounter     : integer range 0 to c_DataBit - 1 := 0;
    signal r_rx_shift_reg   : std_logic_vector(c_DataBit - 1 downto 0) := (others => '0');
    signal r_parity_bit     : std_logic := '0';
    signal r_stop_counter   : integer range 0 to c_StopBit := 0;

    component parity_gen
        generic (
            N           : integer := 8;
            parity_type : parity_type := EVEN
        );
        port (
            i_data   : in  std_logic_vector(N-1 downto 0);
            o_parity : out std_logic
        );
    end component;

    signal calc_parity  : std_logic;

begin
    -- Instantiate parity generator
    u_parity_check : parity_gen
        generic map (
            N => c_DataBit,
            parity_type => c_ParityType
        )
        port map (
            i_data => r_rx_shift_reg,
            o_parity => calc_parity
        );

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_nRST = '0' then
                r_state        <= RX_IDLE;
                r_TickCounter  <= 0;
                r_BitCounter   <= 0;
                r_stop_counter <= 0;
                o_rx_done      <= '0';
                o_data         <= (others => '0');
                o_parity_err   <= '0';
            else
                case r_state is
                    when RX_IDLE =>
                        o_rx_done <= '0';
                        if i_data = '0' then -- start bit detected
                            r_TickCounter <= 0;
                            r_state <= RX_START;
                        end if;

                    when RX_START =>
                        if r_TickCounter = c_HalfBitTick then
                            r_TickCounter <= 0;
                            r_BitCounter <= 0;
                            r_state <= RX_DATA;
                        else
                            r_TickCounter <= r_TickCounter + 1;
                        end if;

                    when RX_DATA =>
                        if r_TickCounter = c_TicksPerBit - 1 then
                            r_TickCounter <= 0;
                            r_rx_shift_reg(r_BitCounter) <= i_data;
                            if r_BitCounter = c_DataBit - 1 then
                                if c_UseParity then
                                    r_state <= RX_PARITY;
                                else
                                    r_state <= RX_STOP;
                                end if;
                            else
                                r_BitCounter <= r_BitCounter + 1;
                            end if;
                        else
                            r_TickCounter <= r_TickCounter + 1;
                        end if;

                    when RX_PARITY =>
                        if r_TickCounter = c_TicksPerBit - 1 then
                            r_TickCounter <= 0;
                            r_parity_bit <= i_data;
                            if i_data /= calc_parity then
                                o_parity_err <= '1';
                            else
                                o_parity_err <= '0';
                            end if;
                            r_state <= RX_STOP;
                        else
                            r_TickCounter <= r_TickCounter + 1;
                        end if;

                    when RX_STOP =>
                        if r_TickCounter = c_TicksPerBit - 1 then
                            r_TickCounter <= 0;
                            if r_stop_counter = c_StopBit - 1 then
                                o_data <= r_rx_shift_reg;
                                o_rx_done <= '1';
                                r_state <= RX_IDLE;
                                r_stop_counter <= 0;
                            else
                                r_stop_counter <= r_stop_counter + 1;
                            end if;
                        else
                            r_TickCounter <= r_TickCounter + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
end Behavioral;

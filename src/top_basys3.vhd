--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- COMPONENTS----------------------------------
	-- CPU cycle FSM
    component controller_fsm is
        Port ( i_reset : in STD_LOGIC;
               i_adv : in STD_LOGIC;
               o_cycle : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component controller_fsm;
    
    -- ALU
    component ALU is
        Port (  i_A : in std_logic_vector (7 downto 0);
                i_B : in std_logic_vector (7 downto 0);
                i_op : in std_logic_vector (2 downto 0);   -- ADD "000", SUB "001", AND "010", OR "011"
                o_result : out std_logic_vector (7 downto 0);
                o_flags : out std_logic_vector (3 downto 0)   -- N Z C V
        );
    end component ALU;
    
    -- Drives TDM...set to 4KHz (k_DIV = 12500)
    component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
    
    -- 2s Compliment Converter
    component twos_comp is
        port (
            i_bin: in std_logic_vector(7 downto 0);
            o_sign: out std_logic;
            o_hund: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twos_comp;
    
    -- TDM...used to mutliplex the data tranx to 7SD
    component TDM4 is
	generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
               i_reset		: in  STD_LOGIC; -- asynchronous
               i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
        );
    end component TDM4;
    
    -- 7S Decoder
    component sevenseg_decoder is
        Port ( i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
               o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
    end component sevenseg_decoder;


    -- SIGNALS -------------------------------------------
    signal w_cycle : std_logic_vector (3 downto 0);
    signal w_A : std_logic_vector (7 downto 0);
    signal w_B : std_logic_vector (7 downto 0);
    signal w_ALU_result : std_logic_vector (7 downto 0);
    signal w_ALU_mux : std_logic_vector (7 downto 0);
    signal w_slow_clk : std_logic;
    signal w_sign : std_logic;                            -- neg sign (if needed)
    signal w_hundreds : std_logic_vector (3 downto 0);    -- digit in hundreds place
    signal w_tens : std_logic_vector (3 downto 0);        -- digit in tens place
    signal w_ones : std_logic_vector (3 downto 0);        --digit in ones place
    signal w_TDM_data: std_logic_vector (3 downto 0);
    signal w_TDM_sel : std_logic_vector (3 downto 0);
  
begin
	-- PORT MAPS ----------------------------------------
    -- CPU cycle FSM
    controller_fsm_inst : controller_fsm
        Port Map (  i_reset => btnU,
                    i_adv => btnC,
                    o_cycle => w_cycle
        );
    
    -- ALU
    ALU_inst : ALU
        Port Map (  i_A => w_A,
                    i_B => w_B,
                    i_op => sw (15 downto 13),   -- ADD "000", SUB "001", AND "010", OR "011"
                    o_result => w_ALU_result,
                    o_flags => led (15 downto 12)   -- N Z C V
        );
    
    -- Drives TDM...set to 4KHz (k_DIV = 12500)
    clock_divider_inst : clock_divider
        generic map (k_DIV => 0) --12500)              -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port map (  i_clk => clk,
                    i_reset => btnU,		   -- asynchronous
                    o_clk => w_slow_clk		   -- divided (slow) clock
        );
	
	-- 2s Compliment Converter
    twos_comp_inst : twos_comp
        port map (
            i_bin => w_ALU_mux,
            o_sign => w_sign,
            o_hund => w_hundreds,
            o_tens => w_tens,
            o_ones => w_ones
        );
    
    -- TDM...used to mutliplex the data tranx to 7SD
    TDM4_inst : TDM4
	    generic map(k_WIDTH => 4) -- bits in input and output
        Port Map (  i_clk => w_slow_clk,
                    i_reset	=> '0', -- asynchronous
                    i_D3 => "0000", -- NEED TO UPDATE THIS WITH NEGATIVE SIGN SOMEHOW
                    i_D2 => w_hundreds,
                    i_D1 => w_tens,
                    i_D0 => w_ones,
                    o_data => w_TDM_data,
                    o_sel => an
        );
    
    -- 7S Decoder
    sevenseg_decoder_inst : sevenseg_decoder
        Port Map (  i_Hex => w_TDM_data,
                    o_seg_n => seg
        );

	
	-- CONCURRENT STATEMENTS ----------------------------
	w_ALU_mux <=  w_A          when w_cycle = "0010" else
	              w_B          when w_cycle = "0100" else
	              w_ALU_result when w_cycle = "1000" else
	              x"00";
	
	-- PROCESSES ----------------------------------------
	i_A_state_register : process(w_cycle(1))
	begin
        if rising_edge(w_cycle(1)) then
           w_A <= sw (7 downto 0);
        end if;
	end process i_A_state_register;
	
	i_B_state_register : process(w_cycle(2))
	begin
        if rising_edge(w_cycle(2)) then
           w_B <= sw (7 downto 0);
        end if;
	end process i_B_state_register;
	
	
end top_basys3_arch;

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
--|
--| ALU OPCODES:
--|
--|     ADD     000
--|     SUB     001
--|     AND     010
--|     OR      011
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity ALU is
    Port (  i_A : in std_logic_vector (7 downto 0);
            i_B : in std_logic_vector (7 downto 0);
            i_op : in std_logic_vector (2 downto 0);
            o_result : out std_logic_vector (7 downto 0);
            o_flags : out std_logic_vector (3 downto 0)   -- N Z C V
    );
end ALU;

architecture behavioral of ALU is 

	-- declare components
    component ripple_adder is
        Port ( A : in std_logic_vector (7 downto 0);
               B : in std_logic_vector (7 downto 0);
               Cin : in std_logic;
               S : out std_logic_vector (7 downto 0);
               Cout : out std_logic
       );
    end component ripple_adder;
    
    -- declare signals
    signal w_i_B : std_logic_vector (7 downto 0);      -- wire from add_sub? mux to port B of adder
    signal w_A_and_B : std_logic_vector (7 downto 0);   -- wire for AND function
    signal w_A_or_B : std_logic_vector (7 downto 0);    -- wire for OR function
    signal w_adder_result : std_logic_vector (7 downto 0);    -- result of ripple_adder
    signal w_Cout : std_logic;                          -- Cout of ripple_adder
    signal w_ALU_result : std_logic_vector (7 downto 0);    -- result of ALU output mux

begin
	-- PORT MAPS ----------------------------------------
    ripple_adder_inst : ripple_adder
    Port Map (
        A => i_A,
        B => w_i_B,         -- mux selects if i_B is passed to adder (addition) or not i_B is passed to adder (subtraction) via w_i_B
        Cin => i_op(0),     -- if i_op(0)='0' then A+B...if i_op(0)='1' then A-B (2s compliment)
        S => w_adder_result,
        Cout => w_Cout  
    );
	
	
	-- CONCURRENT STATEMENTS ----------------------------	
	w_i_B <=   i_B when (i_op(0) = '0') else   -- mux selects if i_B is passed to adder (addition) or not i_B is passed to adder (subtraction)
	           not i_B;
       
    w_ALU_result <= w_adder_result when i_op = "000" else      -- mux selects which operation is ouput by ALU
                w_adder_result when i_op = "001" else
                (i_A and i_B) when i_op = "010" else
                (i_A or i_B) when i_op = "011" else
                x"00";
    
    o_result <= w_ALU_result;               -- result of ALU output mux
    
    -- Negative flag
    o_flags(3) <= w_ALU_result(7);
    
    -- Zero flag
    o_flags(2) <= not (w_ALU_result(7) or w_ALU_result(6) or w_ALU_result(5) or w_ALU_result(4) or w_ALU_result(3) or w_ALU_result(2) or w_ALU_result(1) or w_ALU_result(0));
    
    -- Carry flag
    o_flags(1) <= not(i_op(1)) and  w_Cout;
    
    -- oVerflow flag            
    o_flags(0) <= (not (i_op(0) xor i_A(7) xor i_B(7)))  and  (i_A(7) xor w_ALU_result(7))  and  (not i_op(1));
    
    
                
end behavioral;

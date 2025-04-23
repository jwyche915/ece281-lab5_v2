----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Lt Col Jason Wyche
-- 
-- Create Date: 04/14/2025 03:25:25 PM
-- Module Name: controller_fsm - Behavioral
-- Description: This file implements a CPU controller (Moore Machine) to be used as
--              a component within a simple CPU implemented on a Basys3 FPGA board.
--
--      The system operates as follows:
--          - The controller cycles through five states of a CPU
--              -- Ready
--              -- Load Operand A
--              -- Load Operand B
--              -- Execute Operation
--              -- Clear Display
--          - The controller outputs a 4-bit control signal, which moves data 
--              through the CPU
--          - The state transitions are user controlled via a button on the Basys3
--              board connected to the i_adv input
--          - i_reset asynchronously puts the controller in the 'ready' state
--
--          INPUTS:
--              i_reset --> reset signal
--              i_adv   --> advances controller to next state (cycle)
--
--          OUTPUR:
--              o_cycle (3:0) --> 4-bit signal indicating current cycle (control signal)
--                  '0001' --> CLEAR 7SD
--                  '0010' --> LOAD OPERAND A
--                  '0100' --> LOAD OPERAND B
--                  '1000' --> EXECUTE OPERATION 
--          
-- Dependencies: None
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture Behavioral of controller_fsm is

    -- define state machine type
    type sm_cycle is (clr_display, load_A, load_B, execute);
    
    -- signals to store current and next states
    signal current_cycle, next_cycle: sm_cycle;

begin
    -- CONCURRENT STATEMENTS -----------------------------------------
    
    -- NEXT STATE LOGIC
    next_cycle <=   sm_cycle'succ(current_cycle) when (current_cycle /= execute) else
                    clr_display;
                    
    -- OUTPUT LOGIC
    with current_cycle select
    o_cycle <=  "0001" when clr_display,
                "0010" when load_A,
                "0100" when load_B,
                "1000" when execute,
                "0001" when others;
                
  -- PROCESSES ----------------------------------------------------------
            
  -- State Register
  state_register: process (i_adv, i_reset)
  begin
        if i_reset = '1' then
            current_cycle <= clr_display;
        elsif rising_edge(i_adv) then
            current_cycle <= next_cycle;
        end if;
    end process; 

end Behavioral;

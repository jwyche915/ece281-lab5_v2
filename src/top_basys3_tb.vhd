----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/22/2025 05:06:35 PM
-- Design Name: 
-- Module Name: top_basys3_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
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

entity top_basys3_tb is
end top_basys3_tb;

architecture Behavioral of top_basys3_tb is

-- COMPONENTS
    component top_basys3 is
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
    end component top_basys3;
    
 -- SIGNALS
    signal w_clk : std_logic;
    signal w_sw : std_logic_vector (15 downto 0);
    signal w_btnU : std_logic;
    signal w_btnC : std_logic;
    signal w_led : std_logic_vector (15 downto 0);
    signal w_seg : std_logic_vector (6 downto 0);
    signal w_an : std_logic_vector (3 downto 0);
    
    -- Setup test clk (20 ns --> 50 MHz) and other signals
	constant k_clk_period : time := 20 ns;
		


begin
-- PORT MAPS ---------------------------
    top_basys3_inst : top_basys3
            port map (
                -- inputs
                clk  => w_clk,
                sw   => w_sw,
                btnU => w_btnU,
                btnC => w_btnC,
                -- outputs
                led => w_led,
                -- 7-segment display segments (active-low cathodes)
                seg => w_seg,
                -- 7-segment display active-low enables (anodes)
                an  => w_an
     );

-- PROCESSES ---------------------------
	-- Clock Process ------------------------------------
	clk_process : process
	begin
        w_clk <= '0';
        wait for k_clk_period/2;
        
        w_clk <= '1';
        wait for k_clk_period/2;
	end process clk_process;
	-----------------------------------------------------
	
	-- TEST PROCESS ---------------------
	test_process : process
	begin
	   w_sw (15 downto 13) <= "000";
	
	   w_btnC <= '0';
	   wait for k_clk_period;
	   w_btnC <= '1';
	   wait for k_clk_period;
	   w_btnC <= '0';
	
	   w_sw (7 downto 0) <= x"AB";
	   wait for k_clk_period;
	   w_btnC <= '1';
	   wait for k_clk_period;
	   w_btnC <= '0';
	   wait for k_clk_period * 2;
	   
	   w_sw (7 downto 0) <= x"CD";
	   wait for k_clk_period;
	   w_btnC <= '1';
	   wait for k_clk_period;
	   w_btnC <= '0';
	   wait for k_clk_period * 2;
	   
	   wait for k_clk_period;
	   w_btnC <= '1';
	   wait for k_clk_period;
	   w_btnC <= '0';
	   wait for k_clk_period * 2;
	   
	   wait for k_clk_period;
	   w_btnC <= '1';
	   wait for k_clk_period;
	   w_btnC <= '0';
	   
	   wait;	
	   
	end process test_process;


end Behavioral;

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Lt Col Jason Wyche
-- 
-- Create Date: 04/14/2025 03:54:15 PM
-- Module Name: controller_fsm_tb - Behavioral
-- Description: Test bench to test functionality of controller_fsm
-- 
-- Dependencies: controller_fsm.vhd
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity controller_fsm_tb is
end controller_fsm_tb;

architecture test_bench of controller_fsm_tb is
    -- declare component to be tested
    component controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component controller_fsm;
    
    -- test signals
    signal w_reset, w_adv : std_logic := '0';       -- input signals
    signal w_cycle : std_logic_vector (3 downto 0);              -- output signals
    
    -- i_adv of controller_fsm acts like the clock...create period for this clock
    constant k_adv_period : time := 20 ns;

begin
    -- PORT MAPS -----------------------------------------------------
    controller_fsm_inst : controller_fsm
    port map (
        i_reset => w_reset,
        i_adv   => w_adv,
        o_cycle => w_cycle
    );
    
    -- PROCESSES -----------------------------------------------------
    clock_process : process
    begin
         w_adv <= '0';
         wait for k_adv_period/2;
         
         w_adv <= '1';
         wait for k_adv_period/2;
    end process clock_process;
    
    test_process : process
    begin
        -- reset the FSM
        w_reset <= '1';
        wait for k_adv_period;
        w_reset <= '0';
        
        wait;       -- let FSM run (set sim to 240 ns to see a few cycles of FSM)
    end process test_process;


end test_bench;

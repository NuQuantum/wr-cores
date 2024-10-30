-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for Kasli SoC
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : xwrc_board_kasli.vhd
-- Author(s)  : Jonah Foley <jonah.foley@nu-quantum.com>
-- Company    : Nu Quantum Ltd.
-- Created    : 2024-10-30
-- Last update: 2024-10-30
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: When switching the clock select input to the system PLL, the PLL
-- loses lock, and the output clock goes low. This causes the AXI transaction
-- which initiated the register write to hang because the bresp channel cannot
-- be clocked through. This module avoids this by first staging the clock switch
-- and then enacting it after 2**g_reset_counter_bits cycles.
-------------------------------------------------------------------------------
-- Copyright (c) 2024 Nu Quantum Ltd.
-------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- either version 2.1 of the License, or (at your option) any
-- later version.
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE.  See the GNU Lesser General Public License for more
-- details.
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------
-- vsg_off port_012
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_misc.all;
  use ieee.numeric_std.all;

entity clk_switch_fsm is
  generic (
    -- The number of staging cycles is 2^g_reset_counter_bits
    g_reset_counter_bits : integer   := 8;
    -- The initial clk_switch_o value upon reset
    g_initial_value      : std_logic := '0'
  );
  port (
    -- The clock to run the FSM off
    clk_i        : in  std_logic;
    rst_n_i      : in  std_logic;
    -- Input and output select, synchronised to clk_i domain
    clk_switch_i : in  std_logic;
    clk_switch_o : out std_logic;
    rst_n_o      : out std_logic
  );
end entity clk_switch_fsm;

architecture rtl of clk_switch_fsm is

  signal clk_switch         : std_logic;
  signal clk_switch_update  : std_logic;
  signal clk_switch_release : std_logic;

  signal clk_switch_staged  : std_logic;

  signal countdown     : std_logic;
  signal delay_counter : unsigned(g_reset_counter_bits-1 downto 0);

  type t_state is (IDLE, INITIAL_DELAY, STAGE, RESET_RELEASE, CLOCK_SWITCH);
  signal present_state : t_state;
  signal next_state    : t_state;

begin

  process(clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        clk_switch <= '0';
      else
        clk_switch <= clk_switch_i;
      end if;
    end if;
  end process;

  -- There is a clock sw update when the current and previous values of clock switch
  -- differ
  clk_switch_update <= clk_switch xor clk_switch_i;

  process(clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        delay_counter <= to_unsigned((2**g_reset_counter_bits)-1, g_reset_counter_bits);
      else
        if (countdown = '1') then
          delay_counter <= delay_counter - 1;
        end if;
      end if;
    end if;
  end process;

  -- When there is a clk updated latch the current switch value into the staging area
  process(clk_i) begin
    if rising_edge(clk_i) then
      if (clk_switch_update = '1' and present_state = IDLE) then
        clk_switch_staged <= clk_switch_i;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------------
  -- The FSM
  -----------------------------------------------------------------------------------

  process(clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        present_state <= IDLE;
      else
        present_state <= next_state;
      end if;
    end if;
  end process;

  process(present_state, clk_switch_update, delay_counter) begin
    -- default values
    clk_switch_release <= '0';
    countdown <= '0';
    rst_n_o <= '1';
    next_state <= present_state;
    case present_state is
      when IDLE =>
        if clk_switch_update = '1' then
          next_state <= INITIAL_DELAY;
        end if;
      -- An initial delay where the clk sel register write can ack the AXI txn
      when INITIAL_DELAY =>
        countdown <= '1';
        if delay_counter = to_unsigned(0, g_reset_counter_bits) then
          next_state <= STAGE;
        end if;
      when STAGE =>
        countdown <= '1';
        rst_n_o <= '0';
        if delay_counter = to_unsigned(0, g_reset_counter_bits) then
          next_state <= RESET_RELEASE;
        end if;
      -- release the reset prior to switching the clock
      when RESET_RELEASE =>
        next_state <= CLOCK_SWITCH;
      when CLOCK_SWITCH =>
        clk_switch_release <= '1';
        next_state <= IDLE;
      when others => null;
    end case;
  end process;

  -- When the release signal is asserted implement the staged value
  process(clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        clk_switch_o <= g_initial_value;
      else
        if (clk_switch_release = '1') then
          clk_switch_o <= clk_switch_staged;
        end if;
      end if;
    end if;
  end process;

end architecture;

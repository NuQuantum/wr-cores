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
    -- The initial clk_sel_o value upon reset
    g_initial_value      : std_logic := '0'
  );
  port (
    -- The clock to run the FSM off
    clk_i     : in  std_logic;
    rst_n_i   : in  std_logic;
    -- Input and output select, synchronised to clk_i domain
    clk_sel_i : in  std_logic;
    clk_sel_o : out std_logic;
    rst_n_o   : out std_logic
  );
end entity clk_switch_fsm;

architecture rtl of clk_switch_fsm is

  signal clk_sel         : std_logic;
  signal clk_sel_changed  : std_logic;
  signal clk_sel_release : std_logic;

  signal clk_sel_staged  : std_logic;

  signal countdown     : std_logic;
  signal pll_reset_count_q : unsigned(g_reset_counter_bits-1 downto 0);

  type t_state is (ST_IDLE, ST_INITIAL_DELAY, ST_RESET);
  signal pll_reset_state_q : t_state;
  signal pll_reset_state_d : t_state;

begin

  -----------------------------------------------------------------------------------
  -- Detection of clock select change
  -----------------------------------------------------------------------------------
  -- We support both changing the select from 0->1 and 1->0
  -----------------------------------------------------------------------------------

  process(clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        clk_sel <= '0';
      else
        clk_sel <= clk_sel_i;
      end if;
    end if;
  end process;

  clk_sel_changed <= clk_sel xor clk_sel_i;

  -- When there is a clk updated latch the current switch value into the staging area
  process(clk_i) begin
    if rising_edge(clk_i) then
      if (clk_sel_changed = '1' and pll_reset_state_q = ST_IDLE) then
        clk_sel_staged <= clk_sel_i;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------------
  -- Counts the reset duration
  -----------------------------------------------------------------------------------

  process(clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        pll_reset_count_q <= to_unsigned((2**g_reset_counter_bits)-1, g_reset_counter_bits);
      else
        if (countdown = '1') then
          pll_reset_count_q <= pll_reset_count_q - 1;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------------
  -- The FSM
  -----------------------------------------------------------------------------------

  process(clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        pll_reset_state_q <= ST_IDLE;
      else
        pll_reset_state_q <= pll_reset_state_d;
      end if;
    end if;
  end process;

  process(pll_reset_state_q, clk_sel_changed, pll_reset_count_q) begin
    -- default values
    countdown         <= '0';
    rst_n_o           <= '1';
    clk_sel_release   <= '0';
    pll_reset_state_d <= pll_reset_state_q;

    case pll_reset_state_q is

      when ST_IDLE =>
        if clk_sel_changed = '1' then
          pll_reset_state_d <= ST_INITIAL_DELAY;
        end if;

      -- An initial delay where the clk sel register write can ack the AXI txn
      when ST_INITIAL_DELAY =>
        countdown <= '1';
        if pll_reset_count_q = to_unsigned(0, g_reset_counter_bits) then
          pll_reset_state_d <= ST_RESET;
        end if;

      when ST_RESET =>
        countdown        <= '1';
        rst_n_o          <= '0';
        -- release the staged value at the midpoint of the reset
        if pll_reset_count_q(g_reset_counter_bits - 1) = '0' then
          clk_sel_release <= '1';
        end if;
        if pll_reset_count_q = to_unsigned(0, g_reset_counter_bits) then
          pll_reset_state_d <= ST_IDLE;
        end if;

      when others => null;

    end case;
  end process;

  -----------------------------------------------------------------------------------
  -- Output stage
  -----------------------------------------------------------------------------------

  process(clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        clk_sel_o <= g_initial_value;
      else
        if (clk_sel_release = '1') then
          clk_sel_o <= clk_sel_staged;
        end if;
      end if;
    end if;
  end process;

end architecture;

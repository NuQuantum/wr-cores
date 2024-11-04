-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for Kasli SoC
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : xwrc_board_kasli.vhd
-- Author(s)  : Nu Quantum Ltd.
-- Company    : Nu Quantum Ltd.
-- Created    : 2024-10-30
-- Last update: 2024-10-30
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Manages the application of the clock switch signal during
--              system initialisation
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
  use ieee.math_real.all;

library work;
  use work.gencores_pkg.all;

entity xwrc_clock_switch_supervisor is
  generic (
    g_clock_frequency_hz : integer := 125000000;
    g_reset_duration_us  : integer := 50
  );
  port (
    -- The clock to run the FSM off
    clk_i   : in    std_logic;
    rst_n_i : in    std_logic;
    -- The asynchronous clock select input
    clk_sel_i : in    std_logic;
    clk_sel_o : out   std_logic;
    rst_n_o   : out   std_logic
  );
end entity xwrc_clock_switch_supervisor;

architecture rtl of xwrc_clock_switch_supervisor is

  signal clk_sel_changed    : std_logic;
  signal pll_reset_count_en : std_logic;

  constant c_reset_duration_s      : real    := real(g_reset_duration_us) * 1.0e-6;
  constant c_reset_duration_cycles : real    := c_reset_duration_s * real(g_clock_frequency_hz);
  constant c_reset_counter_bits    : integer := integer(
    ceil(log2(c_reset_duration_cycles))
  );

  signal pll_reset_count_q : unsigned(c_reset_counter_bits - 1 downto 0);

  type t_state is (ST_IDLE, ST_INITIAL_DELAY, ST_RESET, ST_DONE);

  signal pll_reset_state_q : t_state;
  signal pll_reset_state_d : t_state;

begin

  -- We do not assume a relationship between the input select signal and the FSM clock,
  -- therefore synchronise it
  u_gc_sync_ffs_sys_clk_select : component gc_sync_ffs
    generic map (
      g_sync_edge => "positive"
    )
    port map (
      clk_i    => clk_i,
      rst_n_i  => '1',
      data_i   => clk_sel_i,
      synced_o => open,
      npulse_o => open,
      ppulse_o => clk_sel_changed
    );

  -----------------------------------------------------------------------------------
  -- Counts the reset duration
  -----------------------------------------------------------------------------------

  process (clk_i) is
  begin
    if rising_edge(clk_i) then
      if (rst_n_i = '0') then
        pll_reset_count_q <= to_unsigned(
          (2 ** c_reset_counter_bits) - 1, c_reset_counter_bits
        );
      else
        if (pll_reset_count_en = '1') then
          pll_reset_count_q <= pll_reset_count_q - 1;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------------
  -- The FSM
  -----------------------------------------------------------------------------------

  process (clk_i) is
  begin
    if rising_edge(clk_i) then
      if (rst_n_i = '0') then
        pll_reset_state_q <= st_idle;
      else
        pll_reset_state_q <= pll_reset_state_d;
      end if;
    end if;
  end process;

  process (pll_reset_state_q, clk_sel_changed, pll_reset_count_q) is
  begin

    -- default values
    pll_reset_count_en <= '0';
    pll_reset_state_d  <= pll_reset_state_q;

    case pll_reset_state_q is

      when ST_IDLE =>
        if (clk_sel_changed = '1') then
          pll_reset_state_d <= ST_INITIAL_DELAY;
        end if;

      -- An initial delay to allow for the PL<->PS AXI bus to drain any
      -- outstanding transactions before we kill the clock by performing
      -- the switch
      when ST_INITIAL_DELAY =>
        pll_reset_count_en <= '1';
        if (pll_reset_count_q = to_unsigned(0, c_reset_counter_bits)) then
          pll_reset_state_d <= ST_RESET;
        end if;

      when ST_RESET =>
        if (pll_reset_count_q = to_unsigned(0, c_reset_counter_bits)) then
          pll_reset_state_d <= ST_DONE;
        else
          pll_reset_count_en <= '1';
        end if;

      when others => null;

    end case;
  end process;

  -----------------------------------------------------------------------------------
  -- Output stage
  -----------------------------------------------------------------------------------

  rst_n_o   <= '0' when pll_reset_state_q = ST_RESET else '1';
  clk_sel_o <= '1' when (pll_reset_count_q(c_reset_counter_bits-1) = '0'
                         and pll_reset_state_q /= ST_INITIAL_DELAY) else '0';

end architecture rtl;

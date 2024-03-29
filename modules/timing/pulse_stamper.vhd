-------------------------------------------------------------------------------
-- Entity: pulse_stamper
-- File: pulse_stamper.vhd
-- Description: a time-tagger which associates a time-tag with an asyncrhonous
-- input pulse.
-- Author: Javier Serrano (Javier.Serrano@cern.ch)
-- Date: 24 January 2012
-- Version: 0.02
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--               GNU LESSER GENERAL PUBLIC LICENSE
--              -----------------------------------
-- This source file is free software; you can redistribute it and/or modify it
-- under the terms of the GNU Lesser General Public License as published by the
-- Free Software Foundation; either version 2.1 of the License, or (at your
-- option) any later version.
-- This source is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
-- for more details. You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it from
-- http://www.gnu.org/licenses/lgpl-2.1.html
-------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;

entity pulse_stamper is

  generic (
    -- reference clock frequency
    g_ref_clk_rate : integer := 125000000);

  port(
    clk_ref_i : in std_logic;           -- timing reference clock
    clk_sys_i : in std_logic;           -- data output reference clock
    rst_n_i   : in std_logic;           -- system reset

    pulse_a_i : in std_logic;           -- pulses to be stamped

    -------------------------------------------------------------------------------
    -- Timing input (from WRPC), clk_ref_i domain
    ------------------------------------------------------------------------------

    -- 1: time given on tm_utc_i and tm_cycles_i is valid (otherwise, don't timestamp)
    tm_time_valid_i : in std_logic;
    -- number of seconds
    tm_tai_i        : in std_logic_vector(39 downto 0);
    -- number of clk_ref_i cycles
    tm_cycles_i     : in std_logic_vector(27 downto 0);


    ---------------------------------------------------------------------------
    -- Time tag output (clk_sys_i domain)
    ---------------------------------------------------------------------------
    tag_tai_o      : out std_logic_vector(39 downto 0);
    tag_cycles_o   : out std_logic_vector(27 downto 0);
    -- single-cycle pulse: strobe tag on tag_utc_o and tag_cycles_o
    tag_valid_o : out std_logic
    );


end pulse_stamper;

architecture rtl of pulse_stamper is

 -- Signals for input anti-metastability ffs
 signal pulse_ref : std_logic_vector(2 downto 0);
 signal pulse_ref_p1 : std_logic;
 signal pulse_ref_p1_d1 : std_logic;

 -- Time tagger signals
 signal tag_utc_ref : std_logic_vector(39 downto 0);
 signal tag_cycles_ref : std_logic_vector(27 downto 0);

 -- Signals for synchronizer
 signal pulse_sys_p1 : std_logic;

 -- One of two clocks is used in WR for timestamping: 125MHz or 62.5MHz
 -- This functions translates the cycle count into 125MHz-clock cycles
 -- in the case when 62.5MHz clock is used. As a result, timestamps are
 -- always in the same "clock domain". This is important, e.g. for streamers,
 -- in applicatinos where one WR Node works with 62.5MHz WR clock and
 -- another in 125MHz.
 function f_8ns_cycle_cnt (in_cyc: std_logic_vector; ref_clk: integer)
    return std_logic_vector is
    variable out_cyc : std_logic_vector(27 downto 0);
  begin

    if (ref_clk = 125000000) then
      out_cyc := in_cyc;
    elsif(ref_clk = 62500000) then
      out_cyc := in_cyc(26 downto 0) & '0';
    else
      assert FALSE report
      "The only ref_clk_rate supported: 62.5MHz and 125MHz"
      severity FAILURE;
    end if;

    return out_cyc;

  end f_8ns_cycle_cnt;

begin  -- architecture rtl

 -- Synchronization of external pulse into the clk_ref_i clock domain
 inst_edge_detect : entity work.gc_sync_ffs
   generic map (
     g_SYNC_EDGE => "positive")
   port map (
     clk_i    => clk_ref_i,
     rst_n_i  => rst_n_i,
     data_i   => pulse_a_i,
     ppulse_o => pulse_ref_p1);

 -- Time tagging of the pulse, still in the clk_ref_i domain
 p_tagger: process (clk_ref_i)
 begin
  if clk_ref_i'event and clk_ref_i='1' then
    if pulse_ref_p1='1' and tm_time_valid_i='1' then
      tag_utc_ref <= tm_tai_i;
      tag_cycles_ref <= tm_cycles_i;
    end if;
  end if;
 end process;

 -- Synchronizer to pass UTC register data to the system clock domain
 -- This synchronizer is made with the following three processes

 inst_pulse_sync : entity work.gc_pulse_synchronizer
   port map (
     rst_n_i     => rst_n_i,
     clk_in_i    => clk_ref_i,
     clk_out_i   => clk_sys_i,
     d_ready_o   => open,
     d_p_i       => pulse_ref_p1,
     q_p_o       => pulse_sys_p1);


 -- Now we can take the time tags into the clk_sys_i domain
 sys_tags: process (clk_sys_i)
 begin
  if clk_sys_i'event and clk_sys_i='1' then
    if rst_n_i='0' then
     tag_tai_o <= (others=>'0');
     tag_cycles_o <= (others=>'0');
     tag_valid_o <= '0';
    elsif pulse_sys_p1='1' then
     tag_tai_o <= tag_utc_ref;
     tag_cycles_o <= f_8ns_cycle_cnt(tag_cycles_ref,g_ref_clk_rate);
     tag_valid_o <= '1';
    else
     tag_valid_o <='0';
    end if;
  end if;
 end process sys_tags;

end architecture rtl;

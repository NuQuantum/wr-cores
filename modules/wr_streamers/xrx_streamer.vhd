-------------------------------------------------------------------------------
-- Title      : Transmission Streamer
-- Project    : WR Streamers
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/WR_Streamers
-------------------------------------------------------------------------------
-- File       : xrx_streamer.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-CO-HT
-- Created    : 2012-11-02
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description: A simple core demonstrating how to encapsulate a continuous
-- stream of data words into Ethernet frames, in a format that is accepted by
-- the White Rabbit PTP core. This core decodes Ethernet frames encoded by
-- xtx_streamer. More info in the documentation.
-------------------------------------------------------------------------------
-- Copyright (c) 2012-2017 CERN/BE-CO-HT
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
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.gencores_pkg.all;
use work.genram_pkg.all;
use work.streamers_priv_pkg.all;
use work.streamers_pkg.all;

entity xrx_streamer is
  
  generic (
    -- Width of the data words, must be multiple of 16 bits. This value set to this generic
    -- on the receviving device must be the same as the value of g_tx_data_width set on the
    -- transmitting node. The g_rx_data_width and g_tx_data_width can be set to different
    -- values in the same device (i.e. instantiation of xwr_transmission entity). It is the
    -- responsibility of a network designer to make sure these parameters are properly set 
    -- in the network.
    g_data_width        : integer := 32;

    -- Size of RX buffer, in data words.
    g_buffer_size       : integer := 256;

    -- DO NOT USE unless you know what you are doing
    -- legacy: the streamers that were initially used in Btrain did not check/insert 
    -- the escape code. This is justified if only one block of a known number of words is 
    -- sent/expected.
    g_escape_code_disable : boolean := FALSE;

    -- DO NOT USE unless you know what you are doing
    -- legacy: the streamers that were initially used in Btrain accepted only a fixed
    -- number of words, regardless of the frame content. If this generic is set to number
    -- other than zero, only a fixed number of words is accepted. 
    -- In combination with the g_escape_code_disable generic set to TRUE, the behaviour of
    -- the "Btrain streamers" can be recreated.
    g_expected_words_number : integer := 0;

    -- rate fo the White Rabbit referene clock. By default, this clock is
    -- 125MHz for WR Nodes. There are some WR Nodes that work with 62.5MHz.
    -- in the future, more frequences might be supported..
    g_clk_ref_rate : integer := 125000000;

    -- indicate that we are simulating so that some processes can be made to take less 
    -- time, e.g. below
    g_simulation : integer := 0;

    -- shorten the duration of second to see TAI seconds for simulation only (i.e.
    -- only if g_simulation = 1)
    g_sim_cycle_counter_range : integer := 125000000;

    -- when non-zero, the datapath (tx_/rx_ ports) are in the clk_ref_i clock
    -- domain instead of clk_sys_i. This is a must for fixed latency mode if
    -- clk_sys_i is asynchronous (i.e. not locked) to the WR timing.
    g_use_ref_clock_for_data : integer := 0
    );

  port (
    clk_sys_i : in std_logic;
    -- White Rabbit reference clock
    clk_ref_i : in std_logic := '0';
    rst_n_i   : in std_logic;

    -- Endpoint/WRC interface 
    snk_i : in  t_wrf_sink_in;
    snk_o : out t_wrf_sink_out;

    ---------------------------------------------------------------------------
    -- WRC Timing interface, used for latency measurement
    -- Caution: uses clk_ref_i clock domain!
    ---------------------------------------------------------------------------

    -- Time valid flag
    tm_time_valid_i : in std_logic := '0';

    -- TAI seconds
    tm_tai_i : in std_logic_vector(39 downto 0) := x"0000000000";

    -- Fractional part of the second (in clk_ref_i cycles)
    tm_cycles_i : in std_logic_vector(27 downto 0) := x"0000000";

    ---------------------------------------------------------------------------
    -- User interface
    ---------------------------------------------------------------------------

    -- 1 indicates the 1st word of the data block on rx_data_o.
    rx_first_p1_o         : out std_logic;
    -- 1 indicates the last word of the data block on rx_data_o.
    rx_last_p1_o          : out std_logic;
    -- Received data.
    rx_data_o          : out std_logic_vector(g_data_width-1 downto 0);
    -- 1 indicted that rx_data_o is outputting a valid data word.
    rx_valid_o         : out std_logic;
    -- 1 indicates the frame has been reproduced later than its desired fixed latency
    rx_late_o : out std_logic;
    -- 1 indicates the frame has been reproduced earlier than its desired fixed
    -- latency due to the RX latency timeout
    rx_timeout_o : out std_logic;

    -- Synchronous data request input: when 1, the streamer may output another
    -- data word in the subsequent clock cycle.
    rx_dreq_i          : in  std_logic;
    -- Lost output: 1 indicates that one or more frames or blocks have been lost
    -- (left for backward compatibility).
    rx_lost_p1_o          : out std_logic := '0';
    -- indicates that one or more blocks within frame are missing
    rx_lost_blocks_p1_o    :  out std_logic := '0';
    -- indicates that one or more frames are missing, the number of frames is provied
    rx_lost_frames_p1_o    :  out std_logic := '0';
    --number of lost frames, the 0xF...F means that counter overflew
    rx_lost_frames_cnt_o : out std_logic_vector(14 downto 0);
    -- Latency measurement output: indicates the transport latency (between the
    -- TX streamer in remote device and this streamer), in clk_ref_i clock cycles.
    rx_latency_o       : out std_logic_vector(27 downto 0);
    -- 1 when the latency on rx_latency_o is valid.
    rx_latency_valid_o : out std_logic;
    -- pulse when a frame was dropped due to buffer overflow
    rx_stat_overflow_p1_o     : out std_logic;
    rx_stat_match_p1_o   : out std_logic;
    rx_stat_late_p1_o    : out std_logic;
    rx_stat_timeout_p1_o : out std_logic;
    -- received 	streamer frame (counts all frames, corrupted and not)
    rx_frame_p1_o         : out std_logic;
    -- configuration
    rx_streamer_cfg_i     : in t_rx_streamer_cfg := c_rx_streamer_cfg_default
    );

end xrx_streamer;

architecture rtl of xrx_streamer is

  type t_rx_state is (IDLE, HEADER, FRAME_SEQ_ID, PAYLOAD, EOF, DROP_FRAME);

  signal fab, fsm_in : t_pipe;

  signal state : t_rx_state;

  signal ser_count : unsigned(7 downto 0);
  signal seq_no, seq_new,count  : unsigned(14 downto 0);

  signal crc_match, crc_en, crc_en_masked, crc_restart : std_logic;

  signal detect_escapes, is_escape : std_logic;
  signal rx_pending                : std_logic;

  signal pack_data, fifo_data : std_logic_vector(g_data_width-1 downto 0);

  signal fifo_drop, fifo_accept, fifo_accept_d0, fifo_dvalid, fifo_full, fifo_dreq : std_logic;
  signal fifo_sync, fifo_last, frames_lost, blocks_lost      : std_logic;
  signal fifo_dout, fifo_din                                 : std_logic_vector(g_data_width + 1 + 28 + 1 downto 0);

  --attribute mark_debug                : string;
  --attribute mark_debug of fifo_drop   : signal is "true";
  --attribute mark_debug of fifo_accept : signal is "true";
  --attribute mark_debug of fifo_dvalid : signal is "true";
  --attribute mark_debug of state       : signal is "true";
  --attribute mark_debug of fsm_in      : signal is "true";
  --attribute mark_debug of fifo_full   : signal is "true";
  --attribute mark_debug of fifo_dreq   : signal is "true";

  signal fifo_target_ts_en : std_logic;
  signal fifo_target_ts    : std_logic_vector(28 downto 0);

  signal pending_write, fab_dvalid_pre : std_logic;


  signal tx_tag_cycles, rx_tag_cycles : std_logic_vector(27 downto 0);
  signal tx_tag_valid, tx_tag_present, rx_tag_valid : std_logic;
  signal rx_tag_valid_stored          : std_logic;

  signal got_next_subframe : std_logic;
  signal is_frame_seq_id : std_logic;
  signal word_count                                                        : unsigned(11 downto 0);
  signal sync_seq_no : std_logic;

  signal rx_latency         : unsigned(27 downto 0);
  signal rx_latency_stored  : unsigned(27 downto 0);
  signal rx_latency_valid   : std_logic;
  signal is_vlan            : std_logic;

  signal fifo_last_int : std_logic;

  signal rst_int_n : std_logic;

  signal tx_tag_error : std_logic;


  signal tx_tag_adj_valid  : std_logic;
  signal tx_tag_adj_error  : std_logic;
  signal tx_tag_adj_cycles : std_logic_vector(27 downto 0);
  signal tx_tag_adj_tai    : std_logic_vector(39 downto 0);

  signal fifo_target_ts_tai    : std_logic_vector(39 downto 0);
  signal fifo_target_ts_cycles : std_logic_vector(27 downto 0);
  signal fifo_target_ts_error  : std_logic;
  signal timestamp_pushed_to_fifo : std_logic;

  
begin  -- rtl

  p_software_reset : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        rst_int_n <= '0';
      else
        rst_int_n <= not rx_streamer_cfg_i.sw_reset;
      end if;
    end if;
  end process;

  U_rx_crc_generator : gc_crc_gen
    generic map (
      g_polynomial              => x"1021",
      g_init_value              => x"ffff",
      g_residue                 => x"470f",
      g_data_width              => 16,
      g_sync_reset              => 1,
      g_dual_width              => 0,
      g_registered_match_output => true)
    port map (
      clk_i     => clk_sys_i,
      rst_i     => '0',
      restart_i => crc_restart,
      en_i      => crc_en_masked,
      data_i    => fsm_in.data,
      half_i    => '0',
      match_o   => crc_match);

  crc_en_masked <= crc_en and fsm_in.dvalid;

  U_Fabric_Sink : xwb_fabric_sink
    port map (
      clk_i     => clk_sys_i,
      rst_n_i   => rst_int_n,
      snk_i     => snk_i,
      snk_o     => snk_o,
      addr_o    => fab.addr,
      data_o    => fab.data,
      dvalid_o  => fab_dvalid_pre,
      sof_o     => fab.sof,
      eof_o     => fab.eof,
      error_o   => fab.error,
      bytesel_o => fab.bytesel,
      dreq_i    => fab.dreq);

  fab.dvalid <= '1' when fab_dvalid_pre = '1' and fab.addr = c_WRF_DATA and fab.bytesel = '0' else '0';
  gen_escape: if (g_escape_code_disable = FALSE) generate
    U_Escape_Detect : escape_detector
      generic map (
        g_data_width  => 16,
        g_escape_code => x"cafe")
      port map (
        clk_i             => clk_sys_i,
        rst_n_i           => rst_int_n,
        d_i               => fab.data,
        d_detect_enable_i => detect_escapes,
        d_valid_i         => fab.dvalid,
        d_req_o           => fab.dreq,
        d_o               => fsm_in.data,
        d_escape_o        => is_escape,
        d_valid_o         => fsm_in.dvalid,
        d_req_i           => fsm_in.dreq);
  end generate gen_escape;
  gen_no_escape: if (g_escape_code_disable = TRUE) generate
    fsm_in.dvalid <= fab.dvalid;
    fsm_in.data   <= fab.data;
    fab.dreq      <= fsm_in.dreq;
    is_escape     <= '0';
  end generate gen_no_escape;

  fsm_in.eof <= fab.eof or fab.error;
  fsm_in.sof <= fab.sof;

  U_RX_Timestamper : pulse_stamper
    generic map(
      g_ref_clk_rate => g_clk_ref_rate)
    port map (
      clk_ref_i       => clk_ref_i,
      clk_sys_i       => clk_sys_i,
      rst_n_i         => rst_int_n,
      pulse_a_i       => fsm_in.sof,
      tm_time_valid_i => tm_time_valid_i,
      tm_tai_i        => tm_tai_i,
      tm_cycles_i     => tm_cycles_i,
      tag_cycles_o    => rx_tag_cycles,
      tag_valid_o     => rx_tag_valid);

  fifo_last_int <= fifo_last or ((not pending_write) and is_escape);  -- when word is 16 bit

  U_FixLatencyDelay : entity work.fixed_latency_delay
    generic map (
      g_data_width             => g_data_width,
      g_buffer_size            => 32,
      g_use_ref_clock_for_data => g_use_ref_clock_for_data,
      g_clk_ref_rate => g_clk_ref_rate,
      g_sim_cycle_counter_range => g_sim_cycle_counter_range,
      g_simulation => g_simulation)
    port map (
      rst_n_i          => rst_int_n,
      clk_sys_i        => clk_sys_i,
      clk_ref_i        => clk_ref_i,
      tm_time_valid_i  => tm_time_valid_i,
      tm_tai_i => tm_tai_i,
      tm_cycles_i      => tm_cycles_i,
      d_data_i         => fifo_data,
      d_last_i         => fifo_last_int,
      d_sync_i         => fifo_sync,
      d_target_ts_en_i => fifo_target_ts_en,
      d_target_ts_tai_i    => fifo_target_ts_tai,
      d_target_ts_cycles_i => fifo_target_ts_cycles,
      d_target_ts_error_i  => fifo_target_ts_error,
      d_valid_i        => fifo_dvalid,
      d_drop_i         => fifo_drop,
      d_accept_i       => fifo_accept_d0,
      d_req_o              => fifo_dreq,
      d_full_o             => fifo_full,
      rx_first_p1_o    => rx_first_p1_o,
      rx_last_p1_o     => rx_last_p1_o,
      rx_data_o        => rx_data_o,
      rx_valid_o       => rx_valid_o,
      rx_dreq_i        => rx_dreq_i,
      rx_late_o => rx_late_o,
      rx_timeout_o => rx_timeout_o,
      stat_match_p1_o   => rx_stat_match_p1_o,
      stat_late_p1_o    => rx_stat_late_p1_o,
      stat_timeout_p1_o => rx_stat_timeout_p1_o,
      rx_streamer_cfg_i => rx_streamer_cfg_i);


  U_RestoreTAITimeFromRXTimestamp : entity work.ts_restore_tai
    generic map (
      g_tm_sample_period        => 30,
      g_clk_ref_rate            => g_clk_ref_rate,
      g_simulation              => g_simulation,
      g_sim_cycle_counter_range => g_sim_cycle_counter_range)
    port map (
      clk_sys_i       => clk_sys_i,
      clk_ref_i       => clk_ref_i,
      rst_n_i         => rst_n_i,
      tm_time_valid_i => tm_time_valid_i,
      tm_tai_i        => tm_tai_i,
      tm_cycles_i     => tm_cycles_i,
      ts_valid_i      => tx_tag_valid,
      ts_cycles_i     => tx_tag_cycles,
      ts_valid_o      => tx_tag_adj_valid,
      ts_cycles_o     => tx_tag_adj_cycles,
      ts_error_o      => tx_tag_adj_error,
      ts_tai_o        => tx_tag_adj_tai);

  p_gen_fsm_dreq : process(fifo_full, state)
  begin
    if state = PAYLOAD then
      fsm_in.dreq <= not fifo_full;
    else
      fsm_in.dreq <= '1';
    end if;
  end process;


  p_fsm : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_int_n = '0' then
        state                  <= IDLE;
        count                  <= (others => '0');
        seq_no                 <= (others => '1');
        detect_escapes         <= '0';
        crc_en                 <= '0';
        fifo_accept            <= '0';
        fifo_drop              <= '0';
        fifo_dvalid            <= '0';
        pending_write          <= '0';
        got_next_subframe      <= '0';
        fifo_sync              <= '0';
        fifo_last              <= '0';
        tx_tag_valid           <= '0';
        ser_count              <= (others => '0');
        word_count             <= (others => '0');
        sync_seq_no            <= '1';
        rx_frame_p1_o          <= '0';
        rx_lost_frames_cnt_o   <= (others => '0');
        frames_lost            <= '0';
        blocks_lost            <= '0';
        pack_data              <= (others=>'0');
        is_vlan                <= '0';
        tx_tag_present       <= '0';
        tx_tag_valid         <= '0';
      else
        case state is
          when IDLE =>
            detect_escapes     <= '0';
            crc_en             <= '0';
            count              <= (others => '0');
            fifo_accept        <= '0';
            fifo_drop          <= '0';
            fifo_dvalid        <= '0';
            pending_write      <= '0';
            got_next_subframe  <='0';
            ser_count          <= (others => '0');
            fifo_sync          <='0';
            fifo_last          <= '0';
            word_count         <= (others => '0');
            tx_tag_valid       <= '0';
            rx_frame_p1_o      <= '0';
            rx_lost_frames_cnt_o <= (others => '0');
            frames_lost          <= '0';
            blocks_lost          <= '0';
            is_vlan              <= '0';
            tx_tag_present       <= '0';
            tx_tag_valid         <= '0';

            if(fsm_in.sof = '1') then

              if(fifo_full = '1') then
                state <= DROP_FRAME;
              else
                state <=  HEADER;
              end if;
            end if;

          when DROP_FRAME =>
            if (fsm_in.eof = '1' or fsm_in.error = '1') then
              state <= IDLE;
            end if;


          when HEADER =>
            if(fsm_in.eof = '1') then
              state <= IDLE;
            elsif(fsm_in.dvalid = '1') then
              case count(7 downto 0) is
                when x"00" =>
                  if(fsm_in.data /= rx_streamer_cfg_i.mac_local(47 downto 32) nor (rx_streamer_cfg_i.accept_broadcasts = '1' and fsm_in.data /= x"ffff")) then
                    state <= IDLE;
                  end if;
                  count <= count + 1;
                when x"01" =>
                  if(fsm_in.data /= rx_streamer_cfg_i.mac_local(31 downto 16) nor (rx_streamer_cfg_i.accept_broadcasts = '1' and fsm_in.data /= x"ffff")) then
                    state <= IDLE;
                  end if;
                  count <= count + 1;
                when x"02" =>
                  if(fsm_in.data /= rx_streamer_cfg_i.mac_local(15 downto 0) nor (rx_streamer_cfg_i.accept_broadcasts = '1' and fsm_in.data /= x"ffff")) then
                    state <= IDLE;
                  end if;
                  count <= count + 1;
                when x"03" =>
                  if(fsm_in.data /= rx_streamer_cfg_i.mac_remote(47 downto 32) and rx_streamer_cfg_i.filter_remote ='1') then
                    state <= IDLE;
                  end if;
                  count <= count + 1;
                when x"04" =>
                  if(fsm_in.data /= rx_streamer_cfg_i.mac_remote(31 downto 16) and rx_streamer_cfg_i.filter_remote ='1') then
                    state <= IDLE;
                  end if;
                  count <= count + 1;
                when x"05" =>
                  if(fsm_in.data /= rx_streamer_cfg_i.mac_remote(15 downto 0) and rx_streamer_cfg_i.filter_remote ='1') then
                    state <= IDLE;
                  end if;
                  count <= count + 1;
                when x"06" =>
                  if(fsm_in.data = x"8100") then
                    is_vlan <='1';
                  elsif(fsm_in.data /= rx_streamer_cfg_i.ethertype) then
                    state   <= IDLE;
                    is_vlan <='0';
                  end if;
                  count <= count + 1;
                when x"07" =>
                  if(is_vlan = '0') then
                    tx_tag_present              <= fsm_in.data(15);
                    tx_tag_error                <= fsm_in.data(14);
                    tx_tag_cycles(27 downto 16) <= fsm_in.data(11 downto 0);
                  end if;
                  count <= count + 1;
                when x"08" =>
                  if(is_vlan = '0') then
                    tx_tag_valid               <= '1';
                    tx_tag_cycles(15 downto 0) <= fsm_in.data;
                    count                      <= count + 1;
                    crc_en                     <= '1';
                    detect_escapes             <= '1';
                    state                      <= FRAME_SEQ_ID;
                    rx_frame_p1_o              <= '1';
                  elsif(fsm_in.data /= rx_streamer_cfg_i.ethertype) then
                    state <= IDLE;
                  end if;
                  count <= count + 1;
                when x"09" =>
                  tx_tag_present              <= fsm_in.data(15);
                  tx_tag_error                <= fsm_in.data(14);
                  tx_tag_cycles(27 downto 16) <= fsm_in.data(11 downto 0);
                   count <= count + 1;
                when x"0A" =>
                  tx_tag_valid               <= '1';
                  tx_tag_cycles(15 downto 0) <= fsm_in.data;
                  count                      <= count + 1;
                  crc_en                     <= '1';
                  detect_escapes             <= '1';
                  state                      <= FRAME_SEQ_ID;
                  rx_frame_p1_o              <= '1';
                  count <= count + 1;
                when others => null;
              end case;
            end if;

          when FRAME_SEQ_ID =>
            rx_frame_p1_o            <= '0';
            if(fsm_in.eof = '1') then
              state <= IDLE;
            elsif(fsm_in.dvalid = '1') then
              count               <= "000" & x"001"; -- use as subframe seq_no
              state               <= PAYLOAD;
              fifo_drop           <= '0';
              fifo_accept         <= '0';
              ser_count           <= (others => '0');
              word_count          <= word_count + 1; -- count words, increment in advance
              got_next_subframe   <= '1';

              if(std_logic_vector(seq_no) /= fsm_in.data(14 downto 0)) then
                seq_no    <= unsigned(fsm_in.data(14 downto 0))+1;
                if (sync_seq_no = '1') then -- sync to the first received seq_no
                  sync_seq_no <= '0';
                  frames_lost   <= '0';
                  rx_lost_frames_cnt_o <= (others => '0');
                else
                  rx_lost_frames_cnt_o <= std_logic_vector(unsigned(fsm_in.data(14 downto 0)) - seq_no);
                  frames_lost     <= '1';
                end if;
              else
                seq_no    <= unsigned(seq_no + 1);
                frames_lost <= '0';
                rx_lost_frames_cnt_o <= (others => '0');
              end if;
            end if;



          when PAYLOAD =>
            frames_lost <= '0';
            rx_lost_frames_cnt_o <= (others => '0');
            fifo_sync <= got_next_subframe;

            if(fsm_in.eof = '1') then
              state       <= IDLE;
              fifo_drop   <= '1';
              fifo_accept <= '0';
              got_next_subframe <= '0';
              
            elsif(fsm_in.dvalid = '1') then

              
              
              if(is_escape = '1') then
                ser_count <= (others => '0');
                fifo_last <= '1';

                got_next_subframe <= '1';

                if(fsm_in.data(15) = '1') then
                  
                  if(std_logic_vector(count) /= fsm_in.data(14 downto 0)) then
                    count     <= unsigned(fsm_in.data(14 downto 0));
                    blocks_lost <= '1';
                  else
                    count     <= unsigned(count + 1);
                    blocks_lost <= '0';
                  end if;
                  
                  state <= PAYLOAD;

                  fifo_accept   <= crc_match;      --_latched;
                  fifo_drop     <= not crc_match;  --_latched;
                  fifo_dvalid   <= pending_write and not fifo_dvalid;
                  pending_write <= '0';
                  
                elsif fsm_in.data = x"0bad" then
                  blocks_lost   <= '0';
                  state       <= EOF;
                  fifo_accept <= crc_match;      --_latched;
                  fifo_drop   <= not crc_match;  --_latched;


                  fifo_dvalid <= pending_write and not fifo_dvalid;
                else
                  blocks_lost   <= '0';
                  state       <= EOF;
                  fifo_drop   <= '1';
                  fifo_accept <= '0';
                end if;

              else --of:  if(is_escape = '1' or word_count = g_expected_words_number) then

                fifo_last   <= '0';
                fifo_accept <= '0';
                fifo_drop   <= '0';
                blocks_lost   <= '0';

                pack_data(to_integer(ser_count) * 16 + 15 downto to_integer(ser_count) * 16) <= fsm_in.data;

                if(ser_count = g_data_width/16 - 1) then
                  ser_count                                        <= (others => '0');

                  if (ser_count = x"00") then -- ML: the case when g_data_width == 16
                     fifo_sync <= got_next_subframe;
                     fifo_data(g_data_width-1 downto 0)            <= pack_data(g_data_width-1 downto 0);
                     fifo_dvalid <= not is_escape;
                     pending_write <= '0';
                  else
                    ser_count                                        <= (others => '0');
                    fifo_data(g_data_width-16-1 downto 0)            <= pack_data(g_data_width-16-1 downto 0);
                    fifo_data(g_data_width-1 downto g_data_width-16) <= fsm_in.data;
                    fifo_dvalid                                      <= '0';
                    pending_write                                    <= '1';
                  end if;
                  if(word_count = g_expected_words_number) then
                    state       <= EOF;
                    fifo_accept <= '1'; 
                    fifo_drop   <= '0'; 
                    fifo_dvalid <= '1';

                  else
                    word_count <= word_count + 1;
                  end if;
                elsif(ser_count = g_data_width/16-2 and pending_write = '1') then
                  pending_write <= '0';
                  ser_count     <= ser_count + 1;
                  fifo_dvalid   <= '1';
                  fifo_sync <= got_next_subframe;
                  got_next_subframe <= '0';
                else
                  ser_count   <= ser_count + 1;
                  fifo_dvalid <= '0';
                end if;
                
              end if;
            else --of:  elsif(fsm_in.dvalid = '1') then
              fifo_dvalid <= '0';
            end if;

            if(fifo_dvalid = '1') then
              fifo_sync <= '0';
            end if;
            

          when EOF =>
            fifo_dvalid <= '0';
            fifo_drop   <= '0';
            fifo_accept <= '0';
            state       <= IDLE;
            
        end case;
      end if;
    end if;
  end process;



  p_handle_latency : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_int_n = '0' then
        fifo_target_ts_en        <= '0';
        rx_latency_valid         <= '0';
        rx_tag_valid_stored      <= '0';
        timestamp_pushed_to_fifo <= '0';
        rx_latency               <= (others => '0');
      else

        case state is
          when IDLE =>
            timestamp_pushed_to_fifo <= '0';
            rx_tag_valid_stored      <= '0';-- prepare for next timestamp
            fifo_target_ts_en        <= '0';
          when HEADER =>

            -- remember that we got timestamp, it can happen only when receiving header
            if(rx_tag_valid = '1') then
               rx_tag_valid_stored   <= '1';
            end if;

          when PAYLOAD =>

            if(timestamp_pushed_to_fifo = '0' and tx_tag_adj_valid = '1' and tx_tag_present = '1' and unsigned(rx_streamer_cfg_i.fixed_latency) /= 0) then
              fifo_target_ts_cycles <= tx_tag_adj_cycles;
              fifo_target_ts_tai    <= tx_tag_adj_tai;
              fifo_target_ts_error  <= tx_tag_adj_error or tx_tag_error;
              fifo_target_ts_en     <= '1';
            end if;

            if fifo_dvalid = '1' and fifo_target_ts_en = '1' then
              timestamp_pushed_to_fifo <= '1';
            end if;

            -- latency measurement
            if(tx_tag_present = '1' and rx_tag_valid_stored = '1') then
              rx_latency_valid <= '1';
              rx_tag_valid_stored <= '0';
              if(unsigned(tx_tag_cycles) > unsigned(rx_tag_cycles)) then
                rx_latency <= unsigned(rx_tag_cycles) - unsigned(tx_tag_cycles) + to_unsigned(125000000, 28);
              else
                rx_latency <= unsigned(rx_tag_cycles) - unsigned(tx_tag_cycles);
              end if;
            else
              rx_latency_valid <= '0';
            end if;

          when others => null;
        end case;
      end if;
    end if;
  end process;




  p_delay_signals : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      fifo_accept_d0 <= fifo_accept;
    end if;
  end process;

  rx_lost_p1_o        <= frames_lost or blocks_lost;
  rx_lost_blocks_p1_o <= blocks_lost;
  rx_lost_frames_p1_o <= frames_lost;
  rx_latency_o        <= std_logic_vector(rx_latency);
  rx_latency_valid_o  <= rx_latency_valid;
  crc_restart <= '1' when (state = FRAME_SEQ_ID or (is_escape = '1' and fsm_in.data(15) = '1')) else not rst_int_n;

end rtl;

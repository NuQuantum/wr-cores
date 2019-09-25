-------------------------------------------------------------------------------
-- Title      : Deterministic Xilinx GTX wrapper - kintex-7 top module
-- Project    : White Rabbit Switch
-------------------------------------------------------------------------------
-- File       : wr_gtx_phy_family7.vhd
-- Author     : Peter Jansweijer, Tomasz Wlostowski
-- Company    : CERN BE-CO-HT
-- Created    : 2013-04-08
-- Last update: 2019-07-01
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Dual channel wrapper for Xilinx Kintex-7 GTX adapted for
-- deterministic delays at 1.25 Gbps.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2010 CERN
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
--
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2013-04-08  0.1      PeterJ    Initial release based on "wr_gtx_phy_virtex6.vhd"
-- 2013-08-19  0.2      PeterJ    Implemented a small delay before a rx_cdr_lock is propgated
-- 2014-02_19  0.3      Peterj    Added tx_locked_o to indicate that the cpll reached the lock status
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.gencores_pkg.all;
use work.disparity_gen_pkg.all;

entity wr_gtx_phy_kintex7_lp is

  generic (
    -- set to non-zero value to speed up the simulation by reducing some delays
    g_simulation         : integer := 0;
    g_id : integer := 0
    );

  port (

    -- Dedicated reference 125 MHz clock for the GTX transceiver
    qpll_clk_i : in std_logic;
    qpll_ref_clk_i : in std_logic;
    qpll_locked_i : in std_logic;
    qpll_reset_o : out std_logic;

    -- DMTD clock for phase measurements (done in the PHY module as we need to
    -- multiplex between several GTX clock outputs)
    clk_dmtd_i : in std_logic;

    -- Reference 125 MHz clock input for the TX/RX deterministic phase logic (not the GTX itself)
    clk_ref_i : in std_logic;
    
    -- TX path, synchronous to tx_clk_o (125 MHz):
    tx_clk_o : out std_logic;
    tx_locked_o  : out std_logic;

    -- data input (8 bits, not 8b10b-encoded)
    tx_data_i : in std_logic_vector(15 downto 0);

    -- 1 when tx_data_i contains a control code, 0 when it's a data byte
    tx_k_i : in std_logic_vector(1 downto 0);

    -- disparity of the currently transmitted 8b10b code (1 = plus, 0 = minus).
    -- Necessary for the PCS to generate proper frame termination sequences.
    -- Generated for the 2nd byte (LSB) of tx_data_i.
    tx_disparity_o : out std_logic;

    -- Encoding error indication (1 = error, 0 = no error)
    tx_enc_err_o : out std_logic;

    -- RX path, synchronous to ch0_rx_rbclk_o.

    -- RX recovered clock
    rx_rbclk_o : out std_logic;

    -- 8b10b-decoded data output. The data output must be kept invalid before
    -- the transceiver is locked on the incoming signal to prevent the EP from
    -- detecting a false carrier.
    rx_data_o : out std_logic_vector(15 downto 0);

    -- 1 when the byte on rx_data_o is a control code
    rx_k_o : out std_logic_vector(1 downto 0);

    -- encoding error indication
    rx_enc_err_o : out std_logic;

    -- RX bitslide indication, indicating the delay of the RX path of the
    -- transceiver (in UIs). Must be valid when ch0_rx_data_o is valid.
    rx_bitslide_o : out std_logic_vector(4 downto 0);

    -- reset input, active hi
    rst_i         : in std_logic;
    loopen_i      : in std_logic;
    tx_prbs_sel_i : in std_logic_vector(2 downto 0);
    pad_txn_o : out std_logic;
    pad_txp_o : out std_logic;

    pad_rxn_i : in std_logic := '0';
    pad_rxp_i : in std_logic := '0';

    rdy_o     : out std_logic;

    debug_i : in  std_logic_vector(15 downto 0) := x"0000";
    debug_o : out std_logic_vector(15 downto 0);
    rx_rbclk_sampled_o : out std_logic;

    fmon_clk_tx_o : out std_logic;
    fmon_clk_tx2_o : out std_logic;
    fmon_clk_rx_o : out std_logic

    );
end wr_gtx_phy_kintex7_lp;

architecture rtl of wr_gtx_phy_kintex7_lp is

  component dmtd_sampler is
    generic (
      g_divide_input_by_2 : boolean;
      g_reverse           : boolean);
    port (
      clk_in_i      : in  std_logic;
      clk_dmtd_i    : in  std_logic;
      clk_sampled_o : out std_logic);
  end component dmtd_sampler;
  
  component BUFG
    port (
      O : out std_ulogic;
      I : in  std_ulogic);
  end component;

  component gc_dec_8b10b is
    port (
      clk_i       : in  std_logic;
      rst_n_i     : in  std_logic;
      in_10b_i    : in  std_logic_vector(9 downto 0);
      ctrl_o      : out std_logic;
      code_err_o  : out std_logic;
      rdisp_err_o : out std_logic;
      out_8b_o    : out std_logic_vector(7 downto 0));
  end component gc_dec_8b10b;
  
  constant c_rxcdrlock_max            : integer := 1000;
  constant c_reset_cnt_max            : integer := 64;	-- Reset pulse width 64 * 8 = 512 ns
  
  signal rst_synced                   : std_logic;
  signal gtx_rst, gtx_rst_n                      : std_logic;
  signal rst_d0                     : std_logic;
  signal reset_counter              : unsigned(9 downto 0);

  signal rx_rec_clk_bufin             : std_logic;
  signal rx_rec_clk                   : std_logic;
  signal tx_out_clk_bufin             : std_logic;
  signal tx_out_clk                   : std_logic;
  signal rx_cdr_lock                  : std_logic;
  signal rx_cdr_lock_filtered         : std_logic;

  signal tx_rst_done, rx_rst_done     : std_logic;
  signal txpll_lockdet, rxpll_lockdet : std_logic;
--  signal pll_lockdet                  : std_logic;
--  signal cpll_lockdet                 : std_logic;

  signal everything_ready             : std_logic;
  signal rst_done                     : std_logic;
  signal rst_done_n                   : std_logic;
 
  signal rx_k_o_int    : std_logic_vector(1 downto 0);
  signal rx_data_o_int : std_logic_vector(15 downto 0);
  signal rx_k_int    : std_logic_vector(1 downto 0);
  signal rx_data_int : std_logic_vector(15 downto 0);

  signal rx_data_wrap : std_logic_vector(15 downto 0);
  signal rx_charisk_wrap : std_logic_vector(1 downto 0);
  signal rx_disperr_wrap : std_logic_vector(1 downto 0);


  signal rx_data_raw : std_logic_vector(19 downto 0);

  signal rx_enc_err_o_int : std_logic;
  signal rx_disp_err, rx_code_err     : std_logic_vector(1 downto 0);

  signal tx_is_k_swapped              : std_logic_vector(1 downto 0);
  signal tx_data_swapped              : std_logic_vector(15 downto 0);

  signal cur_disp                     : t_8b10b_disparity;



  signal link_up, link_aligned : std_logic;
  signal tx_enable, tx_enable_txclk : std_logic;

  signal tx_sw_reset : std_logic;
  signal rx_enable, rx_enable_rxclk : std_logic;
  signal gtx_rx_reset_a : std_logic;
  signal gtx_tx_reset_a : std_logic;

  signal rx_sw_reset : std_logic;
  signal rx_rec_clk_sampled, tx_out_clk_sampled : std_logic;
  signal gtx_loopback               : std_logic_vector(2 downto 0);

  signal tx_data_8b10b : std_logic_vector(19 downto 0);

  function f_widen(x : std_logic_vector; ratio : integer) return std_logic_vector is
    variable rv : std_logic_vector(x'length * ratio -1 downto 0);
  begin
    for i in 0 to x'length-1 loop
      rv(i*ratio + ratio-1 downto i*ratio) := (others => x(i));
    end loop;
    
    return rv;
  end function;


  signal comma_target_pos : std_logic_vector(7 downto 0);
  signal comma_current_pos : std_logic_vector(7 downto 0);

  signal tx_out_clk_div2 : std_logic;
  signal tx_out_clk_div1 : std_logic;
  signal gtx_rst_n_txdiv2 : std_logic;

  signal run_disparity_q0, run_disparity_q1 : std_logic;
  signal run_disparity_reg : std_logic;

  signal pll_clkfbout_bufin,tx_out_clk_div2_bufin, pll_clkfbout : std_logic;
  signal tx_out_clk_div1_bufin : std_logic;
  signal txusrpll_locked : std_logic;

  signal qpll_sw_reset : std_logic;
  
  attribute mark_debug : string;
  attribute mark_debug of rx_data_raw : signal is "true";
  attribute mark_debug of tx_data_i : signal is "true";
  attribute mark_debug of tx_k_i : signal is "true";
  attribute mark_debug of rx_k_int : signal is "true";
  attribute mark_debug of rx_data_int : signal is "true";
  attribute mark_debug of link_up : signal is "true";
  attribute mark_debug of link_aligned : signal is "true";
  attribute mark_debug of tx_sw_reset : signal is "true";
  attribute mark_debug of rx_sw_reset : signal is "true";
  attribute mark_debug of tx_enable : signal is "true";
  attribute mark_debug of rx_enable: signal is "true";


  signal txusrpll_reset : std_logic;
  
begin  -- rtl

  tx_sw_reset <= debug_i(0);
  tx_enable <= debug_i(1);
  rx_enable <= debug_i(2);
  rx_sw_reset <= debug_i(3);
  qpll_sw_reset <= debug_i(4);
  txusrpll_reset <= debug_i(5); -- not tx_rst_done;
  
  -- Near-end PMA loopback if loopen_i active
  gtx_loopback <= "010" when loopen_i = '1' else "000";

 U_SyncTxEnable : gc_sync_ffs
    port map
    (
      clk_i    => tx_out_clk_div2,
      rst_n_i  => '1',
      data_i   => tx_enable,
      synced_o => tx_enable_txclk
      );

  
  U_SyncTxUsrcCLK2Reset : gc_sync_ffs
    port map
    (
      clk_i    => tx_out_clk_div2,
      rst_n_i  => gtx_rst_n,
      data_i   => '1',
      synced_o => gtx_rst_n_txdiv2
      );

  U_SyncRxEnable : gc_sync_ffs
    port map
    (
      clk_i    => rx_rec_clk,
      rst_n_i  => '1',
      data_i   => rx_enable,
      synced_o => rx_enable_rxclk
      );

  U_SyncRxReset : gc_sync_ffs
    port map
    (
      clk_i    => clk_dmtd_i,
      rst_n_i  => '1',
      data_i   => rx_sw_reset,
      synced_o => gtx_rx_reset_a
      );

  U_SyncQPLLReset : gc_sync_ffs
    port map
    (
      clk_i    => clk_dmtd_i,
      rst_n_i  => '1',
      data_i   => qpll_sw_reset,
      synced_o => qpll_reset_o
      );

  
  U_SyncTxReset : gc_sync_ffs
    port map
    (
      clk_i    => clk_dmtd_i,
      rst_n_i  => '1',
      data_i   => tx_sw_reset,
      synced_o => gtx_tx_reset_a
      );


  U_Sampler_RX : dmtd_sampler
    generic map (
      g_divide_input_by_2 => false,
      g_reverse           => true)
    port map (
      clk_in_i      => rx_rec_clk,
      clk_dmtd_i    => clk_dmtd_i,
      clk_sampled_o => rx_rec_clk_sampled);

  U_Sampler_TX : dmtd_sampler
    generic map (
      g_divide_input_by_2 => false,
      g_reverse           => true)
    port map (
      clk_in_i      => tx_out_clk_div2,
      clk_dmtd_i    => clk_dmtd_i,
      clk_sampled_o => tx_out_clk_sampled);


  comma_target_pos <= debug_i(13 downto 13 - 7);

  process(rx_rec_clk_sampled, tx_out_clk_sampled, debug_i)
  begin
    case debug_i(15 downto 14) is
      when "00" =>
        rx_rbclk_sampled_o <= rx_rec_clk_sampled;
      when "01" =>
        rx_rbclk_sampled_o <= tx_out_clk_sampled;
      when others =>
        rx_rbclk_sampled_o <= '0';
    end case;
  end process;


  tx_enc_err_o <= '0';
  
  p_gen_reset : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then

      rst_d0     <= rst_i;
      rst_synced <= rst_d0;

      if(rst_synced = '1') then
        reset_counter <= (others => '0');
      else
        if(reset_counter(reset_counter'left) = '0') then
          reset_counter <= reset_counter + 1;
        end if;
      end if;
    end if;
  end process;

  gtx_rst <= rst_synced or std_logic(not reset_counter(reset_counter'left));

  
  tx_enc_err_o <= '0';


  tx_clk_o <= tx_out_clk_div2;
  tx_locked_o  <= qpll_locked_i;

  U_BUF_RxRecClk : BUFG
    port map (
      I => rx_rec_clk_bufin,
      O => rx_rec_clk);

  rx_rbclk_o <= rx_rec_clk;

  U_Enc1 : entity work.gc_enc_8b10b
    generic map
    (
      g_use_internal_running_disparity => false
      )
    port map (
      clk_i       => tx_out_clk_div2,
      rst_n_i     => gtx_rst_n_txdiv2,
      in_8b_i     => tx_data_i(15 downto 8),
      dispar_i => run_disparity_reg,
      dispar_o => run_disparity_q0,
      ctrl_i      => tx_k_i(1),
      out_10b_o    => tx_data_8b10b(9 downto 0));


  U_Enc2 : entity work.gc_enc_8b10b
    generic map (
      g_use_internal_running_disparity => false
      )
    port map (
      clk_i       => tx_out_clk_div2,
      rst_n_i     => gtx_rst_n_txdiv2,
      dispar_i => run_disparity_q0,
      dispar_o => run_disparity_q1,
      in_8b_i     => tx_data_i(7 downto 0),
      ctrl_i      => tx_k_i(0),
      out_10b_o    => tx_data_8b10b(19 downto 10));

  p_latch_disparity : process(tx_out_clk_div2)
  begin

    if rising_edge(tx_out_clk_div2) then
      if gtx_rst_n_txdiv2 = '0' then
        run_disparity_reg <= '0';
      else
        run_disparity_reg <= run_disparity_q1;
      end if;
      
    end if;
  end process;
  
    
  
  
  U_GTX_INST : entity work.WHITERABBIT_GTXE2_CHANNEL_WRAPPER_GT
    generic map
    (
       -- Simulation attributes
       GT_SIM_GTRESET_SPEEDUP    =>  "TRUE"        -- Set to "true" to speed up sim reset
    )
    port map
    (
		--------------------------------- CPLL Ports -------------------------------
		CPLLFBCLKLOST_OUT          => open,
		CPLLLOCK_OUT               => open,
		CPLLLOCKDETCLK_IN          => '0',
		CPLLREFCLKLOST_OUT         => open,
		CPLLRESET_IN               => '0',
		-------------------------- Channel - Clocking Ports ------------------------
		GTREFCLK0_IN               => '0',
		---------------------------- Channel - DRP Ports  --------------------------
		DRPADDR_IN                 => (Others => '0'),
		DRPCLK_IN                  => '0',
		DRPDI_IN                   => (Others => '0'),
		DRPDO_OUT                  => open,
		DRPEN_IN                   => '0',
		DRPRDY_OUT                 => open,
		DRPWE_IN                   => '0',
		------------------------------- Clocking Ports -----------------------------
		QPLLCLK_IN                 => qpll_clk_i,
		QPLLREFCLK_IN              => qpll_ref_clk_i,
		------------------------------- Loopback Ports -----------------------------
		LOOPBACK_IN                => gtx_loopback,
		--------------------- RX Initialization and Reset Ports --------------------
--		RXUSERRDY_IN               => rx_cdr_lock,
		RXUSERRDY_IN               => '1', --rx_cdr_lock_filtered,
		-------------------------- RX Margin Analysis Ports ------------------------
		EYESCANDATAERROR_OUT       => open,
		------------------------- Receive Ports - CDR Ports ------------------------
		RXCDRLOCK_OUT              => rx_cdr_lock,
		RXCDRRESET_IN              => '0',   -- this port cannot be generated by the CoreGen GUI, it cannot be turnes "on"                           : in   std_logic;
		------------------ Receive Ports - FPGA RX Interface Ports -----------------
		RXUSRCLK_IN                => rx_rec_clk,
		RXUSRCLK2_IN               => rx_rec_clk,
		------------------ Receive Ports - FPGA RX interface Ports -----------------
		RXDATA_OUT                 => rx_data_raw,
		--------------------------- Receive Ports - RX AFE -------------------------
		GTXRXP_IN                  => pad_rxp_i,
		------------------------ Receive Ports - RX AFE Ports ----------------------
		GTXRXN_IN                  => pad_rxn_i,
		--------------------- Receive Ports - RX Equilizer Ports -------------------
		RXLPMHFHOLD_IN             => '0',          -- this port is always generated by the CoreGen GUI and cannot be turned "off"
		RXLPMLFHOLD_IN             => '0',          -- this port is always generated by the CoreGen GUI and cannot be turned "off"
		--------------- Receive Ports - RX Fabric Output Control Ports -------------
		RXOUTCLK_OUT               => rx_rec_clk_bufin,
		------------- Receive Ports - RX Initialization and Reset Ports ------------
		GTRXRESET_IN               => gtx_rx_reset_a,
		RXPMARESET_IN              => '0',
		-------------- Receive Ports -RX Initialization and Reset Ports ------------
		RXRESETDONE_OUT            => rx_rst_done,
		--------------------- TX Initialization and Reset Ports --------------------
		GTTXRESET_IN               => gtx_tx_reset_a,
		TXUSERRDY_IN               => qpll_locked_i,
		------------------ Transmit Ports - FPGA TX Interface Ports ----------------
		TXUSRCLK_IN                => tx_out_clk,
		TXUSRCLK2_IN               => tx_out_clk,
		------------------ Transmit Ports - TX Data Path interface -----------------
		TXDATA_IN                  => f_widen(tx_data_8b10b, 1),
		---------------- Transmit Ports - TX Driver and OOB signaling --------------
		GTXTXN_OUT                 => pad_txn_o,
		GTXTXP_OUT                 => pad_txp_o,
		----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
		TXOUTCLK_OUT               => tx_out_clk_bufin,
		TXOUTCLKFABRIC_OUT         => open,
		TXOUTCLKPCS_OUT            => open,
		--------------------- Transmit Ports - TX Gearbox Ports --------------------
		TXRESETDONE_OUT            => tx_rst_done,
                ------------------ Transmit Ports - pattern Generator Ports ----------------
                TXPRBSSEL_IN               => "000" --tx_prbs_sel_i
                );


  

  txusrpll_locked <= '1';

  tx_out_clk_div2 <= tx_out_clk;
  
  U_BUF_TxOutClk : BUFG
    port map (
      I => tx_out_clk_bufin,
      O => tx_out_clk);


  U_BUF_TxOutClkFB : BUFG
    port map (
      I => pll_clkfbout_bufin,
      O => pll_clkfbout);


  txpll_lockdet    <= qpll_locked_i;
  rxpll_lockdet    <= rx_cdr_lock_filtered;
  rst_done         <= rx_rst_done and tx_rst_done;
  rst_done_n       <= not rst_done;
  everything_ready <= rst_done and txpll_lockdet and rxpll_lockdet;
  rdy_o            <= everything_ready;
  

  -- 2013 August 19: Peterj
  -- The family 7 GTX seem to have an artifact in rx_cdr_lock. For no reason lock may be lost for a clock cycle
  -- There is not much information on the web but examples of "Series-7 Integrated Block for PCI Express" (pipe_user.v)
  -- show that Xilinx itself implements a small delay before an rx_cdr_lock is propagated.
  p_rx_cdr_lock_filter : process(rx_rec_clk, gtx_rst)
    variable rxcdrlock_cnt      : integer range 0 to c_rxcdrlock_max;
  begin
    if(gtx_rst = '1') then  
      rxcdrlock_cnt := 0;
      rx_cdr_lock_filtered <= '0';
    elsif rising_edge(rx_rec_clk) then
      if rx_cdr_lock = '0' then
        if rxcdrlock_cnt /= c_rxcdrlock_max then
          rxcdrlock_cnt := rxcdrlock_cnt + 1;
        else
          rx_cdr_lock_filtered <= '0';
        end if;
      else
        rxcdrlock_cnt := 0;
        rx_cdr_lock_filtered <= '1';
      end if;
    end if;
  end process;

  
  U_Comma_Detect : entity work.gtx_comma_detect_kintex7_lp
    generic map(
      g_id => g_id
      )
    port map (
      clk_rx_i  => rx_rec_clk,
      rst_i     => gtx_rst,
      rx_data_raw_i => rx_data_raw,
      comma_target_pos_i => comma_target_pos,
      comma_current_pos_o => comma_current_pos,
      link_up_o => link_up,
      aligned_o => link_aligned);

  

  gtx_rst_n <= not gtx_rst;
  
  U_Dec1 : gc_dec_8b10b
    port map (
      clk_i       => rx_rec_clk,
      rst_n_i     => gtx_rst_n,
      in_10b_i    => (rx_data_raw(19 downto 10)),
      ctrl_o      => rx_k_int(1),
      code_err_o  => rx_code_err(1),
      rdisp_err_o => open,
      out_8b_o    => rx_data_int(15 downto 8));

  U_Dec2 : gc_dec_8b10b
    port map (
      clk_i       => rx_rec_clk,
      rst_n_i     => gtx_rst_n,
      in_10b_i    => (rx_data_raw(9 downto 0)),
      ctrl_o      => rx_k_int(0),
      code_err_o  => rx_code_err(0),
      rdisp_err_o => open,
      out_8b_o    => rx_data_int(7 downto 0));

  rx_disp_err <= (others => '0');

  debug_o(0) <= qpll_locked_i; 
  debug_o(1) <= link_up;
  debug_o(2) <= link_aligned;
  debug_o(3) <= tx_rst_done;
  debug_o(4) <= txusrpll_locked;
  debug_o(5) <= rx_rst_done;
  
  debug_o(14 downto 7) <= comma_current_pos;
  
  p_gen_rx_outputs : process(rx_rec_clk, gtx_rst)
  begin
    if(gtx_rst = '1') then
      rx_data_o_int    <= (others => '0');
      rx_k_o_int       <= (others => '0');
      rx_enc_err_o_int <= '0';
    elsif rising_edge(rx_rec_clk) then
      if(rx_enable_rxclk = '1') then
        rx_data_o_int    <= rx_data_int(7 downto 0) & rx_data_int(15 downto 8);
        rx_k_o_int       <= rx_k_int(0) & rx_k_int(1);
        rx_enc_err_o_int <= rx_disp_err(0) or rx_disp_err(1) or rx_code_err(0) or rx_code_err(1);
      else
        rx_data_o_int    <= (others => '1');
        rx_k_o_int       <= (others => '1');
        rx_enc_err_o_int <= '1';
      end if;
    end if;
  end process;

  p_gen_tx_disparity : process(tx_out_clk_div2)
  begin
    if rising_edge(tx_out_clk_div2) then
      if tx_enable_txclk = '0' then
        cur_disp <= RD_MINUS;
      else
        cur_disp <= f_next_8b10b_disparity16(cur_disp, tx_k_i, tx_data_i);
      end if;
    end if;
  end process;

  tx_disparity_o <= to_std_logic(cur_disp);

  rx_data_o <= rx_data_o_int;
  rx_k_o <= rx_k_o_int;
  rx_enc_err_o <= rx_enc_err_o_int;


  fmon_clk_tx_o <= tx_out_clk_div1;
  fmon_clk_tx2_o <= tx_out_clk_div2;
  fmon_clk_rx_o <= rx_rec_clk;

  
  rx_bitslide_o <= (others => '0');

end rtl;

-------------------------------------------------------------------------------
-- Title      : Deterministic Xilinx GTX wrapper - kintex-7 top module
-- Project    : White Rabbit Switch
-------------------------------------------------------------------------------
-- File       : wr_gtx_phy_family7.vhd
-- Author     : Peter Jansweijer, Tomasz Wlostowski
-- Company    : CERN BE-CO-HT
-- Created    : 2013-04-08
-- Last update: 2019-04-18
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
    clk_gtx_i : in std_logic;

    -- DMTD clock for phase measurements (done in the PHY module as we need to
    -- multiplex between several GTX clock outputs)
    clk_dmtd_i : in std_logic;

    -- Reference 62.5 MHz clock input for the TX/RX deterministic phase logic (not the GTX itself)
    clk_ref_i : in std_logic;
    
    -- TX path, synchronous to tx_clk_o (62.5 MHz):
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
    rx_rbclk_sampled_o : out std_logic

    );
end wr_gtx_phy_kintex7_lp;

architecture rtl of wr_gtx_phy_kintex7_lp is

  component WHITERABBIT_GTXE2_CHANNEL_WRAPPER_GT is
    generic
    (
        -- Simulation attributes
        GT_SIM_GTRESET_SPEEDUP    : string     :=  "TRUE";        -- Set to "TRUE" to speed up sim reset (Need Capital Letters!)
        RX_DFE_KL_CFG2_IN         : bit_vector :=   X"3010D90C";
        PMA_RSV_IN                : bit_vector :=   X"00018480";
        PCS_RSVD_ATTR_IN          : bit_vector :=   X"000000000000"
    );
    port 
    (
    --------------------------------- CPLL Ports -------------------------------
    CPLLFBCLKLOST_OUT                       : out  std_logic;
    CPLLLOCK_OUT                            : out  std_logic;
    CPLLLOCKDETCLK_IN                       : in   std_logic;
    CPLLREFCLKLOST_OUT                      : out  std_logic;
    CPLLRESET_IN                            : in   std_logic;
    -------------------------- Channel - Clocking Ports ------------------------
    GTREFCLK0_IN                            : in   std_logic;
    ---------------------------- Channel - DRP Ports  --------------------------
    DRPADDR_IN                              : in   std_logic_vector(8 downto 0);
    DRPCLK_IN                               : in   std_logic;
    DRPDI_IN                                : in   std_logic_vector(15 downto 0);
    DRPDO_OUT                               : out  std_logic_vector(15 downto 0);
    DRPEN_IN                                : in   std_logic;
    DRPRDY_OUT                              : out  std_logic;
    DRPWE_IN                                : in   std_logic;
    ------------------------------- Clocking Ports -----------------------------
    QPLLCLK_IN                              : in   std_logic;
    QPLLREFCLK_IN                           : in   std_logic;
    ------------------------------- Loopback Ports -----------------------------
    LOOPBACK_IN                             : in   std_logic_vector(2 downto 0);
    --------------------- RX Initialization and Reset Ports --------------------
    RXUSERRDY_IN                            : in   std_logic;
    -------------------------- RX Margin Analysis Ports ------------------------
    EYESCANDATAERROR_OUT                    : out  std_logic;
    ------------------------- Receive Ports - CDR Ports ------------------------
    RXCDRLOCK_OUT                           : out  std_logic;
    RXCDRRESET_IN                           : in   std_logic;
    ------------------ Receive Ports - FPGA RX Interface Ports -----------------
    RXUSRCLK_IN                             : in   std_logic;
    RXUSRCLK2_IN                            : in   std_logic;
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
    RXDATA_OUT                              : out  std_logic_vector(15 downto 0);
    RXCHARISK_OUT                              : out  std_logic_vector(1 downto 0);
    RXDISPERR_OUT                              : out  std_logic_vector(1 downto 0);
 
    --------------------------- Receive Ports - RX AFE -------------------------
    GTXRXP_IN                               : in   std_logic;
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    GTXRXN_IN                               : in   std_logic;
    --------------------- Receive Ports - RX Equilizer Ports -------------------
    RXLPMHFHOLD_IN                          : in   std_logic;
    RXLPMLFHOLD_IN                          : in   std_logic;
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    RXOUTCLK_OUT                            : out  std_logic;
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    GTRXRESET_IN                            : in   std_logic;
    RXPMARESET_IN                           : in   std_logic;
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    RXRESETDONE_OUT                         : out  std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    GTTXRESET_IN                            : in   std_logic;
    TXUSERRDY_IN                            : in   std_logic;
    ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
    TXUSRCLK_IN                             : in   std_logic;
    TXUSRCLK2_IN                            : in   std_logic;
    ------------------ Transmit Ports - TX Data Path interface -----------------
    TXDATA_IN                               : in   std_logic_vector(15 downto 0);
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    GTXTXN_OUT                              : out  std_logic;
    GTXTXP_OUT                              : out  std_logic;
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    TXOUTCLK_OUT                            : out  std_logic;
    TXOUTCLKFABRIC_OUT                      : out  std_logic;
    TXOUTCLKPCS_OUT                         : out  std_logic;
    --------------------- Transmit Ports - TX Gearbox Ports --------------------
    TXCHARISK_IN                            : in   std_logic_vector(1 downto 0);
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    TXRESETDONE_OUT                         : out  std_logic;
    ------------------ Transmit Ports - pattern Generator Ports ----------------
    TXPRBSSEL_IN                            : in   std_logic_vector(2 downto 0)
	);
  end component WHITERABBIT_GTXE2_CHANNEL_WRAPPER_GT;

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
  
  constant c_rxcdrlock_max            : integer := 3;
  constant c_reset_cnt_max            : integer := 64;	-- Reset pulse width 64 * 8 = 512 ns
  
  signal rst_synced                   : std_logic;
  signal gtx_rst, gtx_rst_n                      : std_logic;
  signal rst_d0                     : std_logic;
  signal reset_counter              : unsigned(9 downto 0);

--  signal trig0, trig1, trig2, trig3   : std_logic_vector(31 downto 0);

  signal rx_rec_clk_bufin             : std_logic;
  signal rx_rec_clk                   : std_logic;
  signal tx_out_clk_bufin             : std_logic;
  signal tx_out_clk                   : std_logic;
  signal rx_cdr_lock                  : std_logic;
  signal rx_cdr_lock_filtered         : std_logic;

  signal tx_rst_done, rx_rst_done     : std_logic;
  signal txpll_lockdet, rxpll_lockdet : std_logic;
  signal pll_lockdet                  : std_logic;
  signal cpll_lockdet                 : std_logic;
  signal gtreset                      : std_logic;

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


  signal tx_reset_done : std_logic;

  signal link_up, link_aligned : std_logic;
  signal tx_enable, tx_enable_refclk : std_logic;

  signal tx_sw_reset : std_logic;
  signal rx_enable, rx_enable_rxclk : std_logic;
  signal gtx_rx_reset_a : std_logic;
  signal gtx_tx_reset_a : std_logic;

  signal rx_sw_reset : std_logic;
  signal rx_rec_clk_sampled, tx_out_clk_sampled : std_logic;
  signal gtx_loopback               : std_logic_vector(2 downto 0);

  
begin  -- rtl

  tx_sw_reset <= debug_i(0);
  tx_enable <= debug_i(1);
  rx_enable <= debug_i(2);
  rx_sw_reset <= debug_i(3);

  -- Near-end PMA loopback if loopen_i active
  gtx_loopback <= "010" when loopen_i = '1' else "000";

 U_SyncTxEnable : gc_sync_ffs
    port map
    (
      clk_i    => clk_ref_i,
      rst_n_i  => '1',
      data_i   => tx_enable,
      synced_o => tx_enable_refclk
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
      clk_in_i      => tx_out_clk,
      clk_dmtd_i    => clk_dmtd_i,
      clk_sampled_o => tx_out_clk_sampled);


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

  debug_o(0) <= '1'; -- was tx_reset_done
  
  tx_enc_err_o <= '0';

  U_BUF_TxOutClk : BUFG
    port map (
      I => tx_out_clk_bufin,
      O => tx_out_clk);

   tx_clk_o <= tx_out_clk;
   tx_locked_o  <= cpll_lockdet;

      U_BUF_RxRecClk : BUFG
    port map (
      I => rx_rec_clk_bufin,
      O => rx_rec_clk);

  rx_rbclk_o <= rx_rec_clk;
  
  U_GTX_INST : WHITERABBIT_GTXE2_CHANNEL_WRAPPER_GT
    generic map
    (
       -- Simulation attributes
       GT_SIM_GTRESET_SPEEDUP    =>  "TRUE"        -- Set to "true" to speed up sim reset
    )
    port map
    (
		--------------------------------- CPLL Ports -------------------------------
		CPLLFBCLKLOST_OUT          => open,
		CPLLLOCK_OUT               => cpll_lockdet,
		CPLLLOCKDETCLK_IN          => '0',
		CPLLREFCLKLOST_OUT         => open,
		CPLLRESET_IN               => gtx_rst,
		-------------------------- Channel - Clocking Ports ------------------------
		GTREFCLK0_IN               => clk_gtx_i,
		---------------------------- Channel - DRP Ports  --------------------------
		DRPADDR_IN                 => (Others => '0'),
		DRPCLK_IN                  => '0',
		DRPDI_IN                   => (Others => '0'),
		DRPDO_OUT                  => open,
		DRPEN_IN                   => '0',
		DRPRDY_OUT                 => open,
		DRPWE_IN                   => '0',
		------------------------------- Clocking Ports -----------------------------
		QPLLCLK_IN                 => '0',
		QPLLREFCLK_IN              => '0',
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
		RXDATA_OUT                 => rx_data_wrap,
                RXCHARISK_OUT => rx_charisk_wrap,
                RXDISPERR_OUT => rx_disperr_wrap,
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
		TXUSERRDY_IN               => cpll_lockdet,
		------------------ Transmit Ports - FPGA TX Interface Ports ----------------
		TXUSRCLK_IN                => tx_out_clk,
		TXUSRCLK2_IN               => tx_out_clk,
		------------------ Transmit Ports - TX Data Path interface -----------------
		TXDATA_IN                  => tx_data_swapped,
--       TXDATA_IN                  => tx_data_i,
		---------------- Transmit Ports - TX Driver and OOB signaling --------------
		GTXTXN_OUT                 => pad_txn_o,
		GTXTXP_OUT                 => pad_txp_o,
		----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
		TXOUTCLK_OUT               => tx_out_clk_bufin,
		TXOUTCLKFABRIC_OUT         => open,
		TXOUTCLKPCS_OUT            => open,
		--------------------- Transmit Ports - TX Gearbox Ports --------------------
		TXCHARISK_IN               => tx_is_k_swapped,
--       TXCHARISK_IN               => tx_k_i,
		------------- Transmit Ports - TX Initialization and Reset Ports -----------
		TXRESETDONE_OUT            => tx_rst_done,
                ------------------ Transmit Ports - pattern Generator Ports ----------------
    TXPRBSSEL_IN               => "000" --tx_prbs_sel_i
                );

  rx_data_raw(7 downto 0) <= rx_data_wrap(7 downto 0);
  rx_data_raw(8) <= rx_charisk_wrap(0);
  rx_data_raw(9) <= rx_disperr_wrap(0);
  rx_data_raw(17 downto 10) <= rx_data_wrap(15 downto 8);
  rx_data_raw(18) <= rx_charisk_wrap(1);
  rx_data_raw(19) <= rx_disperr_wrap(1);
  


  txpll_lockdet    <= cpll_lockdet;
  rxpll_lockdet    <= rx_cdr_lock_filtered;
  gtreset          <= not cpll_lockdet;
  rst_done         <= rx_rst_done and tx_rst_done;
  rst_done_n       <= not rst_done;
  pll_lockdet      <= txpll_lockdet and rxpll_lockdet;
  everything_ready <= rst_done and pll_lockdet;
  rdy_o            <= everything_ready;


  process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if tx_enable_refclk = '0' then
        tx_is_k_swapped <= "00";
        tx_data_swapped <= (others => '0');
      else
        tx_is_k_swapped <= tx_k_i(0) & tx_k_i(1);
        tx_data_swapped <= tx_data_i(7 downto 0) & tx_data_i(15 downto 8);
      end if;
    end if;
  end process;

  

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

  
  U_Comma_Detect : entity work.gtx_comma_detect_lp
    generic map(
      g_id => g_id
      )
    port map (
      clk_rx_i  => rx_rec_clk,
      rst_i     => gtx_rst,
      rx_data_raw_i => rx_data_raw,
      link_up_o => link_up,
      aligned_o => link_aligned,
      rx_data_i =>rx_data_o_int,
      rx_k_i => rx_k_o_int,
      rx_error_i => rx_enc_err_o_int);

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
  
  debug_o(1) <= link_up;
  debug_o(2) <= link_aligned;

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

  p_gen_tx_disparity : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if tx_enable_refclk = '0' then
        cur_disp <= RD_MINUS;
      else
        cur_disp <= f_next_8b10b_disparity16(cur_disp, tx_k_i, tx_data_i);
      end if;
    end if;
  end process;

  tx_disparity_o <= to_std_logic(cur_disp);

  rx_data_o <= rx_data_o_int;
  rx_k_o <= rx_k_o_int;
  rx_enc_err_o <= '0';-- rx_enc_err_o_int;


end rtl;

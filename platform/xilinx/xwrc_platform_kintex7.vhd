-------------------------------------------------------------------------------
-- Title      : Kintex 7 components needed for WR PTP Core on Xilinx
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : wrc_platform_kintex7.vhd
-- Author     : Maciej Lipinski, Grzegorz Daniluk, Dimitrios Lampridis
-- Company    : CERN
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description:
-- This module instantiates platform-specific modules that are needed by the
-- WR PTP Core (WRPC) to interface hardware on the Kintex 7 family of Xilinx FPGAs.
-- In particular it contains:
-- * PHY
-- * PLLs
-- * buffers
-- The Kintex platform supports only one GTP transceiver, and therefore one SFP
-- port.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2016-2017 CERN / BE-CO-HT
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- either version 2.1 of the License, or (at your option) any
-- later version
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE.  See the GNU Lesser General Public License for more
-- details
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.endpoint_pkg.all;
use work.gencores_pkg.all;
use work.wr_xilinx_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity xwrc_platform_kintex7 is
  generic
    (
      -- Set to FALSE if you want to instantiate your own PLLs
      g_with_main_pll              : boolean := TRUE;
      g_with_helper_pll            : boolean := TRUE;
      -- Selects Direct DMTD clock input (when g_with_helper_pll = FALSE)
      g_dmtd_div2                  : boolean := FALSE;
      -- Select whether to include external ref clock input
      g_with_external_clock_input  : boolean := FALSE;
      -- Select whether to use bootstrap clock as a second input to system PLLs
      g_with_bootstrap_clock_input : boolean := FALSE;
      -- Config for the auxiliary PLL output
      g_aux_pll_cfg                : t_auxpll_cfg_array := c_AUXPLL_CFG_ARRAY_DEFAULT;
      -- Set to TRUE will speed up some initialization processes
      g_simulation                 : integer := 0);
  port (
    ---------------------------------------------------------------------------
    -- Asynchronous reset (active low)
    ---------------------------------------------------------------------------
    areset_n_i             : in  std_logic;
    ---------------------------------------------------------------------------
    -- 10MHz ext ref clock input (g_with_external_clock_input = TRUE)
    ---------------------------------------------------------------------------
    clk_10m_ext_i          : in  std_logic             := '0';
    ---------------------------------------------------------------------------
    -- 125 MHz GTP/GTX reference
    ---------------------------------------------------------------------------
    clk_125m_gtp_p_i       : in  std_logic;
    clk_125m_gtp_n_i       : in  std_logic;
    ---------------------------------------------------------------------------
    -- 125 MHz Bootstrap clock (g_with_bootstrap_clock_input = TRUE)
    ---------------------------------------------------------------------------
    clk_125m_bootstrap_i   : in  std_logic             := '0';
    ---------------------------------------------------------------------------
    -- 125 MHz Bootstrap clock select (default is GTP/GTX reference clock)
    ---------------------------------------------------------------------------
    clk_sys_sel_i          : in  std_logic             := '1';
    ---------------------------------------------------------------------------
    -- Main (system) clock
    ---------------------------------------------------------------------------
    -- g_with_main_pll = FALSE (Direct 62.5MHz sys clock)
    clk_62m5_sys_i         : in  std_logic             := '0';
    clk_sys_locked_i       : in  std_logic             := '1';
    ---------------------------------------------------------------------------
    -- Helper clock
    ---------------------------------------------------------------------------
    -- g_with_helper_pll = TRUE
    clk_20m_vcxo_i         : in  std_logic             := '0';
    -- (g_with_helper_pll = FALSE) and (g_dmtd_div2 = TRUE)
    -- Used in CLBv3 reference design
    clk_125m_dmtd_i        : in  std_logic             := '0';
    -- (g_with_helper_pll = FALSE) and (g_dmtd_div2 = FALSE) (Direct 62.49MHz helper)
    clk_62m5_dmtd_i        : in  std_logic             := '0';
    clk_dmtd_locked_i      : in  std_logic             := '1';
    ---------------------------------------------------------------------------
    -- External clock (g_with_external_clock_input = TRUE)
    ---------------------------------------------------------------------------
    -- 125MHz derived from 10MHz external reference and lock status
    clk_125m_ext_i         : in  std_logic             := '0';
    clk_ext_locked_i       : in  std_logic             := '1';
    clk_ext_stopped_i      : in  std_logic             := '0';
    clk_ext_rst_o          : out std_logic;
    ---------------------------------------------------------------------------
    -- SFP - channel 0
    ---------------------------------------------------------------------------
    sfp_txn_o              : out std_logic;
    sfp_txp_o              : out std_logic;
    sfp_rxn_i              : in  std_logic;
    sfp_rxp_i              : in  std_logic;
    sfp_tx_fault_i         : in  std_logic             := '0';
    sfp_los_i              : in  std_logic             := '0';
    sfp_tx_disable_o       : out std_logic;
    ---------------------------------------------------------------------------
    --Auxiliary PLL outputs
    ---------------------------------------------------------------------------
    clk_pll_aux_o          : out std_logic_vector(3 downto 0);
    pll_aux_locked_o       : out std_logic;
    ---------------------------------------------------------------------------
    --Interface to WR PTP Core (WRPC)
    ---------------------------------------------------------------------------
    -- PLL outputs
    clk_62m5_sys_o         : out std_logic;
    clk_125m_ref_o         : out std_logic;
    clk_20m_o              : out std_logic;
    clk_ref_locked_o       : out std_logic;
    clk_62m5_dmtd_o        : out std_logic;
    clk_250m_dmtd_over_o   : out std_logic;
    pll_locked_o           : out std_logic;
    clk_10m_ext_o          : out std_logic;
    -- PHY
    phy16_o                : out t_phy_16bits_to_wrc;
    phy16_i                : in  t_phy_16bits_from_wrc := c_dummy_phy16_from_wrc;
    -- External reference
    ext_ref_mul_o          : out std_logic;
    ext_ref_mul_locked_o   : out std_logic;
    ext_ref_mul_stopped_o  : out std_logic;
    ext_ref_rst_i          : in  std_logic             := '0'
  );

end entity xwrc_platform_kintex7;

architecture rtl of xwrc_platform_kintex7 is

  -----------------------------------------------------------------------------
  -- Signals declaration
  -----------------------------------------------------------------------------

  signal pll_arst            : std_logic := '0';

  -- Main / helper PLLs
  signal clk_125m_pllref_buf : std_logic;
  signal clk_sys             : std_logic;
  signal clk_sys_locked      : std_logic;
  signal clk_dmtd            : std_logic := '0'; -- initialize for simulation
  signal clk_dmtd_locked     : std_logic;
  signal clk_pll_aux         : std_logic_vector(3 downto 0);

  -- GTX Phy
  signal clk_ref             : std_logic;
  signal clk_125m_gtx_buf    : std_logic;
  signal clk_ref_locked      : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Clock PLLs
  -----------------------------------------------------------------------------

  -- active high async reset for PLLs
  pll_arst <= not areset_n_i;

  -- This module is parameterised on the instantiation of both the main and helper PLLs
  -- When both PLLs are enabled the main takes a 125MHz clock signal as input and
  -- produces the 62.5MHz main system clock and any configured auxiliary clocks. When
  -- g_with_bootstrap_clock_input = TRUE, a second clock input is taken to the system
  -- PLL (on supported devices) that enables a bootstrap clock to be used for initial
  -- system configuration, with the clock source chosen via clk_sys_sel_i. The
  -- bootstrap clock can be used to drive clk_sys while the system is configured, for
  -- example, when using programmable oscillators for the main PLL.

  -- The other PLL takes a 20MHz clock signal as input and produces the
  -- 62.5MHz DMTD clock.

  -- A third PLL is instantiated if also g_with_external_clock_input = TRUE.
  -- In that case, a 10MHz external reference is multiplied to generate a
  -- 125MHz reference clock

  -- The 125MHz reference clock is derived from the GTX transceiver

  ---------------------------------------------------------------------------
  --  Input Clock Buffering
  ---------------------------------------------------------------------------

  -- Dedicated GTX clock.
  cmp_gtp_dedicated_clk : IBUFDS_GTE2
  generic map(
    CLKCM_CFG    => true,
    CLKRCV_TRST  => true,
    CLKSWING_CFG => "11")
  port map (
    O     => clk_125m_gtx_buf,
    ODIV2 => open,
    CEB   => '0',
    I     => clk_125m_gtp_p_i,
    IB    => clk_125m_gtp_n_i);

  -- System PLL input clock buffer
  cmp_clk_sys_buf_i : BUFG
    port map (
      I => clk_125m_gtx_buf,
      O => clk_125m_pllref_buf);

  ---------------------------------------------------------------------------
  --  Main PLL
  ---------------------------------------------------------------------------

  gen_use_main_pll : if (g_with_main_pll = TRUE) generate
    signal clk_sys_fb         : std_logic;
    signal clk_125m_bootstrap : std_logic;
  begin

    -- Bootstrap clock source
    gen_bootstrap_clock_enabled : if (g_with_bootstrap_clock_input = TRUE) generate
      clk_125m_bootstrap <= clk_125m_bootstrap_i;
    end generate gen_bootstrap_clock_enabled;

    gen_bootstrap_clock_disabled : if (g_with_bootstrap_clock_input = FALSE) generate
      clk_125m_bootstrap <= '0';
    end generate gen_bootstrap_clock_disabled;

    -- System PLL (125 MHz -> 62.5 MHz)
    cmp_sys_clk_pll : MMCME2_ADV
      generic map (
        BANDWIDTH            => "OPTIMIZED",
        CLKOUT4_CASCADE      => false,
        COMPENSATION         => "ZHOLD",
        STARTUP_WAIT         => false,
        DIVCLK_DIVIDE        => 1,
        CLKFBOUT_MULT_F      => 8.000,     -- 125 MHz x 8.
        CLKFBOUT_PHASE       => 0.000,
        CLKFBOUT_USE_FINE_PS => false,

        CLKIN1_PERIOD       => 8.000,      -- 8 ns means 125 MHz
        CLKIN2_PERIOD       => 8.000,      -- 8 ns means 125 MHz

        CLKOUT0_DIVIDE_F    => 16.000,     -- 62.5 MHz sys clock
        CLKOUT0_PHASE       => 0.000,
        CLKOUT0_DUTY_CYCLE  => 0.500,
        CLKOUT0_USE_FINE_PS => false,

        CLKOUT1_DIVIDE     => g_aux_pll_cfg(0).divide,
        CLKOUT1_PHASE      => 0.000,
        CLKOUT1_DUTY_CYCLE => 0.500,
        CLKOUT1_USE_FINE_PS  => false,

        CLKOUT2_DIVIDE     => g_aux_pll_cfg(1).divide,
        CLKOUT2_PHASE      => 0.000,
        CLKOUT2_DUTY_CYCLE => 0.500,
        CLKOUT2_USE_FINE_PS  => false,

        CLKOUT3_DIVIDE     => g_aux_pll_cfg(2).divide,
        CLKOUT3_PHASE      => 0.000,
        CLKOUT3_DUTY_CYCLE => 0.500,
        CLKOUT3_USE_FINE_PS  => false,

        CLKOUT4_DIVIDE     => g_aux_pll_cfg(3).divide,
        CLKOUT4_PHASE      => 0.000,
        CLKOUT4_DUTY_CYCLE => 0.500,
        CLKOUT4_USE_FINE_PS  => false,

        REF_JITTER1   => 0.010)
      port map (
        -- Output clocks
        CLKFBOUT     => clk_sys_fb,
        CLKOUT0      => clk_sys,
        CLKOUT1      => clk_pll_aux(0),
        CLKOUT2      => clk_pll_aux(1),
        CLKOUT3      => clk_pll_aux(2),
        CLKOUT4      => clk_pll_aux(3),
        -- Input clock control
        CLKFBIN      => clk_sys_fb,
        CLKIN1       => clk_125m_pllref_buf,
        CLKIN2       => clk_125m_bootstrap,
        -- Tied to always select the primary input clock
        CLKINSEL     => clk_sys_sel_i,
        -- Ports for dynamic reconfiguration
        DADDR        => (others => '0'),
        DCLK         => '0',
        DEN          => '0',
        DI           => (others => '0'),
        DO           => open,
        DRDY         => open,
        DWE          => '0',
        -- Ports for dynamic phase shift
        PSCLK        => '0',
        PSEN         => '0',
        PSINCDEC     => '0',
        PSDONE       => open,
        -- Other control and status signals
        LOCKED       => clk_sys_locked,
        CLKINSTOPPED => open,
        CLKFBSTOPPED => open,
        PWRDWN       => '0',
        RST          => pll_arst);

    pll_aux_locked_o <= clk_sys_locked;

  end generate gen_use_main_pll;

  ---------------------------------------------------------------------------
  -- Main Passthrough
  ---------------------------------------------------------------------------

  gen_main_passthrough : if (g_with_main_pll = FALSE) generate
  begin
    clk_sys          <= clk_62m5_sys_i;
    clk_sys_locked   <= clk_sys_locked_i;
    clk_pll_aux      <= (others => '0');
    pll_aux_locked_o <= '0';
  end generate gen_main_passthrough;

  ---------------------------------------------------------------------------
  --  Helper PLL
  ---------------------------------------------------------------------------

  gen_use_helper_pll : if (g_with_helper_pll = TRUE) generate
    signal clk_20m_vcxo_buf : std_logic;
    signal clk_dmtd_fb      : std_logic;
  begin

    -- DMTD PLL input clock buffer
    cmp_clk_dmtd_buf_i : BUFG
    port map (
      O => clk_20m_vcxo_buf,
      I => clk_20m_vcxo_i);

    -- DMTD PLL (20 MHz -> ~62,5 MHz)
    cmp_dmtd_clk_pll : MMCME2_ADV
      generic map (
        BANDWIDTH            => "OPTIMIZED",
        CLKOUT4_CASCADE      => false,
        COMPENSATION         => "ZHOLD",
        STARTUP_WAIT         => false,
        DIVCLK_DIVIDE        => 1,
        CLKFBOUT_MULT_F      => 50.000,    -- 20 MHz -> 1 GHz
        CLKFBOUT_PHASE       => 0.000,
        CLKFBOUT_USE_FINE_PS => false,
        CLKOUT0_DIVIDE_F     => 16.000,    -- 1GHz/16 -> 62.5 MHz
        CLKOUT0_PHASE        => 0.000,
        CLKOUT0_DUTY_CYCLE   => 0.500,
        CLKOUT0_USE_FINE_PS  => false,
        CLKOUT1_DIVIDE       => 16,        -- 1GHz/16 -> 62.5 MHz
        CLKOUT1_PHASE        => 0.000,
        CLKOUT1_DUTY_CYCLE   => 0.500,
        CLKOUT1_USE_FINE_PS  => false,
        CLKIN1_PERIOD        => 50.000,    -- 50ns for 20 MHz
        REF_JITTER1          => 0.010)
      port map (
        -- Output clocks
        CLKFBOUT     => clk_dmtd_fb,
        CLKOUT0      => clk_dmtd,
        -- Input clock control
        CLKFBIN      => clk_dmtd_fb,
        CLKIN1       => clk_20m_vcxo_buf,
        CLKIN2       => '0',
        -- Tied to always select the primary input clock
        CLKINSEL     => '1',
        -- Ports for dynamic reconfiguration
        DADDR        => (others => '0'),
        DCLK         => '0',
        DEN          => '0',
        DI           => (others => '0'),
        DO           => open,
        DRDY         => open,
        DWE          => '0',
        -- Ports for dynamic phase shift
        PSCLK        => '0',
        PSEN         => '0',
        PSINCDEC     => '0',
        PSDONE       => open,
        -- Other control and status signals
        LOCKED       => clk_dmtd_locked,
        CLKINSTOPPED => open,
        CLKFBSTOPPED => open,
        PWRDWN       => '0',
        RST          => pll_arst);

  end generate gen_use_helper_pll;

  ---------------------------------------------------------------------------
  -- Helper Passthrough
  ---------------------------------------------------------------------------

  gen_helper_passthrough : if (g_with_helper_pll = FALSE) generate
  begin

    gen_dmtd_div2 : if (g_dmtd_div2 = TRUE) generate
    begin
      -- DMTD Div2 (124.9920 MHz -> 62.496 MHz)
      process(clk_125m_dmtd_i)
      begin
        if rising_edge(clk_125m_dmtd_i) then
          clk_dmtd <= not clk_dmtd;
        end if;
      end process;
      clk_dmtd_locked <= '1';
    end generate gen_dmtd_div2;

    gen_dmtd_direct : if (g_dmtd_div2 = FALSE) generate
    begin
      -- DMTD direct passthrough (62.496 MHz)
      clk_dmtd        <= clk_62m5_dmtd_i;
      clk_dmtd_locked <= clk_dmtd_locked_i;
    end generate gen_dmtd_direct;

  end generate gen_helper_passthrough;

  ---------------------------------------------------------------------------
  -- External reference (10MHz) PLL
  ---------------------------------------------------------------------------

  gen_kintex7_artix7_ext_ref_pll : if (g_with_external_clock_input = TRUE) generate
    signal clk_ext_fbi : std_logic;
    signal clk_ext_fbo : std_logic;
    signal clk_ext_buf : std_logic;
    signal clk_ext_mul : std_logic;
    signal pll_ext_rst : std_logic;
  begin
    mmcm_adv_inst : MMCME2_ADV
      generic map (
        BANDWIDTH            => "OPTIMIZED",
        CLKOUT4_CASCADE      => FALSE,
        COMPENSATION         => "ZHOLD",
        STARTUP_WAIT         => FALSE,
        DIVCLK_DIVIDE        => 1,
        CLKFBOUT_MULT_F      => 62.500,
        CLKFBOUT_PHASE       => 0.000,
        CLKFBOUT_USE_FINE_PS => FALSE,
        CLKOUT0_DIVIDE_F     => 10.000,
        CLKOUT0_PHASE        => 0.000,
        CLKOUT0_DUTY_CYCLE   => 0.500,
        CLKOUT0_USE_FINE_PS  => FALSE,
        CLKIN1_PERIOD        => 100.000,
        REF_JITTER1          => 0.005)
      port map (
        -- Output clocks
        CLKFBOUT     => clk_ext_fbo,
        CLKOUT0      => clk_ext_mul,
        -- Input clock control
        CLKFBIN      => clk_ext_fbi,
        CLKIN1       => clk_ext_buf,
        CLKIN2       => '0',
        -- Tied to always select the primary input clock
        CLKINSEL     => '1',
        -- Ports for dynamic reconfiguration
        DADDR        => (others => '0'),
        DCLK         => '0',
        DEN          => '0',
        DI           => (others => '0'),
        DO           => open,
        DRDY         => open,
        DWE          => '0',
        -- Ports for dynamic phase shift
        PSCLK        => '0',
        PSEN         => '0',
        PSINCDEC     => '0',
        PSDONE       => open, -- Other control and status signals
        LOCKED       => ext_ref_mul_locked_o,
        CLKINSTOPPED => ext_ref_mul_stopped_o,
        CLKFBSTOPPED => open,
        PWRDWN       => '0',
        RST          => pll_ext_rst);

    -- External reference input buffer
    cmp_clk_ext_buf_i : BUFG
      port map (
        O => clk_ext_buf,
        I => clk_10m_ext_i);

    clk_10m_ext_o <= clk_ext_buf;

    -- External reference feedback buffer
    cmp_clk_ext_buf_fb : BUFG
      port map (
        O => clk_ext_fbi,
        I => clk_ext_fbo);

    -- External reference output buffer
    cmp_clk_ext_buf_o : BUFG
      port map (
        O => ext_ref_mul_o,
        I => clk_ext_mul);

    cmp_extend_ext_reset : gc_extend_pulse
      generic map (
        g_width => 1000)
      port map (
        clk_i      => clk_sys,
        rst_n_i    => clk_sys_locked,
        pulse_i    => ext_ref_rst_i,
        extended_o => pll_ext_rst);

  end generate gen_kintex7_artix7_ext_ref_pll;

  ---------------------------------------------------------------------------
  -- No external reference
  ---------------------------------------------------------------------------

  gen_no_ext_ref_pll : if (g_with_external_clock_input = FALSE) generate
    clk_10m_ext_o         <= '0';
    ext_ref_mul_o         <= '0';
    ext_ref_mul_locked_o  <= '1';
    ext_ref_mul_stopped_o <= '1';
  end generate gen_no_ext_ref_pll;

  ---------------------------------------------------------------------------
  -- Aux Clock Ouptut Buffers
  ---------------------------------------------------------------------------

  gen_auxclk_bufs: for I in g_aux_pll_cfg'range generate
    -- Aux PLL_BASE clocks with BUFG enabled
    gen_auxclk_bufg_en: if g_aux_pll_cfg(I).enabled and g_aux_pll_cfg(I).bufg_en generate
      cmp_clk_sys_buf_o : BUFG
        port map (
          O => clk_pll_aux_o(I),
          I => clk_pll_aux(I));
    end generate;
    -- Aux PLL_BASE clocks with BUFG disabled
    gen_auxclk_no_bufg: if g_aux_pll_cfg(I).enabled and g_aux_pll_cfg(I).bufg_en = FALSE generate
      clk_pll_aux_o(I) <= clk_pll_aux(I);
    end generate;
    -- Disabled aux PLL_BASE clocks
    gen_auxclk_disabled: if not g_aux_pll_cfg(I).enabled generate
      clk_pll_aux_o(I) <= '0';
    end generate;

  end generate gen_auxclk_bufs;

  ---------------------------------------------------------------------------
  -- Outputs
  ---------------------------------------------------------------------------

  pll_locked_o <= clk_dmtd_locked and clk_sys_locked;

  -- always pass ext reference reset input to output, even when not used
  clk_ext_rst_o <= ext_ref_rst_i;

  -- DMTD output clock buffer
  cmp_clk_dmtd_buf_o : BUFG
  port map (
    O => clk_62m5_dmtd_o,
    I => clk_dmtd);

  -- System output clock buffer
  cmp_clk_sys_buf_o : BUFG
  port map (
    I => clk_sys,
    O => clk_62m5_sys_o);

  ---------------------------------------------------------------------------
  -- Transceiver PHY
  ---------------------------------------------------------------------------

  cmp_gtx: wr_gtx_phy_family7
    generic map(
      g_simulation => g_simulation)
    port map(
      clk_gtx_i      => clk_125m_gtx_buf,
      tx_out_clk_o   => clk_ref,
      tx_data_i      => phy16_i.tx_data,
      tx_k_i         => phy16_i.tx_k,
      tx_disparity_o => phy16_o.tx_disparity,
      tx_enc_err_o   => phy16_o.tx_enc_err,
      rx_rbclk_o     => phy16_o.rx_clk,
      rx_data_o      => phy16_o.rx_data,
      rx_k_o         => phy16_o.rx_k,
      rx_enc_err_o   => phy16_o.rx_enc_err,
      rx_bitslide_o  => phy16_o.rx_bitslide,
      rst_i          => phy16_i.rst,
      loopen_i       => phy16_i.loopen_vec,
      tx_prbs_sel_i  => phy16_i.tx_prbs_sel,
      rdy_o          => phy16_o.rdy,

      pad_txn_o => sfp_txn_o,
      pad_txp_o => sfp_txp_o,
      pad_rxn_i => sfp_rxn_i,
      pad_rxp_i => sfp_rxp_i,

      tx_locked_o   => clk_ref_locked);

  clk_125m_ref_o       <= clk_ref;
  clk_ref_locked_o     <= clk_ref_locked;
  phy16_o.ref_clk      <= clk_ref;
  phy16_o.sfp_tx_fault <= sfp_tx_fault_i;
  phy16_o.sfp_los      <= sfp_los_i;
  sfp_tx_disable_o     <= phy16_i.sfp_tx_disable;

end architecture rtl;

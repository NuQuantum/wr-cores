---------------------------------------------------------------------------------------
-- Title          : Wishbone slave core for WR Core Diagnostics
---------------------------------------------------------------------------------------
-- File           : wrc_diags_wb.vhd
-- Author         : auto-generated by wbgen2 from wrc_diags_wb.wb
-- Created        : Fri Feb 19 19:31:37 2021
-- Version        : 0x00000001
-- Standard       : VHDL'87
---------------------------------------------------------------------------------------
-- THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE wrc_diags_wb.wb
-- DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wrc_diags_wbgen2_pkg.all;


entity wrc_diags_wb is
port (
  rst_n_i                                  : in     std_logic;
  clk_sys_i                                : in     std_logic;
  wb_adr_i                                 : in     std_logic_vector(4 downto 0);
  wb_dat_i                                 : in     std_logic_vector(31 downto 0);
  wb_dat_o                                 : out    std_logic_vector(31 downto 0);
  wb_cyc_i                                 : in     std_logic;
  wb_sel_i                                 : in     std_logic_vector(3 downto 0);
  wb_stb_i                                 : in     std_logic;
  wb_we_i                                  : in     std_logic;
  wb_ack_o                                 : out    std_logic;
  wb_err_o                                 : out    std_logic;
  wb_rty_o                                 : out    std_logic;
  wb_stall_o                               : out    std_logic;
  regs_i                                   : in     t_wrc_diags_in_registers;
  regs_o                                   : out    t_wrc_diags_out_registers
);
end wrc_diags_wb;

architecture syn of wrc_diags_wb is

signal wrc_diags_ver_id_int                     : std_logic_vector(31 downto 0);
signal wrc_diags_ctrl_data_snapshot_int         : std_logic      ;
signal ack_sreg                                 : std_logic_vector(9 downto 0);
signal rddata_reg                               : std_logic_vector(31 downto 0);
signal wrdata_reg                               : std_logic_vector(31 downto 0);
signal bwsel_reg                                : std_logic_vector(3 downto 0);
signal rwaddr_reg                               : std_logic_vector(4 downto 0);
signal ack_in_progress                          : std_logic      ;
signal wr_int                                   : std_logic      ;
signal rd_int                                   : std_logic      ;
signal allones                                  : std_logic_vector(31 downto 0);
signal allzeros                                 : std_logic_vector(31 downto 0);

begin
-- Some internal signals assignments
wrdata_reg <= wb_dat_i;
-- 
-- Main register bank access process.
process (clk_sys_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    ack_sreg <= "0000000000";
    ack_in_progress <= '0';
    rddata_reg <= "00000000000000000000000000000000";
    wrc_diags_ver_id_int <= "00000000000000000000000000000001";
    wrc_diags_ctrl_data_snapshot_int <= '0';
  elsif rising_edge(clk_sys_i) then
-- advance the ACK generator shift register
    ack_sreg(8 downto 0) <= ack_sreg(9 downto 1);
    ack_sreg(9) <= '0';
    if (ack_in_progress = '1') then
      if (ack_sreg(0) = '1') then
        ack_in_progress <= '0';
      else
      end if;
    else
      if ((wb_cyc_i = '1') and (wb_stb_i = '1')) then
        case rwaddr_reg(4 downto 0) is
        when "00000" => 
          if (wb_we_i = '1') then
            wrc_diags_ver_id_int <= wrdata_reg(31 downto 0);
          end if;
          rddata_reg(31 downto 0) <= wrc_diags_ver_id_int;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "00001" => 
          if (wb_we_i = '1') then
            wrc_diags_ctrl_data_snapshot_int <= wrdata_reg(8);
          end if;
          rddata_reg(0) <= regs_i.ctrl_data_valid_i;
          rddata_reg(8) <= wrc_diags_ctrl_data_snapshot_int;
          rddata_reg(1) <= 'X';
          rddata_reg(2) <= 'X';
          rddata_reg(3) <= 'X';
          rddata_reg(4) <= 'X';
          rddata_reg(5) <= 'X';
          rddata_reg(6) <= 'X';
          rddata_reg(7) <= 'X';
          rddata_reg(9) <= 'X';
          rddata_reg(10) <= 'X';
          rddata_reg(11) <= 'X';
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "00010" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(0) <= regs_i.wdiag_sstat_wr_mode_i;
          rddata_reg(11 downto 8) <= regs_i.wdiag_sstat_servostate_i;
          rddata_reg(1) <= 'X';
          rddata_reg(2) <= 'X';
          rddata_reg(3) <= 'X';
          rddata_reg(4) <= 'X';
          rddata_reg(5) <= 'X';
          rddata_reg(6) <= 'X';
          rddata_reg(7) <= 'X';
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "00011" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(0) <= regs_i.wdiag_pstat_link_i;
          rddata_reg(1) <= regs_i.wdiag_pstat_locked_i;
          rddata_reg(2) <= 'X';
          rddata_reg(3) <= 'X';
          rddata_reg(4) <= 'X';
          rddata_reg(5) <= 'X';
          rddata_reg(6) <= 'X';
          rddata_reg(7) <= 'X';
          rddata_reg(8) <= 'X';
          rddata_reg(9) <= 'X';
          rddata_reg(10) <= 'X';
          rddata_reg(11) <= 'X';
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "00100" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(7 downto 0) <= regs_i.wdiag_ptpstat_ptpstate_i;
          rddata_reg(8) <= 'X';
          rddata_reg(9) <= 'X';
          rddata_reg(10) <= 'X';
          rddata_reg(11) <= 'X';
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "00101" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(7 downto 0) <= regs_i.wdiag_astat_aux_i;
          rddata_reg(8) <= 'X';
          rddata_reg(9) <= 'X';
          rddata_reg(10) <= 'X';
          rddata_reg(11) <= 'X';
          rddata_reg(12) <= 'X';
          rddata_reg(13) <= 'X';
          rddata_reg(14) <= 'X';
          rddata_reg(15) <= 'X';
          rddata_reg(16) <= 'X';
          rddata_reg(17) <= 'X';
          rddata_reg(18) <= 'X';
          rddata_reg(19) <= 'X';
          rddata_reg(20) <= 'X';
          rddata_reg(21) <= 'X';
          rddata_reg(22) <= 'X';
          rddata_reg(23) <= 'X';
          rddata_reg(24) <= 'X';
          rddata_reg(25) <= 'X';
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "00110" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_txfcnt_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "00111" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_rxfcnt_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "01000" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_sec_msb_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "01001" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_sec_lsb_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "01010" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_ns_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "01011" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_mu_msb_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "01100" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_mu_lsb_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "01101" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_dms_msb_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "01110" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_dms_lsb_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "01111" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_asym_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "10000" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_cko_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "10001" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_setp_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "10010" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_ucnt_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "10011" => 
          if (wb_we_i = '1') then
          end if;
          rddata_reg(31 downto 0) <= regs_i.wdiag_temp_i;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when others =>
-- prevent the slave from hanging the bus on invalid address
          ack_in_progress <= '1';
          ack_sreg(0) <= '1';
        end case;
      end if;
    end if;
  end if;
end process;


-- Drive the data output bus
wb_dat_o <= rddata_reg;
-- Version identifier
regs_o.ver_id_o <= wrc_diags_ver_id_int;
-- WR DIAG data valid
-- WR DIAG data snapshot
regs_o.ctrl_data_snapshot_o <= wrc_diags_ctrl_data_snapshot_int;
-- WR valid
-- Servo State
-- Link Status
-- PLL Locked
-- PTP State
-- AUX channel
-- Data
-- Data
-- Data
-- Data
-- Data
-- Data
-- Data
-- Data
-- Data
-- Data
-- Data
-- Data
-- Data
-- Data
rwaddr_reg <= wb_adr_i;
wb_stall_o <= (not ack_sreg(0)) and (wb_stb_i and wb_cyc_i);
wb_err_o <= '0';
wb_rty_o <= '0';
-- ACK signal generation. Just pass the LSB of ACK counter.
wb_ack_o <= ack_sreg(0);
end syn;

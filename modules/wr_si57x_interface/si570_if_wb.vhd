---------------------------------------------------------------------------------------
-- Title          : Wishbone slave core for silabs interface
---------------------------------------------------------------------------------------
-- File           : si570_if_wb.vhd
-- Author         : auto-generated by wbgen2 from si570_if_wb.wb
-- Created        : Tue Jan 26 15:18:39 2021
-- Standard       : VHDL'87
---------------------------------------------------------------------------------------
-- THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE si570_if_wb.wb
-- DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.si570_wbgen2_pkg.all;


entity si570_if_wb is
port (
  rst_n_i                                  : in     std_logic;
  clk_sys_i                                : in     std_logic;
  wb_adr_i                                 : in     std_logic_vector(2 downto 0);
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
  regs_i                                   : in     t_si570_in_registers;
  regs_o                                   : out    t_si570_out_registers
);
end si570_if_wb;

architecture syn of si570_if_wb is

signal si570_cr_i2c_addr_int                    : std_logic_vector(7 downto 0);
signal si570_cr_enable_int                      : std_logic      ;
signal si570_cr_gain_int                        : std_logic_vector(7 downto 0);
signal si570_cr_clk_div_int                     : std_logic_vector(7 downto 0);
signal si570_rfreql_int                         : std_logic_vector(31 downto 0);
signal si570_rfreqh_int                         : std_logic_vector(31 downto 0);
signal si570_gpcr_scl_dly0                      : std_logic      ;
signal si570_gpcr_scl_int                       : std_logic      ;
signal si570_gpcr_sda_dly0                      : std_logic      ;
signal si570_gpcr_sda_int                       : std_logic      ;
signal ack_sreg                                 : std_logic_vector(9 downto 0);
signal rddata_reg                               : std_logic_vector(31 downto 0);
signal wrdata_reg                               : std_logic_vector(31 downto 0);
signal bwsel_reg                                : std_logic_vector(3 downto 0);
signal rwaddr_reg                               : std_logic_vector(2 downto 0);
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
    si570_cr_i2c_addr_int <= "00000000";
    si570_cr_enable_int <= '0';
    si570_cr_gain_int <= "00000000";
    si570_cr_clk_div_int <= "00000000";
    si570_rfreql_int <= "00000000000000000000000000000000";
    si570_rfreqh_int <= "00000000000000000000000000000000";
    regs_o.gpsr_scl_load_o <= '0';
    regs_o.gpsr_sda_load_o <= '0';
    si570_gpcr_scl_int <= '0';
    si570_gpcr_sda_int <= '0';
  elsif rising_edge(clk_sys_i) then
-- advance the ACK generator shift register
    ack_sreg(8 downto 0) <= ack_sreg(9 downto 1);
    ack_sreg(9) <= '0';
    if (ack_in_progress = '1') then
      if (ack_sreg(0) = '1') then
        regs_o.gpsr_scl_load_o <= '0';
        regs_o.gpsr_sda_load_o <= '0';
        si570_gpcr_scl_int <= '0';
        si570_gpcr_sda_int <= '0';
        ack_in_progress <= '0';
      else
        regs_o.gpsr_scl_load_o <= '0';
        regs_o.gpsr_sda_load_o <= '0';
      end if;
    else
      if ((wb_cyc_i = '1') and (wb_stb_i = '1')) then
        case rwaddr_reg(2 downto 0) is
        when "000" => 
          if (wb_we_i = '1') then
            si570_cr_i2c_addr_int <= wrdata_reg(7 downto 0);
            si570_cr_enable_int <= wrdata_reg(8);
            si570_cr_gain_int <= wrdata_reg(16 downto 9);
            si570_cr_clk_div_int <= wrdata_reg(24 downto 17);
          end if;
          rddata_reg(7 downto 0) <= si570_cr_i2c_addr_int;
          rddata_reg(8) <= si570_cr_enable_int;
          rddata_reg(16 downto 9) <= si570_cr_gain_int;
          rddata_reg(24 downto 17) <= si570_cr_clk_div_int;
          rddata_reg(25) <= regs_i.cr_busy_i;
          rddata_reg(26) <= 'X';
          rddata_reg(27) <= 'X';
          rddata_reg(28) <= 'X';
          rddata_reg(29) <= 'X';
          rddata_reg(30) <= 'X';
          rddata_reg(31) <= 'X';
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "001" => 
          if (wb_we_i = '1') then
            si570_rfreql_int <= wrdata_reg(31 downto 0);
          end if;
          rddata_reg(31 downto 0) <= si570_rfreql_int;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "010" => 
          if (wb_we_i = '1') then
            si570_rfreqh_int <= wrdata_reg(31 downto 0);
          end if;
          rddata_reg(31 downto 0) <= si570_rfreqh_int;
          ack_sreg(0) <= '1';
          ack_in_progress <= '1';
        when "011" => 
          if (wb_we_i = '1') then
            regs_o.gpsr_scl_load_o <= '1';
            regs_o.gpsr_sda_load_o <= '1';
          end if;
          rddata_reg(0) <= regs_i.gpsr_scl_i;
          rddata_reg(1) <= regs_i.gpsr_sda_i;
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
        when "100" => 
          if (wb_we_i = '1') then
            si570_gpcr_scl_int <= wrdata_reg(0);
            si570_gpcr_sda_int <= wrdata_reg(1);
          end if;
          rddata_reg(0) <= '0';
          rddata_reg(1) <= '0';
          rddata_reg(0) <= 'X';
          rddata_reg(1) <= 'X';
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
          ack_sreg(2) <= '1';
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
-- Si57x Address
regs_o.cr_i2c_addr_o <= si570_cr_i2c_addr_int;
-- Si57x SPLL input enable
regs_o.cr_enable_o <= si570_cr_enable_int;
-- RFREQ gain/scalefactor
regs_o.cr_gain_o <= si570_cr_gain_int;
-- I2C Clock Divider
regs_o.cr_clk_div_o <= si570_cr_clk_div_int;
-- Si57x I/F Busy
-- RFREQ low part
regs_o.rfreql_o <= si570_rfreql_int;
-- RFREQ hi part
regs_o.rfreqh_o <= si570_rfreqh_int;
-- SIlabs I2C bitbanged SCL
regs_o.gpsr_scl_o <= wrdata_reg(0);
-- SIlabs I2C bitbanged SDA
regs_o.gpsr_sda_o <= wrdata_reg(1);
-- SILabs I2C bitbanged SCL
process (clk_sys_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    si570_gpcr_scl_dly0 <= '0';
    regs_o.gpcr_scl_o <= '0';
  elsif rising_edge(clk_sys_i) then
    si570_gpcr_scl_dly0 <= si570_gpcr_scl_int;
    regs_o.gpcr_scl_o <= si570_gpcr_scl_int and (not si570_gpcr_scl_dly0);
  end if;
end process;


-- SIlabs I2C bitbanged SDA
process (clk_sys_i, rst_n_i)
begin
  if (rst_n_i = '0') then 
    si570_gpcr_sda_dly0 <= '0';
    regs_o.gpcr_sda_o <= '0';
  elsif rising_edge(clk_sys_i) then
    si570_gpcr_sda_dly0 <= si570_gpcr_sda_int;
    regs_o.gpcr_sda_o <= si570_gpcr_sda_int and (not si570_gpcr_sda_dly0);
  end if;
end process;


rwaddr_reg <= wb_adr_i;
wb_stall_o <= (not ack_sreg(0)) and (wb_stb_i and wb_cyc_i);
wb_err_o <= '0';
wb_rty_o <= '0';
-- ACK signal generation. Just pass the LSB of ACK counter.
wb_ack_o <= ack_sreg(0);
end syn;

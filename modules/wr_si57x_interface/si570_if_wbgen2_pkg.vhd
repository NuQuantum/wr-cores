---------------------------------------------------------------------------------------
-- Title          : Wishbone slave core for silabs interface
---------------------------------------------------------------------------------------
-- File           : si570_if_wbgen2_pkg.vhd
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

package si570_wbgen2_pkg is
  
  
  -- Input registers (user design -> WB slave)
  
  type t_si570_in_registers is record
    cr_busy_i                                : std_logic;
    gpsr_scl_i                               : std_logic;
    gpsr_sda_i                               : std_logic;
  end record;
  
  constant c_si570_in_registers_init_value: t_si570_in_registers := (
    cr_busy_i => '0',
    gpsr_scl_i => '0',
    gpsr_sda_i => '0'
  );
  
  -- Output registers (WB slave -> user design)
  
  type t_si570_out_registers is record
    cr_i2c_addr_o                            : std_logic_vector(7 downto 0);
    cr_enable_o                              : std_logic;
    cr_gain_o                                : std_logic_vector(7 downto 0);
    cr_clk_div_o                             : std_logic_vector(7 downto 0);
    rfreql_o                                 : std_logic_vector(31 downto 0);
    rfreqh_o                                 : std_logic_vector(31 downto 0);
    gpsr_scl_o                               : std_logic;
    gpsr_scl_load_o                          : std_logic;
    gpsr_sda_o                               : std_logic;
    gpsr_sda_load_o                          : std_logic;
    gpcr_scl_o                               : std_logic;
    gpcr_sda_o                               : std_logic;
  end record;
  
  constant c_si570_out_registers_init_value: t_si570_out_registers := (
    cr_i2c_addr_o => (others => '0'),
    cr_enable_o => '0',
    cr_gain_o => (others => '0'),
    cr_clk_div_o => (others => '0'),
    rfreql_o => (others => '0'),
    rfreqh_o => (others => '0'),
    gpsr_scl_o => '0',
    gpsr_scl_load_o => '0',
    gpsr_sda_o => '0',
    gpsr_sda_load_o => '0',
    gpcr_scl_o => '0',
    gpcr_sda_o => '0'
  );

function "or" (left, right: t_si570_in_registers) return t_si570_in_registers;
function f_x_to_zero (x:std_logic) return std_logic;
function f_x_to_zero (x:std_logic_vector) return std_logic_vector;

component si570_if_wb is
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
end component;

end package;

package body si570_wbgen2_pkg is
function f_x_to_zero (x:std_logic) return std_logic is
begin
  if x = '1' then
    return '1';
  else
    return '0';
  end if;
end function;

function f_x_to_zero (x:std_logic_vector) return std_logic_vector is
  variable tmp: std_logic_vector(x'length-1 downto 0);
begin
  for i in 0 to x'length-1 loop
    if(x(i) = 'X' or x(i) = 'U') then
      tmp(i):= '0';
    else
      tmp(i):=x(i);
    end if; 
  end loop; 
  return tmp;
end function;

function "or" (left, right: t_si570_in_registers) return t_si570_in_registers is
  variable tmp: t_si570_in_registers;
begin
  tmp.cr_busy_i := f_x_to_zero(left.cr_busy_i) or f_x_to_zero(right.cr_busy_i);
  tmp.gpsr_scl_i := f_x_to_zero(left.gpsr_scl_i) or f_x_to_zero(right.gpsr_scl_i);
  tmp.gpsr_sda_i := f_x_to_zero(left.gpsr_sda_i) or f_x_to_zero(right.gpsr_sda_i);
  return tmp;
end function;

end package body;

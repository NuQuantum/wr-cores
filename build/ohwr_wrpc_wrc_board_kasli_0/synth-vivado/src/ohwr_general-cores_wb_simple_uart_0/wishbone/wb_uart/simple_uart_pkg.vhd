---------------------------------------------------------------------------------------
-- Title          : Wishbone slave core for Simple Wishbone UART
---------------------------------------------------------------------------------------
-- File           : simple_uart_pkg.vhd
-- Author         : auto-generated by wbgen2 from simple_uart_wb.wb
-- Created        : Fri Jan 26 16:35:06 2024
-- Standard       : VHDL'87
---------------------------------------------------------------------------------------
-- THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE simple_uart_wb.wb
-- DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package uart_wbgen2_pkg is
  
  
  -- Input registers (user design -> WB slave)
  
  type t_uart_in_registers is record
    sr_tx_busy_i                             : std_logic;
    sr_rx_rdy_i                              : std_logic;
    sr_rx_fifo_supported_i                   : std_logic;
    sr_tx_fifo_supported_i                   : std_logic;
    sr_rx_fifo_valid_i                       : std_logic;
    sr_tx_fifo_empty_i                       : std_logic;
    sr_tx_fifo_full_i                        : std_logic;
    sr_rx_fifo_overflow_i                    : std_logic;
    sr_rx_fifo_bytes_i                       : std_logic_vector(15 downto 0);
    sr_physical_uart_i                       : std_logic;
    sr_virtual_uart_i                        : std_logic;
    rdr_rx_data_i                            : std_logic_vector(7 downto 0);
    host_tdr_rdy_i                           : std_logic;
    host_rdr_data_i                          : std_logic_vector(7 downto 0);
    host_rdr_rdy_i                           : std_logic;
    host_rdr_count_i                         : std_logic_vector(15 downto 0);
  end record;
  
  constant c_uart_in_registers_init_value: t_uart_in_registers := (
    sr_tx_busy_i => '0',
    sr_rx_rdy_i => '0',
    sr_rx_fifo_supported_i => '0',
    sr_tx_fifo_supported_i => '0',
    sr_rx_fifo_valid_i => '0',
    sr_tx_fifo_empty_i => '0',
    sr_tx_fifo_full_i => '0',
    sr_rx_fifo_overflow_i => '0',
    sr_rx_fifo_bytes_i => (others => '0'),
    sr_physical_uart_i => '0',
    sr_virtual_uart_i => '0',
    rdr_rx_data_i => (others => '0'),
    host_tdr_rdy_i => '0',
    host_rdr_data_i => (others => '0'),
    host_rdr_rdy_i => '0',
    host_rdr_count_i => (others => '0')
  );
  
  -- Output registers (WB slave -> user design)
  
  type t_uart_out_registers is record
    sr_rx_fifo_overflow_o                    : std_logic;
    sr_rx_fifo_overflow_load_o               : std_logic;
    bcr_o                                    : std_logic_vector(31 downto 0);
    bcr_wr_o                                 : std_logic;
    tdr_tx_data_o                            : std_logic_vector(7 downto 0);
    tdr_tx_data_wr_o                         : std_logic;
    host_tdr_data_o                          : std_logic_vector(7 downto 0);
    host_tdr_data_wr_o                       : std_logic;
    cr_rx_fifo_purge_o                       : std_logic;
    cr_tx_fifo_purge_o                       : std_logic;
    cr_rx_interrupt_enable_o                 : std_logic;
    cr_tx_interrupt_enable_o                 : std_logic;
  end record;
  
  constant c_uart_out_registers_init_value: t_uart_out_registers := (
    sr_rx_fifo_overflow_o => '0',
    sr_rx_fifo_overflow_load_o => '0',
    bcr_o => (others => '0'),
    bcr_wr_o => '0',
    tdr_tx_data_o => (others => '0'),
    tdr_tx_data_wr_o => '0',
    host_tdr_data_o => (others => '0'),
    host_tdr_data_wr_o => '0',
    cr_rx_fifo_purge_o => '0',
    cr_tx_fifo_purge_o => '0',
    cr_rx_interrupt_enable_o => '0',
    cr_tx_interrupt_enable_o => '0'
  );
  
  function "or" (left, right: t_uart_in_registers) return t_uart_in_registers;
  function f_x_to_zero (x:std_logic) return std_logic;
  function f_x_to_zero (x:std_logic_vector) return std_logic_vector;
  
  component simple_uart_wb is
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
      rdr_rack_o                               : out    std_logic;
      host_rack_o                              : out    std_logic;
      regs_i                                   : in     t_uart_in_registers;
      regs_o                                   : out    t_uart_out_registers
    );
  end component;
  
end package;

package body uart_wbgen2_pkg is
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
      if(x(i) = '1') then
        tmp(i):= '1';
      else
        tmp(i):= '0';
      end if; 
    end loop; 
    return tmp;
  end function;
  
  function "or" (left, right: t_uart_in_registers) return t_uart_in_registers is
    variable tmp: t_uart_in_registers;
  begin
    tmp.sr_tx_busy_i := f_x_to_zero(left.sr_tx_busy_i) or f_x_to_zero(right.sr_tx_busy_i);
    tmp.sr_rx_rdy_i := f_x_to_zero(left.sr_rx_rdy_i) or f_x_to_zero(right.sr_rx_rdy_i);
    tmp.sr_rx_fifo_supported_i := f_x_to_zero(left.sr_rx_fifo_supported_i) or f_x_to_zero(right.sr_rx_fifo_supported_i);
    tmp.sr_tx_fifo_supported_i := f_x_to_zero(left.sr_tx_fifo_supported_i) or f_x_to_zero(right.sr_tx_fifo_supported_i);
    tmp.sr_rx_fifo_valid_i := f_x_to_zero(left.sr_rx_fifo_valid_i) or f_x_to_zero(right.sr_rx_fifo_valid_i);
    tmp.sr_tx_fifo_empty_i := f_x_to_zero(left.sr_tx_fifo_empty_i) or f_x_to_zero(right.sr_tx_fifo_empty_i);
    tmp.sr_tx_fifo_full_i := f_x_to_zero(left.sr_tx_fifo_full_i) or f_x_to_zero(right.sr_tx_fifo_full_i);
    tmp.sr_rx_fifo_overflow_i := f_x_to_zero(left.sr_rx_fifo_overflow_i) or f_x_to_zero(right.sr_rx_fifo_overflow_i);
    tmp.sr_rx_fifo_bytes_i := f_x_to_zero(left.sr_rx_fifo_bytes_i) or f_x_to_zero(right.sr_rx_fifo_bytes_i);
    tmp.sr_physical_uart_i := f_x_to_zero(left.sr_physical_uart_i) or f_x_to_zero(right.sr_physical_uart_i);
    tmp.sr_virtual_uart_i := f_x_to_zero(left.sr_virtual_uart_i) or f_x_to_zero(right.sr_virtual_uart_i);
    tmp.rdr_rx_data_i := f_x_to_zero(left.rdr_rx_data_i) or f_x_to_zero(right.rdr_rx_data_i);
    tmp.host_tdr_rdy_i := f_x_to_zero(left.host_tdr_rdy_i) or f_x_to_zero(right.host_tdr_rdy_i);
    tmp.host_rdr_data_i := f_x_to_zero(left.host_rdr_data_i) or f_x_to_zero(right.host_rdr_data_i);
    tmp.host_rdr_rdy_i := f_x_to_zero(left.host_rdr_rdy_i) or f_x_to_zero(right.host_rdr_rdy_i);
    tmp.host_rdr_count_i := f_x_to_zero(left.host_rdr_count_i) or f_x_to_zero(right.host_rdr_count_i);
    return tmp;
  end function;

end package body;
---------------------------------------------------------------------------------------
-- Title          : Wishbone slave core for White Rabbit Switch NIC's spec
---------------------------------------------------------------------------------------
-- File           : nic_wishbone_slave.vhd
-- Author         : auto-generated by wbgen2 from wr_nic.wb
-- Created        : Mon Aug  1 16:03:57 2016
-- Standard       : VHDL'87
---------------------------------------------------------------------------------------
-- THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE wr_nic.wb
-- DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wbgen2_pkg.all;

use work.nic_wbgen2_pkg.all;


entity nic_wishbone_slave is
  port (
    rst_n_i                                  : in     std_logic;
    clk_sys_i                                : in     std_logic;
    wb_adr_i                                 : in     std_logic_vector(6 downto 0);
    wb_dat_i                                 : in     std_logic_vector(31 downto 0);
    wb_dat_o                                 : out    std_logic_vector(31 downto 0);
    wb_cyc_i                                 : in     std_logic;
    wb_sel_i                                 : in     std_logic_vector(3 downto 0);
    wb_stb_i                                 : in     std_logic;
    wb_we_i                                  : in     std_logic;
    wb_ack_o                                 : out    std_logic;
    wb_stall_o                               : out    std_logic;
    wb_int_o                                 : out    std_logic;
    irq_rcomp_i                              : in     std_logic;
    irq_rcomp_ack_o                          : out    std_logic;
    irq_tcomp_i                              : in     std_logic;
    irq_tcomp_ack_o                          : out    std_logic;
    irq_tcomp_mask_o                         : out    std_logic;
    irq_txerr_i                              : in     std_logic;
    irq_txerr_ack_o                          : out    std_logic;
    irq_txerr_mask_o                         : out    std_logic;
-- Ports for RAM: TX descriptors mem
    nic_dtx_addr_i                           : in     std_logic_vector(4 downto 0);
-- Read data output
    nic_dtx_data_o                           : out    std_logic_vector(31 downto 0);
-- Read strobe input (active high)
    nic_dtx_rd_i                             : in     std_logic;
-- Write data input
    nic_dtx_data_i                           : in     std_logic_vector(31 downto 0);
-- Write strobe (active high)
    nic_dtx_wr_i                             : in     std_logic;
-- Ports for RAM: RX descriptors mem
    nic_drx_addr_i                           : in     std_logic_vector(4 downto 0);
-- Read data output
    nic_drx_data_o                           : out    std_logic_vector(31 downto 0);
-- Read strobe input (active high)
    nic_drx_rd_i                             : in     std_logic;
-- Write data input
    nic_drx_data_i                           : in     std_logic_vector(31 downto 0);
-- Write strobe (active high)
    nic_drx_wr_i                             : in     std_logic;
    regs_i                                   : in     t_nic_in_registers;
    regs_o                                   : out    t_nic_out_registers
  );
end nic_wishbone_slave;

architecture syn of nic_wishbone_slave is

signal nic_cr_rx_en_int                         : std_logic      ;
signal nic_cr_tx_en_int                         : std_logic      ;
signal nic_cr_sw_rst_dly0                       : std_logic      ;
signal nic_cr_sw_rst_int                        : std_logic      ;
signal nic_dtx_rddata_int                       : std_logic_vector(31 downto 0);
signal nic_dtx_rd_int                           : std_logic      ;
signal nic_dtx_wr_int                           : std_logic      ;
signal nic_drx_rddata_int                       : std_logic_vector(31 downto 0);
signal nic_drx_rd_int                           : std_logic      ;
signal nic_drx_wr_int                           : std_logic      ;
signal eic_idr_int                              : std_logic_vector(2 downto 0);
signal eic_idr_write_int                        : std_logic      ;
signal eic_ier_int                              : std_logic_vector(2 downto 0);
signal eic_ier_write_int                        : std_logic      ;
signal eic_imr_int                              : std_logic_vector(2 downto 0);
signal eic_isr_clear_int                        : std_logic_vector(2 downto 0);
signal eic_isr_status_int                       : std_logic_vector(2 downto 0);
signal eic_irq_ack_int                          : std_logic_vector(2 downto 0);
signal eic_isr_write_int                        : std_logic      ;
signal irq_inputs_vector_int                    : std_logic_vector(2 downto 0);
signal ack_sreg                                 : std_logic_vector(9 downto 0);
signal rddata_reg                               : std_logic_vector(31 downto 0);
signal wrdata_reg                               : std_logic_vector(31 downto 0);
signal bwsel_reg                                : std_logic_vector(3 downto 0);
signal rwaddr_reg                               : std_logic_vector(6 downto 0);
signal ack_in_progress                          : std_logic      ;
signal wr_int                                   : std_logic      ;
signal rd_int                                   : std_logic      ;
signal allones                                  : std_logic_vector(31 downto 0);
signal allzeros                                 : std_logic_vector(31 downto 0);

begin
-- Some internal signals assignments. For (foreseen) compatibility with other bus standards.
  wrdata_reg <= wb_dat_i;
  bwsel_reg <= wb_sel_i;
  rd_int <= wb_cyc_i and (wb_stb_i and (not wb_we_i));
  wr_int <= wb_cyc_i and (wb_stb_i and wb_we_i);
  allones <= (others => '1');
  allzeros <= (others => '0');
-- 
-- Main register bank access process.
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then 
      ack_sreg <= "0000000000";
      ack_in_progress <= '0';
      rddata_reg <= "00000000000000000000000000000000";
      nic_cr_rx_en_int <= '0';
      nic_cr_tx_en_int <= '0';
      nic_cr_sw_rst_int <= '0';
      regs_o.sr_rec_load_o <= '0';
      regs_o.sr_tx_done_load_o <= '0';
      regs_o.sr_tx_error_load_o <= '0';
      regs_o.maxrxbw_load_o <= '0';
      eic_idr_write_int <= '0';
      eic_ier_write_int <= '0';
      eic_isr_write_int <= '0';
    elsif rising_edge(clk_sys_i) then
-- advance the ACK generator shift register
      ack_sreg(8 downto 0) <= ack_sreg(9 downto 1);
      ack_sreg(9) <= '0';
      if (ack_in_progress = '1') then
        if (ack_sreg(0) = '1') then
          nic_cr_sw_rst_int <= '0';
          regs_o.sr_rec_load_o <= '0';
          regs_o.sr_tx_done_load_o <= '0';
          regs_o.sr_tx_error_load_o <= '0';
          regs_o.maxrxbw_load_o <= '0';
          eic_idr_write_int <= '0';
          eic_ier_write_int <= '0';
          eic_isr_write_int <= '0';
          ack_in_progress <= '0';
        else
          regs_o.sr_rec_load_o <= '0';
          regs_o.sr_tx_done_load_o <= '0';
          regs_o.sr_tx_error_load_o <= '0';
          regs_o.maxrxbw_load_o <= '0';
        end if;
      else
        if ((wb_cyc_i = '1') and (wb_stb_i = '1')) then
          case rwaddr_reg(6 downto 5) is
          when "00" => 
            case rwaddr_reg(3 downto 0) is
            when "0000" => 
              if (wb_we_i = '1') then
                nic_cr_rx_en_int <= wrdata_reg(0);
                nic_cr_tx_en_int <= wrdata_reg(1);
                nic_cr_sw_rst_int <= wrdata_reg(31);
              end if;
              rddata_reg(0) <= nic_cr_rx_en_int;
              rddata_reg(1) <= nic_cr_tx_en_int;
              rddata_reg(31) <= '0';
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
              ack_sreg(2) <= '1';
              ack_in_progress <= '1';
            when "0001" => 
              if (wb_we_i = '1') then
                regs_o.sr_rec_load_o <= '1';
                regs_o.sr_tx_done_load_o <= '1';
                regs_o.sr_tx_error_load_o <= '1';
              end if;
              rddata_reg(0) <= regs_i.sr_bna_i;
              rddata_reg(1) <= regs_i.sr_rec_i;
              rddata_reg(2) <= regs_i.sr_tx_done_i;
              rddata_reg(3) <= regs_i.sr_tx_error_i;
              rddata_reg(10 downto 8) <= regs_i.sr_cur_tx_desc_i;
              rddata_reg(18 downto 16) <= regs_i.sr_cur_rx_desc_i;
              rddata_reg(4) <= 'X';
              rddata_reg(5) <= 'X';
              rddata_reg(6) <= 'X';
              rddata_reg(7) <= 'X';
              rddata_reg(11) <= 'X';
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
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
            when "0010" => 
              if (wb_we_i = '1') then
              end if;
              rddata_reg(31 downto 0) <= regs_i.rxbw_i;
              ack_sreg(0) <= '1';
              ack_in_progress <= '1';
            when "0011" => 
              if (wb_we_i = '1') then
                regs_o.maxrxbw_load_o <= '1';
              end if;
              rddata_reg(15 downto 0) <= regs_i.maxrxbw_i;
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
            when "1000" => 
              if (wb_we_i = '1') then
                eic_idr_write_int <= '1';
              end if;
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
              ack_sreg(0) <= '1';
              ack_in_progress <= '1';
            when "1001" => 
              if (wb_we_i = '1') then
                eic_ier_write_int <= '1';
              end if;
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
              ack_sreg(0) <= '1';
              ack_in_progress <= '1';
            when "1010" => 
              if (wb_we_i = '1') then
              end if;
              rddata_reg(2 downto 0) <= eic_imr_int(2 downto 0);
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
            when "1011" => 
              if (wb_we_i = '1') then
                eic_isr_write_int <= '1';
              end if;
              rddata_reg(2 downto 0) <= eic_isr_status_int(2 downto 0);
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
            when others =>
-- prevent the slave from hanging the bus on invalid address
              ack_in_progress <= '1';
              ack_sreg(0) <= '1';
            end case;
          when "01" => 
            if (rd_int = '1') then
              ack_sreg(0) <= '1';
            else
              ack_sreg(0) <= '1';
            end if;
            ack_in_progress <= '1';
          when "10" => 
            if (rd_int = '1') then
              ack_sreg(0) <= '1';
            else
              ack_sreg(0) <= '1';
            end if;
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
  
  
-- Data output multiplexer process
  process (rddata_reg, rwaddr_reg, nic_dtx_rddata_int, nic_drx_rddata_int, wb_adr_i  )
  begin
    case rwaddr_reg(6 downto 5) is
    when "01" => 
      wb_dat_o(31 downto 0) <= nic_dtx_rddata_int;
    when "10" => 
      wb_dat_o(31 downto 0) <= nic_drx_rddata_int;
    when others =>
      wb_dat_o <= rddata_reg;
    end case;
  end process;
  
  
-- Read & write lines decoder for RAMs
  process (wb_adr_i, rd_int, wr_int  )
  begin
    if (wb_adr_i(6 downto 5) = "01") then
      nic_dtx_rd_int <= rd_int;
      nic_dtx_wr_int <= wr_int;
    else
      nic_dtx_wr_int <= '0';
      nic_dtx_rd_int <= '0';
    end if;
    if (wb_adr_i(6 downto 5) = "10") then
      nic_drx_rd_int <= rd_int;
      nic_drx_wr_int <= wr_int;
    else
      nic_drx_wr_int <= '0';
      nic_drx_rd_int <= '0';
    end if;
  end process;
  
  
-- Receive enable
  regs_o.cr_rx_en_o <= nic_cr_rx_en_int;
-- Transmit enable
  regs_o.cr_tx_en_o <= nic_cr_tx_en_int;
-- Software Reset
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then 
      nic_cr_sw_rst_dly0 <= '0';
      regs_o.cr_sw_rst_o <= '0';
    elsif rising_edge(clk_sys_i) then
      nic_cr_sw_rst_dly0 <= nic_cr_sw_rst_int;
      regs_o.cr_sw_rst_o <= nic_cr_sw_rst_int and (not nic_cr_sw_rst_dly0);
    end if;
  end process;
  
  
-- Buffer Not Available
-- Frame Received
  regs_o.sr_rec_o <= wrdata_reg(1);
-- Transmission done
  regs_o.sr_tx_done_o <= wrdata_reg(2);
-- Transmission error
  regs_o.sr_tx_error_o <= wrdata_reg(3);
-- Current TX descriptor
-- Current RX descriptor
-- Bytes-per-second
-- KBytes-per-second
  regs_o.maxrxbw_o <= wrdata_reg(15 downto 0);
-- extra code for reg/fifo/mem: TX descriptors mem
-- RAM block instantiation for memory: TX descriptors mem
  nic_dtx_raminst : wbgen2_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 32,
      g_addr_width         => 5,
      g_dual_clock         => false,
      g_use_bwsel          => false
    )
    port map (
      clk_a_i              => clk_sys_i,
      clk_b_i              => clk_sys_i,
      addr_b_i             => nic_dtx_addr_i,
      addr_a_i             => rwaddr_reg(4 downto 0),
      data_b_o             => nic_dtx_data_o,
      rd_b_i               => nic_dtx_rd_i,
      data_b_i             => nic_dtx_data_i,
      wr_b_i               => nic_dtx_wr_i,
      bwsel_b_i            => allones(3 downto 0),
      data_a_o             => nic_dtx_rddata_int(31 downto 0),
      rd_a_i               => nic_dtx_rd_int,
      data_a_i             => wrdata_reg(31 downto 0),
      wr_a_i               => nic_dtx_wr_int,
      bwsel_a_i            => allones(3 downto 0)
    );
  
-- extra code for reg/fifo/mem: RX descriptors mem
-- RAM block instantiation for memory: RX descriptors mem
  nic_drx_raminst : wbgen2_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 32,
      g_addr_width         => 5,
      g_dual_clock         => false,
      g_use_bwsel          => false
    )
    port map (
      clk_a_i              => clk_sys_i,
      clk_b_i              => clk_sys_i,
      addr_b_i             => nic_drx_addr_i,
      addr_a_i             => rwaddr_reg(4 downto 0),
      data_b_o             => nic_drx_data_o,
      rd_b_i               => nic_drx_rd_i,
      data_b_i             => nic_drx_data_i,
      wr_b_i               => nic_drx_wr_i,
      bwsel_b_i            => allones(3 downto 0),
      data_a_o             => nic_drx_rddata_int(31 downto 0),
      rd_a_i               => nic_drx_rd_int,
      data_a_i             => wrdata_reg(31 downto 0),
      wr_a_i               => nic_drx_wr_int,
      bwsel_a_i            => allones(3 downto 0)
    );
  
-- extra code for reg/fifo/mem: Interrupt disable register
  eic_idr_int(2 downto 0) <= wrdata_reg(2 downto 0);
-- extra code for reg/fifo/mem: Interrupt enable register
  eic_ier_int(2 downto 0) <= wrdata_reg(2 downto 0);
-- extra code for reg/fifo/mem: Interrupt status register
  eic_isr_clear_int(2 downto 0) <= wrdata_reg(2 downto 0);
-- extra code for reg/fifo/mem: IRQ_CONTROLLER
  eic_irq_controller_inst : wbgen2_eic
    generic map (
      g_num_interrupts     => 3,
      g_irq00_mode         => 3,
      g_irq01_mode         => 3,
      g_irq02_mode         => 3,
      g_irq03_mode         => 0,
      g_irq04_mode         => 0,
      g_irq05_mode         => 0,
      g_irq06_mode         => 0,
      g_irq07_mode         => 0,
      g_irq08_mode         => 0,
      g_irq09_mode         => 0,
      g_irq0a_mode         => 0,
      g_irq0b_mode         => 0,
      g_irq0c_mode         => 0,
      g_irq0d_mode         => 0,
      g_irq0e_mode         => 0,
      g_irq0f_mode         => 0,
      g_irq10_mode         => 0,
      g_irq11_mode         => 0,
      g_irq12_mode         => 0,
      g_irq13_mode         => 0,
      g_irq14_mode         => 0,
      g_irq15_mode         => 0,
      g_irq16_mode         => 0,
      g_irq17_mode         => 0,
      g_irq18_mode         => 0,
      g_irq19_mode         => 0,
      g_irq1a_mode         => 0,
      g_irq1b_mode         => 0,
      g_irq1c_mode         => 0,
      g_irq1d_mode         => 0,
      g_irq1e_mode         => 0,
      g_irq1f_mode         => 0
    )
    port map (
      clk_i                => clk_sys_i,
      rst_n_i              => rst_n_i,
      irq_i                => irq_inputs_vector_int,
      irq_ack_o            => eic_irq_ack_int,
      reg_imr_o            => eic_imr_int,
      reg_ier_i            => eic_ier_int,
      reg_ier_wr_stb_i     => eic_ier_write_int,
      reg_idr_i            => eic_idr_int,
      reg_idr_wr_stb_i     => eic_idr_write_int,
      reg_isr_o            => eic_isr_status_int,
      reg_isr_i            => eic_isr_clear_int,
      reg_isr_wr_stb_i     => eic_isr_write_int,
      wb_irq_o             => wb_int_o
    );
  
  irq_inputs_vector_int(0) <= irq_rcomp_i;
  irq_rcomp_ack_o <= eic_irq_ack_int(0);
  irq_inputs_vector_int(1) <= irq_tcomp_i;
  irq_tcomp_ack_o <= eic_irq_ack_int(1);
  irq_tcomp_mask_o <= eic_imr_int(1);
  irq_inputs_vector_int(2) <= irq_txerr_i;
  irq_txerr_ack_o <= eic_irq_ack_int(2);
  irq_txerr_mask_o <= eic_imr_int(2);
  rwaddr_reg <= wb_adr_i;
  wb_stall_o <= (not ack_sreg(0)) and (wb_stb_i and wb_cyc_i);
-- ACK signal generation. Just pass the LSB of ACK counter.
  wb_ack_o <= ack_sreg(0);
end syn;

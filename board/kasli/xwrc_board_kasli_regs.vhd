-- Do not edit.  Generated by cheby 1.6.0rc1 using these options:
--  --gen-hdl=xwrc_board_kasli_regs.vhd -i xwrc_board_kasli.cheby
-- Generated on Thu Oct 10 18:09:59 2024 by jfoley


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package xwrc_board_kasli_regs_pkg is
  type t_wrpc_kasli_regs_master_out is record
    RESET_WRPC_CORE  : std_logic;
    SYSTEM_CLOCK_SELECT : std_logic;
  end record t_wrpc_kasli_regs_master_out;
  subtype t_wrpc_kasli_regs_slave_in is t_wrpc_kasli_regs_master_out;

end xwrc_board_kasli_regs_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.xwrc_board_kasli_regs_pkg.all;

entity xwrc_board_kasli_regs is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(2 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);
    -- Wires and registers
    wrpc_kasli_regs_o    : out   t_wrpc_kasli_regs_master_out
  );
end xwrc_board_kasli_regs;

architecture syn of xwrc_board_kasli_regs is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal RESET_WRPC_CORE_reg            : std_logic;
  signal RESET_wreq                     : std_logic;
  signal RESET_wack                     : std_logic;
  signal SYSTEM_CLOCK_SELECT_reg        : std_logic;
  signal SYSTEM_CLOCK_wreq              : std_logic;
  signal SYSTEM_CLOCK_wack              : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(2 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
begin

  -- WB decode signals
  wb_en <= wb_cyc_i and wb_stb_i;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_we_i)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_we_i) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_we_i)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_we_i) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_ack_o <= ack_int;
  wb_stall_o <= not ack_int and wb_en;
  wb_rty_o <= '0';
  wb_err_o <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wb_dat_o <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "0";
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
      end if;
    end if;
  end process;

  -- Register RESET
  wrpc_kasli_regs_o.RESET_WRPC_CORE <= RESET_WRPC_CORE_reg;
  RESET_wack <= RESET_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        RESET_WRPC_CORE_reg <= '1';
      else
        if RESET_wreq = '1' then
          RESET_WRPC_CORE_reg <= wr_dat_d0(0);
        end if;
      end if;
    end if;
  end process;

  -- Register SYSTEM_CLOCK
  wrpc_kasli_regs_o.SYSTEM_CLOCK_SELECT <= SYSTEM_CLOCK_SELECT_reg;
  SYSTEM_CLOCK_wack <= SYSTEM_CLOCK_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        SYSTEM_CLOCK_SELECT_reg <= '0';
      else
        if SYSTEM_CLOCK_wreq = '1' then
          SYSTEM_CLOCK_SELECT_reg <= wr_dat_d0(0);
        end if;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, RESET_wack, SYSTEM_CLOCK_wack) begin
    RESET_wreq <= '0';
    SYSTEM_CLOCK_wreq <= '0';
    case wr_adr_d0(2 downto 2) is
    when "0" =>
      -- Reg RESET
      RESET_wreq <= wr_req_d0;
      wr_ack_int <= RESET_wack;
    when "1" =>
      -- Reg SYSTEM_CLOCK
      SYSTEM_CLOCK_wreq <= wr_req_d0;
      wr_ack_int <= SYSTEM_CLOCK_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, RESET_WRPC_CORE_reg, SYSTEM_CLOCK_SELECT_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(2 downto 2) is
    when "0" =>
      -- Reg RESET
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(0) <= RESET_WRPC_CORE_reg;
      rd_dat_d0(31 downto 1) <= (others => '0');
    when "1" =>
      -- Reg SYSTEM_CLOCK
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(0) <= SYSTEM_CLOCK_SELECT_reg;
      rd_dat_d0(31 downto 1) <= (others => '0');
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;


-- Memory map:
--      0x000: Minic
--      0x100: Endpoint
--      0x200: Softpll
--      0x300: PPS gen
--      0x400: Syscon
--      0x500: UART
--      0x600: OneWire
--      0x800: WRPC diagnostics registers (for user)
--      0x900: WRPC diagnostics registers (for firmware)
--      0xa00: freq monitor
--      0xb00: cpu csr
--      0xc00: secbar sdb
--      0x8000: Auxillary space (Etherbone config, etc)

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.axi4_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity tb_kasli_axi_rw is
generic (
     runner_cfg        : string;
     CHIP_LEVEL        : boolean := FALSE
);
end entity;

architecture sim of tb_kasli_axi_rw is

begin

U_kasli : entity work.kasli_testbench;

main : process
alias m_axis is << constant .tb_kasli_axi_rw.U_kasli.axi_bus : bus_master_t >>;
alias m_uart is << constant .tb_kasli_axi_rw.U_kasli.master_uart : uart_master_t >>;

variable read_data   : std_logic_vector(31 downto 0);
begin
    test_runner_setup(runner, runner_cfg);
    wait for 1 us;
    if run("read_softpll") then
      read_bus(net, m_axis, x"00000200", read_data);
      check(read_data = x"00000000", "did not read back as expected at 0x200");

    elsif run("write_to_softpll") then
      write_bus(net, m_axis, x"00000200", x"00001122");
      read_bus(net, m_axis, x"00000200", read_data);
      check(read_data = x"00001122", "did not read back as expected at 0x200");

    elsif run("write_to_uart") then
      write_bus(net, m_axis, x"00000500", x"00001122");
      read_bus(net, m_axis, x"00000500", read_data);
      check(read_data = x"00001122", "did not read back as expected at 0x500");

    elsif run("read_from_uart") then
      read_bus(net, m_axis, x"00000500", read_data);
      check(read_data = x"00000000", "did not read back as expected at 0x500");

    elsif run("read_endpoint") then
      read_bus(net, m_axis, x"00000100", read_data);
      check(read_data = x"00000000", "did not read back as expected at 0x100");

    elsif run("write_endpoint") then
      write_bus(net, m_axis, x"00000100", x"00001122");
      read_bus(net, m_axis, x"00000100", read_data);
      check(read_data = x"00001122", "did not read back as expected at 0x100");

    end if;

    wait for 1 us;
    test_runner_cleanup(runner);

end process;

test_runner_watchdog(runner, 2 ms);

receive_uart : process
alias s_uart is << constant .tb_kasli_axi_rw.U_kasli.slave_uart : uart_slave_t >>;
begin
wait;
end process;

end architecture;


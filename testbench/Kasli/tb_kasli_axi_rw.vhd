
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.axi4_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity tb_kasli_axi_rw is
generic (
     runner_cfg        : string
);
end entity;

architecture sim of tb_kasli_axi_rw is

begin
DUT : entity work.kasli_testbench;

main : process
alias m_axis is << constant .tb_kasli_axi_rw.DUT.axi_bus : bus_master_t >>;
alias m_uart is << constant .tb_kasli_axi_rw.DUT.master_uart : uart_master_t >>;

begin
    test_runner_setup(runner, runner_cfg);
    wait for 100 us;

    test_runner_cleanup(runner);

end process;

test_runner_watchdog(runner, 2 ms);

receive_uart : process
alias s_uart is << constant .tb_kasli_axi_rw.DUT.slave_uart : uart_slave_t >>;
begin
wait;
end process;

end architecture;


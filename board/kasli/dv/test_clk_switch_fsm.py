from pathlib import Path
import os
from cocotb.runner import get_runner

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.clock import Clock


class TB:

    _init = [
        ("clk_i", 0),
        ("rst_n_i", 1),
        ("clk_switch_i", 0),
    ]

    def __init__(self, dut):

        self.dut = dut
        self.clk = self.dut.clk_i
        self.rst_n = self.dut.rst_n_i

        self.n_countdown_cycles = 2 ** int(self.dut.g_reset_counter_bits.value)

        for signal, reset_value in self._init:
            getattr(self.dut, signal).setimmediatevalue(reset_value)

        cocotb.start_soon(Clock(self.clk, period=8.0, units="ns").start())

    async def reset(self):
        self.rst_n.value = 0
        await ClockCycles(self.clk, 10)
        self.rst_n.value = 1
        await RisingEdge(self.clk)


@cocotb.test
async def cctb_test_bringup(dut):

    tb = TB(dut)
    await tb.reset()


@cocotb.test
async def cctb_test_pulse_switch(dut):

    tb = TB(dut)
    await tb.reset()

    await ClockCycles(tb.clk, 5)

    tb.dut.clk_switch_i.value = 1
    await RisingEdge(tb.clk)
    tb.dut.clk_switch_i.value = 0

    await ClockCycles(tb.clk, 3 * tb.n_countdown_cycles)
    assert tb.dut.clk_switch_o.value == 1


@cocotb.test
async def cctb_test_hold_switch(dut):

    tb = TB(dut)
    await tb.reset()

    await ClockCycles(tb.clk, 5)
    tb.dut.clk_switch_i.value = 1
    await ClockCycles(tb.clk, 3 * tb.n_countdown_cycles)
    assert tb.dut.clk_switch_o.value == 1


@cocotb.test
async def cctb_test_hold_then_swap(dut):

    tb = TB(dut)
    await tb.reset()

    await ClockCycles(tb.clk, 5)
    tb.dut.clk_switch_i.value = 1
    await ClockCycles(tb.clk, 3 * tb.n_countdown_cycles)
    assert tb.dut.clk_switch_o.value == 1
    tb.dut.clk_switch_i.value = 0
    await ClockCycles(tb.clk, 3 * tb.n_countdown_cycles)
    assert tb.dut.clk_switch_o.value == 0


def test_clk_switch_fsm_runner():
    """Python simulation runner"""

    pwd = Path(__file__).resolve().parent

    hdl_toplevel = "clk_switch_fsm"
    sim = os.getenv("SIM", "xcelium")
    testcase = os.getenv("TESTCASE", None)
    waves = os.getenv("WAVES", False)

    sources = [
        pwd / "../clk_switch_fsm.vhd",
    ]

    runner = get_runner(sim)
    runner.build(
        sources=sources, hdl_toplevel=hdl_toplevel, always=True, build_args=["-v200X"]
    )
    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module=f"test_{hdl_toplevel},",
        hdl_toplevel_lang="vhdl",
        testcase=testcase,
        waves=waves,
    )


if __name__ == "__main__":
    test_clk_switch_fsm_runner()

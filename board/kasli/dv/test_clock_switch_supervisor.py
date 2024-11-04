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
        ("clk_sel_i", 0),
    ]

    def __init__(self, dut):

        self.dut = dut
        self.clk = self.dut.clk_i
        self.rst_n = self.dut.rst_n_i

        print(f"rst counter bits: {int(self.dut.c_reset_counter_bits.value)}")
        self.n_countdown_cycles = 2 ** int(self.dut.c_reset_counter_bits.value)

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

    tb.dut.clk_sel_i.value = 1
    await RisingEdge(tb.clk)
    tb.dut.clk_sel_i.value = 0

    await ClockCycles(tb.clk, 3 * tb.n_countdown_cycles)
    assert tb.dut.clk_sel_o.value == 1
    assert tb.dut.rst_n_o.value == 1


@cocotb.test
async def cctb_test_hold_switch(dut):

    tb = TB(dut)
    await tb.reset()

    await ClockCycles(tb.clk, 5)
    tb.dut.clk_sel_i.value = 1
    await ClockCycles(tb.clk, 3 * tb.n_countdown_cycles)
    assert tb.dut.clk_sel_o.value == 1
    assert tb.dut.rst_n_o.value == 1


def test_clock_switch_supervisor_runner():
    """Python simulation runner"""

    pwd = Path(__file__).resolve().parent

    hdl_toplevel = "xwrc_clock_switch_supervisor"
    sim = os.getenv("SIM", "xcelium")
    testcase = os.getenv("TESTCASE", None)
    waves = os.getenv("WAVES", False)

    sources = [
        *[
            pwd / f"../../../ip_cores/general-cores/modules/common/{module}.vhd"
            for module in [
                "gencores_pkg",
                "gc_edge_detect",
                "gc_sync",
                "gc_sync_ffs",
            ]
        ],
        pwd / "../xwrc_clock_switch_supervisor.vhd",
    ]

    runner = get_runner(sim)
    runner.build(
        vhdl_sources=sources,
        hdl_toplevel=hdl_toplevel,
        always=True,
        build_args=["-v200X"],
    )
    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module=f"test_{hdl_toplevel.removeprefix('xwrc_')},",
        hdl_toplevel_lang="vhdl",
        testcase=testcase,
        waves=waves,
    )


if __name__ == "__main__":
    test_clock_switch_supervisor_runner()

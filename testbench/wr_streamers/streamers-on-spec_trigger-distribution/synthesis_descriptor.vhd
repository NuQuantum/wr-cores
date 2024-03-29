--------------------------------------------------------------------------------
-- SDB meta information for spec_wr_ref.xise.
--
-- This file was automatically generated by ../../ip_cores/general-cores/tools/sdb_desc_gen.tcl on:
-- Monday, May 13 2019
--
-- ../../ip_cores/general-cores/tools/sdb_desc_gen.tcl is part of OHWR general-cores:
-- https://www.ohwr.org/projects/general-cores/wiki
--
-- For more information on SDB meta information, see also:
-- https://www.ohwr.org/projects/sdb/wiki
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.wishbone_pkg.all;

package synthesis_descriptor is

  constant c_sdb_synthesis_info : t_sdb_synthesis := (
    syn_module_name  => "spec_wr_ref     ",
    syn_commit_id    => "94c94685dfc78fe1c2e81ba0467dc7b*",
    syn_tool_name    => "ISE     ",
    syn_tool_version => x"00000147",
    syn_date         => x"20190513",
    syn_username     => "Maciej Lipinski");

  constant c_sdb_repo_url : t_sdb_repo_url := (
    repo_url => "https://ohwr.org/project/wr-cores.git                          ");

end package synthesis_descriptor;

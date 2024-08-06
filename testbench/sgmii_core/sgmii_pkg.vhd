-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2023, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;

context work.com_context;
use work.stream_master_pkg.all;
use work.stream_slave_pkg.all;
use work.sync_pkg.all;
use work.integer_vector_ptr_pkg.all;
use work.queue_pkg.all;

package sgmii_pkg is
  type sgmii_master_t is record
    p_actor : actor_t;
    p_baud_rate : natural;
    p_idle_state : std_logic;
  end record;

  type sgmii_slave_t is record
    p_actor : actor_t;
    p_baud_rate : natural;
    p_idle_state : std_logic;
    p_data_length : positive;
  end record;

  -- Set the baud rate [bits/s]
  procedure set_baud_rate(signal net : inout network_t;
                          sgmii_master : sgmii_master_t;
                          baud_rate : natural);

  procedure set_baud_rate(signal net : inout network_t;
                          sgmii_slave : sgmii_slave_t;
                          baud_rate : natural);

  constant default_baud_rate : natural := 115200;
  constant default_idle_state : std_logic := '1';
  constant default_data_length : positive := 8;
  impure function new_sgmii_master(initial_baud_rate : natural := default_baud_rate;
                                  idle_state : std_logic := default_idle_state) return sgmii_master_t;
  impure function new_sgmii_slave(initial_baud_rate : natural := default_baud_rate;
                                 idle_state : std_logic := default_idle_state;
                                 data_length : positive := default_data_length) return sgmii_slave_t;

  impure function as_stream(sgmii_master : sgmii_master_t) return stream_master_t;
  impure function as_stream(sgmii_slave : sgmii_slave_t) return stream_slave_t;
  impure function as_sync(sgmii_master : sgmii_master_t) return sync_handle_t;
  impure function as_sync(sgmii_slave : sgmii_slave_t) return sync_handle_t;

  constant sgmii_set_baud_rate_msg : msg_type_t := new_msg_type("sgmii set baud rate");
end package;

package body sgmii_pkg is

  impure function new_sgmii_master(initial_baud_rate : natural := default_baud_rate;
                                  idle_state : std_logic := default_idle_state) return sgmii_master_t is
  begin
    return (p_actor => new_actor,
            p_baud_rate => initial_baud_rate,
            p_idle_state => idle_state);
  end;

  impure function new_sgmii_slave(initial_baud_rate : natural := default_baud_rate;
                                 idle_state : std_logic := default_idle_state;
                                 data_length : positive := default_data_length) return sgmii_slave_t is
  begin
    return (p_actor => new_actor,
            p_baud_rate => initial_baud_rate,
            p_idle_state => idle_state,
            p_data_length => data_length);
  end;

  impure function as_stream(sgmii_master : sgmii_master_t) return stream_master_t is
  begin
    return stream_master_t'(p_actor => sgmii_master.p_actor);
  end;

  impure function as_stream(sgmii_slave : sgmii_slave_t) return stream_slave_t is
  begin
    return stream_slave_t'(p_actor => sgmii_slave.p_actor);
  end;

  impure function as_sync(sgmii_master : sgmii_master_t) return sync_handle_t is
  begin
    return sgmii_master.p_actor;
  end;

  impure function as_sync(sgmii_slave : sgmii_slave_t) return sync_handle_t is
  begin
    return sgmii_slave.p_actor;
  end;

  procedure set_baud_rate(signal net : inout network_t;
                          actor : actor_t;
                          baud_rate : natural) is
    variable msg : msg_t := new_msg(sgmii_set_baud_rate_msg);
  begin
    push(msg, baud_rate);
    send(net, actor, msg);
  end;

  procedure set_baud_rate(signal net : inout network_t;
                          sgmii_master : sgmii_master_t;
                          baud_rate : natural) is
  begin
    set_baud_rate(net, sgmii_master.p_actor, baud_rate);
  end;

  procedure set_baud_rate(signal net : inout network_t;
                          sgmii_slave : sgmii_slave_t;
                          baud_rate : natural) is
  begin
    set_baud_rate(net, sgmii_slave.p_actor, baud_rate);
  end;
end package body;

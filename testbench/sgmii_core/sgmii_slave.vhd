-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2023, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.stream_slave_pkg.all;
use vunit_lib.queue_pkg.all;

use work.sgmii_pkg.all;


entity sgmii_slave is
  generic (
    sgmii : sgmii_slave_t);
  port (
    rx_p : in std_logic;
    rx_n : in std_logic);
end entity;

architecture a of sgmii_slave is
  signal baud_rate : natural := sgmii.p_baud_rate;
  signal local_event : std_logic := '0';
  constant data_queue : queue_t := new_queue;
begin

  main : process
    variable reply_msg, msg : msg_t;
    variable msg_type : msg_type_t;
  begin
    receive(net, sgmii.p_actor, msg);
    msg_type := message_type(msg);

    if msg_type = sgmii_set_baud_rate_msg then
      baud_rate <= pop(msg);

    elsif msg_type = stream_pop_msg then
      reply_msg := new_msg;
      if not (length(data_queue) > 0) then
        wait on local_event until length(data_queue) > 0;
      end if;
      push_std_ulogic_vector(reply_msg, pop_std_ulogic_vector(data_queue));
      push_boolean(reply_msg, false);
      reply(net, msg, reply_msg);

    else
      unexpected_msg_type(msg_type);
    end if;

  end process;

  recv : process
      variable time_per_bit : time := (10**9 / baud_rate) * 1 ns;
      variable time_per_half_bit : time := (10**9 / (2*baud_rate)) * 1 ns;

    procedure sgmii_recv(variable data : out std_logic_vector;
                        signal rx : in std_logic;
                        baud_rate : integer) is
    begin
      assert time_per_bit /= 0 ps report "time base too small for the sgmii core" severity FAILURE;
      wait until rx_p'event;
      wait for time_per_half_bit; -- middle of start bit

      for i in 0 to data'length-1 loop
        data(i) := rx_p;
        wait for time_per_bit;
      end loop;

    end procedure;

    variable d8  : std_logic_vector(7 downto 0);
    variable k   : std_logic;
    variable data : std_logic_vector(9 downto 0);
  begin
    wait on rx_p;
    -----------------------------------
    -- get bit alignment
    ----------------------------------
    bit_align : loop
        sgmii_recv(data, rx_p, baud_rate);
        decode_8b10b(data, d8, k);
        if k = '1' and d8 = x"50" then
            exit; -- loop bit_align;
        else
            wait for time_per_bit;
        end if;
    end loop;
    -----------------------------------
    -- wait for a start of frame
    ----------------------------------
    loop
       while not(k = '1' and d8 = x"5D") loop  -- Start of frame delimiter
          sgmii_recv(data, rx_p, baud_rate);
          decode_8b10b(data, d8, k);
       end loop;
       -- then grab the data
       while not(k = '1' and d8 = x"FD") loop -- end of frame delimiter
          sgmii_recv(data, rx_p, baud_rate);
          decode_8b10b(data, d8, k);
          push_std_ulogic_vector(data_queue, data);
       end loop;

       local_event <= '1';
       wait for 0 ns;
       local_event <= '0';
       wait for 0 ns;
    end loop;
  end process;

end architecture;

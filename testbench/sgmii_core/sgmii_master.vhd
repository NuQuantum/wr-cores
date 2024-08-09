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
use vunit_lib.stream_master_pkg.all;
use vunit_lib.queue_pkg.all;
use vunit_lib.sync_pkg.all;

use work.sgmii_pkg.all;

entity sgmii_master is
  generic (
    sgmii : sgmii_master_t);
  port (
    tx_p : out std_logic := '0';
    tx_n : out std_logic := '1');
end entity;

architecture a of sgmii_master is
signal data              : std_logic_vector(7 downto 0) := (others=>'0');
signal k                 : std_logic := '0';
signal time_per_bit      : time := (10**9 / 1250000) * 1 ps;
signal clock_half_period : time := 4 ns;
signal clock             : std_logic := '0';
signal running_disparity : boolean := false;

begin
clock <= not clock after clock_half_period;

  main : process
    variable msg : msg_t;
    variable baud_rate : natural := sgmii.p_baud_rate;
    variable msg_type : msg_type_t;
  begin
    if has_message(sgmii.p_actor) then
        receive(net, sgmii.p_actor, msg);
        msg_type := message_type(msg);

        handle_sync_message(net, msg_type, msg);
        ------------------------------------------
        if msg_type = stream_push_msg then
        ------------------------------------------
            send_Idle2(clock, data, k);
            send_StartOfPacket(clock, data, k);
            for i in 0 to 5 loop
                send_Preamble(clock, data, k);
            end loop;

            send_StartOfFrame(clock, data, k);
            k <= '0';
            while has_message(sgmii.p_actor) loop
                receive(net, sgmii.p_actor, msg);
                data <= pop_std_ulogic_vector(msg);
                wait until rising_edge(clock);
            end loop;
            send_Terminate(clock, data, k);
            send_CarrierExtend(clock, data, k);
            if running_disparity then
                send_Idle1(clock, data, k);
            else
                send_Idle2(clock, data, k);
            end if;
            for i in 0 to 3 loop
                send_Idle2(clock, data, k);
            end loop;

        ------------------------------------------
        elsif msg_type = sgmii_set_baud_rate_msg then
        ------------------------------------------
            baud_rate := pop(msg);
            time_per_bit <= (10**9 / (baud_rate / 1000)) * 1 ps ;
            clock_half_period <= (10**8 / (baud_rate / 1000)) * 1 ps ;
        ------------------------------------------
        else
        ------------------------------------------
            unexpected_msg_type(msg_type);
        end if;
    else
        send_Idle2(clock, data, k);
    end if;
  end process;

encoder : process
  variable disparity : boolean := false;
  variable d10       : std_logic_vector(9 downto 0);
begin
   wait until rising_edge(clock);
   loop
      encode_8b10b(k, disparity, data, d10);
      running_disparity <= disparity;
      for i in 0 to 9 loop
          tx_p <= d10(i);
          tx_n <= not d10(i);
          wait for time_per_bit;
      end loop;
   end loop;
end process;
end architecture;

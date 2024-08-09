-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2023, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.com_context;
use vunit_lib.stream_master_pkg.all;
use vunit_lib.stream_slave_pkg.all;
use vunit_lib.sync_pkg.all;
use vunit_lib.integer_vector_ptr_pkg.all;
use vunit_lib.queue_pkg.all;

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

  function count_ones(a:std_logic_vector) return integer;
  procedure encode_8b10b(k     : in std_logic;
                         disparity : inout boolean;
                         d8    : in std_logic_vector(7 downto 0);
                         d10   : inout std_logic_vector(9 downto 0));
  procedure decode_8b10b(d10 : in std_logic_vector(9 downto 0);
                         d8  : inout std_logic_vector(7 downto 0);
                         k   : inout std_logic);

  procedure send_Idle1 (signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic);
  procedure send_Idle2 (signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic);
  procedure send_StartOfPacket ( signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic);
  procedure send_Terminate ( signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic);
  procedure send_CarrierExtend ( signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic);
  procedure send_Error ( signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic);
  procedure send_Preamble ( signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic);
  procedure send_StartOfFrame ( signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic);

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

  function count_ones(a:std_logic_vector) return integer is
  variable rtn   : integer := 0;
  begin
      for i in a'range loop
        if a(i) then
        rtn := rtn + 1;
        end if;
      end loop;
      return rtn;
  end function;

  procedure encode_8b10b(k     : in std_logic;
                         disparity : inout boolean;
                         d8    : in std_logic_vector(7 downto 0);
                         d10   : inout std_logic_vector(9 downto 0)) is
  variable rtn : std_logic_vector(9 downto 0);
  begin

    if k = '1' then
      case d8 is
      when "00011100" => d10 := "0011110100"; --    110000 1011 -- K.28.0    1C
      when "00111100" => d10 := "0011111001"; --    110000 0110 -- K.28.1 †  3C
      when "01011100" => d10 := "0011110101"; --    110000 1010 -- K.28.2    5C
      when "01111100" => d10 := "0011110011"; --    110000 1100 -- K.28.3    7C
      when "10011100" => d10 := "0011110010"; --    110000 1101 -- K.28.4    9C
      when "10111100" => d10 := "0011111010"; --    110000 0101 -- K.28.5 †  BC
      when "11011100" => d10 := "0011110110"; --    110000 1001 -- K.28.6    DC
      when "11111100" => d10 := "0011111000"; --    110000 0111 -- K.28.7 ‡  FC
      when "11110111" => d10 := "1110101000"; --    000101 0111 -- K.23.7    F7
      when "11111011" => d10 := "1101101000"; --    001001 0111 -- K.27.7    FB
      when "11111101" => d10 := "1011101000"; --    010001 0111 -- K.29.7    FD
      when "11111110" => d10 := "0111101000"; --    100001 0111 -- K.30.7    FE
      when others => NULL;
      end case;
      if disparity then
         d10 := not d10;
      end if;
      if count_ones(d10) /= 5 then
          disparity := not disparity; -- in this case there are always +2 difference in bits
      end if;
    else
        -- do the 5b/6b
        case d8(4 downto 0) is
        when "00000" => d10(5 downto 0) := "100111"; --   011000    -- D.00
        when "00001" => d10(5 downto 0) := "011101"; --   100010    -- D.01
        when "00010" => d10(5 downto 0) := "101101"; --   010010    -- D.02
        when "00011" => d10(5 downto 0) := "110001"; --             -- D.03
        when "00100" => d10(5 downto 0) := "110101"; --   001010    -- D.04
        when "00101" => d10(5 downto 0) := "101001"; --             -- D.05
        when "00110" => d10(5 downto 0) := "011001"; --             -- D.06
        when "00111" => d10(5 downto 0) := "111000"; --   000111    -- D.07
        when "01000" => d10(5 downto 0) := "111001"; --   000110    -- D.08
        when "01001" => d10(5 downto 0) := "100101"; --             -- D.09
        when "01010" => d10(5 downto 0) := "010101"; --             -- D.10
        when "01011" => d10(5 downto 0) := "110100"; --             -- D.11
        when "01100" => d10(5 downto 0) := "001101"; --             -- D.12
        when "01101" => d10(5 downto 0) := "101100"; --             -- D.13
        when "01110" => d10(5 downto 0) := "011100"; --             -- D.14
        when "01111" => d10(5 downto 0) := "010111"; --   101000    -- D.15
        when "10000" => d10(5 downto 0) := "011011"; --   100100    -- D.16
        when "10001" => d10(5 downto 0) := "100011"; --             -- D.17
        when "10010" => d10(5 downto 0) := "010011"; --             -- D.18
        when "10011" => d10(5 downto 0) := "110010"; --             -- D.19
        when "10100" => d10(5 downto 0) := "001011"; --             -- D.20
        when "10101" => d10(5 downto 0) := "101010"; --             -- D.21
        when "10110" => d10(5 downto 0) := "011010"; --             -- D.22
        when "10111" => d10(5 downto 0) := "111010"; --   000101    -- D.23 † also used for the K.23.7 symbol
        when "11000" => d10(5 downto 0) := "110011"; --   001100    -- D.24
        when "11001" => d10(5 downto 0) := "100110"; --             -- D.25
        when "11010" => d10(5 downto 0) := "010110"; --             -- D.26
        when "11011" => d10(5 downto 0) := "110110"; --   001001    -- D.27 † also used for the K.27.7 symbol
        when "11100" => d10(5 downto 0) := "001110"; --             -- D.28
        when "11101" => d10(5 downto 0) := "101110"; --   010001    -- D.29 † also used for the K.29.7 symbol
        when "11110" => d10(5 downto 0) := "011110"; --   100001    -- D.30 † also used for the K.30.7 symbol
        when "11111" => d10(5 downto 0) := "101011"; --   010100    -- D.31
        --when "11100" => d10(5 downto 0) := "001111"; --   110000    -- K.28 ‡
        --not used   111100   000011
        when others => NULL;
        end case;

        if (count_ones(d10(5 downto 0)) /= 3) or (d8(4 downto 0)="00111") then
            if disparity then
               d10(5 downto 0) := not d10(5 downto 0);
            end if;
        end if;

        if (count_ones(d10(5 downto 0)) /= 3) then
            disparity := not disparity; -- in this case there are always +2 difference in bits
        end if;

       -- do the 3b/4b
        case d8(7 downto 5) is
        when "000" => d10(9 downto 6) := "1011"; --   0100 -- D.x.0
        when "001" => d10(9 downto 6) := "1001"; --        -- D.x.1
        when "010" => d10(9 downto 6) := "0101"; --        -- D.x.2
        when "011" => d10(9 downto 6) := "1100"; --   0011 -- D.x.3
        when "100" => d10(9 downto 6) := "1101"; --   0010 -- D.x.4
        when "101" => d10(9 downto 6) := "1010"; --        -- D.x.5
        when "110" => d10(9 downto 6) := "0110"; --        -- D.x.6
        when "111" => d10(9 downto 6) := "1110"; --   0001 -- D.x.P7 †
        when others => NULL;
        end case;

        -- special case to prevent a run of 5 consecutive '1' or '0'
        -- when RD = −1: for x = 17, 18 and 20 and
        -- when RD = +1: for x = 11, 13 and 14
        if d8(7 downto 5) = "111" and
          ((not disparity and ((d8(4 downto 0) = "10001") or (d8(4 downto 0) = "10010") or (d8(4 downto 0) = "10100"))) or
          (disparity and ((d8(4 downto 0) = "01011") or (d8(4 downto 0) = "01101") or (d8(4 downto 0) = "01110")))) then
            d10 := "0111"; --   1000 -- D.x.A7 †
        end if;

        if (count_ones(d10(9 downto 6)) /= 2) or (d8(7 downto 5)="011") then
            if disparity then
               d10(9 downto 6) := not d10(9 downto 6);
            end if;
        end if;

        if (count_ones(d10(9 downto 6)) /= 2) then
            disparity := not disparity; -- in this case there are always +2 difference in bits
        end if;
    end if;
  end procedure;

  procedure decode_8b10b(d10 : in std_logic_vector(9 downto 0);
                         d8  : inout std_logic_vector(7 downto 0);
                         k   : inout std_logic) is
  variable d10_rev : std_logic_vector(9 downto 0);
  begin

    for i in 0 to 9 loop
      d10_rev(i) := d10(9-i);
    end loop;

    -- have a look for the special characters
    case d10_rev is
    when "0011110100" | "1100001011" => k := '1'; d8 := "00011100"; -- K.28.0    1C
    when "0011111001" | "1100000110" => k := '1'; d8 := "00111100"; -- K.28.1 †  3C
    when "0011110101" | "1100001010" => k := '1'; d8 := "01011100"; -- K.28.2    5C
    when "0011110011" | "1100001100" => k := '1'; d8 := "01111100"; -- K.28.3    7C
    when "0011110010" | "1100001101" => k := '1'; d8 := "10011100"; -- K.28.4    9C
    when "0011111010" | "1100000101" => k := '1'; d8 := "10111100"; -- K.28.5 †  BC
    when "0011110110" | "1100001001" => k := '1'; d8 := "11011100"; -- K.28.6    DC
    when "0011111000" | "1100000111" => k := '1'; d8 := "11111100"; -- K.28.7 ‡  FC
    when "1110101000" | "0001010111" => k := '1'; d8 := "11110111"; -- K.23.7    F7
    when "1101101000" | "0010010111" => k := '1'; d8 := "11111011"; -- K.27.7    FB
    when "1011101000" | "0100010111" => k := '1'; d8 := "11111101"; -- K.29.7    FD
    when "0111101000" | "1000010111" => k := '1'; d8 := "11111110"; -- K.30.7    FE
    when others => k :='0';
    end case;

    if k = '0' then
        case d10_rev(5 downto 0) is
        when "100111" | "011000"  => d8(4 downto 0) := "00000";   -- D.00
        when "011101" | "100010"  => d8(4 downto 0) := "00001";   -- D.01
        when "101101" | "010010"  => d8(4 downto 0) := "00010";   -- D.02
        when "110001"             => d8(4 downto 0) := "00011";   -- D.03
        when "110101" | "001010"  => d8(4 downto 0) := "00100";   -- D.04
        when "101001"             => d8(4 downto 0) := "00101";   -- D.05
        when "011001"             => d8(4 downto 0) := "00110";   -- D.06
        when "111000" | "000111"  => d8(4 downto 0) := "00111";   -- D.07
        when "111001" | "000110"  => d8(4 downto 0) := "01000";   -- D.08
        when "100101"             => d8(4 downto 0) := "01001";   -- D.09
        when "010101"             => d8(4 downto 0) := "01010";   -- D.10
        when "110100"             => d8(4 downto 0) := "01011";   -- D.11
        when "001101"             => d8(4 downto 0) := "01100";   -- D.12
        when "101100"             => d8(4 downto 0) := "01101";   -- D.13
        when "011100"             => d8(4 downto 0) := "01110";   -- D.14
        when "010111" | "101000"  => d8(4 downto 0) := "01111";   -- D.15
        when "011011" | "100100"  => d8(4 downto 0) := "10000";   -- D.16
        when "100011"             => d8(4 downto 0) := "10001";   -- D.17
        when "010011"             => d8(4 downto 0) := "10010";   -- D.18
        when "110010"             => d8(4 downto 0) := "10011";   -- D.19
        when "001011"             => d8(4 downto 0) := "10100";   -- D.20
        when "101010"             => d8(4 downto 0) := "10101";   -- D.21
        when "011010"             => d8(4 downto 0) := "10110";   -- D.22
        when "111010" | "000101"  => d8(4 downto 0) := "10111";   -- D.23 † also used for the K.23.7 symbol
        when "110011" | "001100"  => d8(4 downto 0) := "11000";   -- D.24
        when "100110"             => d8(4 downto 0) := "11001";   -- D.25
        when "010110"             => d8(4 downto 0) := "11010";   -- D.26
        when "110110" | "001001"  => d8(4 downto 0) := "11011";   -- D.27 † also used for the K.27.7 symbol
        when "001110"             => d8(4 downto 0) := "11100";   -- D.28
        when "101110" | "010001"  => d8(4 downto 0) := "11101";   -- D.29 † also used for the K.29.7 symbol
        when "011110" | "100001"  => d8(4 downto 0) := "11110";   -- D.30 † also used for the K.30.7 symbol
        when "101011" | "010100"  => d8(4 downto 0) := "11111";   -- D.31
        when "001111" | "110000"  => d8(4 downto 0) := "11100";   -- K.28 ‡
        when others => d8(4 downto 0) := "11110"; --not used   111100   000011
        end case;

        case d10_rev(9 downto 6) is
        when "1011" | "0100" => d8(7 downto 5) := "000";  -- D.x.0
        when "1001"          => d8(7 downto 5) := "001";  -- D.x.1
        when "0101"          => d8(7 downto 5) := "010";  -- D.x.2
        when "1100" | "0011" => d8(7 downto 5) := "011";  -- D.x.3
        when "1101" | "0010" => d8(7 downto 5) := "100";  -- D.x.4
        when "1010"          => d8(7 downto 5) := "101";  -- D.x.5
        when "0110"          => d8(7 downto 5) := "110";  -- D.x.6
        when "1110" | "0001" => d8(7 downto 5) := "111";  -- D.x.P7 †
        when "0111" | "1000" => d8(7 downto 5) := "111";  -- D.x.A7 †
        when others => d8(7 downto 5) := "111";
        end case;
    end if;

  end procedure;

  procedure send_Idle1 (signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic) is
  begin
     k <= '1'; data <= x"BC";
     wait until rising_edge(clock);
     k <= '0'; data <= x"C5";
     wait until rising_edge(clock);
  end procedure;

  procedure send_Idle2 (signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic) is
  begin
     k <= '1'; data <= x"BC";
     wait until rising_edge(clock);
     k <= '0'; data <= x"50";
     wait until rising_edge(clock);
  end procedure;

  procedure send_StartOfPacket ( signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic) is
  begin
     k <= '1'; data <= x"FB";
     wait until rising_edge(clock);
  end procedure;

  procedure send_Terminate ( signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic) is
  begin
     k <= '1'; data <= x"FD";
     wait until rising_edge(clock);
  end procedure;

  procedure send_CarrierExtend ( signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic) is
  begin
     k <= '1'; data <= x"F7";
     wait until rising_edge(clock);
  end procedure;

  procedure send_Error ( signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic) is
  begin
     k <= '1'; data <= x"FE";
     wait until rising_edge(clock);
  end procedure;

  procedure send_Preamble ( signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic) is
  begin
     k <= '1'; data <= x"55";
     wait until rising_edge(clock);
  end procedure;

  procedure send_StartOfFrame ( signal clock : in std_logic;
                     signal data  : out std_logic_vector(7 downto 0);
                     signal k     : out std_logic) is
  begin
     k <= '1'; data <= x"D5";
     wait until rising_edge(clock);
  end procedure;

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

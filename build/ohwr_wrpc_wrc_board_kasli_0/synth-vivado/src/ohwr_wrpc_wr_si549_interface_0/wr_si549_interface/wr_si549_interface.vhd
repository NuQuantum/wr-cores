library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.si549_if_wb_pkg.all;

entity wr_si549_interface is
  
  generic 
  (
    g_simulation 			: integer := 0;
    g_sys_clock_freq 	: integer := 62500000;
    g_i2c_freq 				: integer := 400000;
    g_use_axi4l 			: boolean := false 		--true=axi4l interface, false=wb- interface, 
  );
  port 
  (
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    -- WR Core timing interface: aux clock tune port
    tm_dac_value_i    : in std_logic_vector(23 downto 0) := x"000000";
    tm_dac_value_wr_i : in std_logic := '0';

    -- I2C bus: output enable (active low)
    scl_pad_oen_o : out std_logic;
    sda_pad_oen_o : out std_logic;

    -- I2C bus: input pads
    scl_pad_i : in std_logic;
    sda_pad_i : in std_logic;

    -- Wishbone
    wb_adr_i   : in  std_logic_vector(c_wishbone_address_width-1 downto 0);  
    wb_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);      
    wb_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);			 
    wb_sel_i   : in  std_logic_vector(c_wishbone_address_width/8-1 downto 0); 
    wb_we_i    : in  std_logic;
    wb_cyc_i   : in  std_logic;
    wb_stb_i   : in  std_logic;
    wb_ack_o   : out std_logic;
    wb_err_o   : out std_logic;
    wb_rty_o 	 : out std_logic;
    wb_stall_o : out std_logic
  );

end wr_si549_interface;

architecture rtl of wr_si549_interface is

  component si549_if_wb is
    port (
	    rst_n_i              : in    std_logic;
	    clk_i                : in    std_logic;
	    wb_cyc_i             : in    std_logic;
	    wb_stb_i             : in    std_logic;
	    wb_adr_i             : in    std_logic_vector(4 downto 2);
	    wb_sel_i             : in    std_logic_vector(3 downto 0);
	    wb_we_i              : in    std_logic;
	    wb_dat_i             : in    std_logic_vector(31 downto 0);
	    wb_ack_o             : out   std_logic;
	    wb_err_o             : out   std_logic;
	    wb_rty_o             : out   std_logic;
	    wb_stall_o           : out   std_logic;
	    wb_dat_o             : out   std_logic_vector(31 downto 0);
	    -- Wires and registers
	    si549_regs_i         : in    t_si549_regs_master_in;
	    si549_regs_o         : out   t_si549_regs_master_out
    );
  end component;

  signal regs_in  : t_si549_regs_master_in;
  signal regs_out : t_si549_regs_master_out;

  signal delta_new_p      : std_logic;
  signal delta_current		: std_logic_vector(23 downto 0);
  signal delta_new  			: std_logic_vector(23 downto 0);

  signal tm_dac_value_wr_d : std_logic;

  constant c_adpll_byte0_addr	: std_logic_vector(7 downto 0)	:= X"e7";
  constant c_adpll_byte1_addr : std_logic_vector(7 downto 0)	:= X"e8";
  constant c_adpll_byte2_addr : std_logic_vector(7 downto 0)	:= X"e9";
  
  signal i2c_tick    : std_logic;
  signal i2c_divider : unsigned(7 downto 0);

  signal scl_int : std_logic;
  signal sda_int : std_logic;

  signal seq_count : unsigned(8 downto 0);
  signal delta_scaled_long : signed(33  downto 0);
  constant delta_shift : integer := 13;

  type t_i2c_transaction is (START, STOP, SEND_BYTE);

  type t_state is (IDLE, SI_START0, SI_ADDR0, SI_REG0, SI_BYTE0, SI_BYTE1, SI_BYTE2, SI_STOP0);

  signal state : t_state;

  signal scl_out_host : std_logic;
  signal scl_out_fsm 	: std_logic;
  signal sda_out_host	: std_logic;
  signal sda_out_fsm 	: std_logic;

  procedure f_i2c_iterate(tick : std_logic; signal counter : inout unsigned(seq_count'length-1 downto 0); value : std_logic_vector(7 downto 0); trans_type : t_i2c_transaction; signal scl : out std_logic; signal sda : out std_logic; signal state_var : out t_state; next_state : t_state) is
    variable last : boolean;
  begin

    last := false;

    if(tick = '0') then
      return;
    end if;


    case trans_type is
      when START =>
        case counter(1 downto 0) is
          -- states 0..2: start condition
          when "00" =>
            scl <= '1';
            sda <= '1';
          when "01" =>
            sda <= '0';
          when "10" =>
            scl  <= '0';
            last := true;
          when others => null;
        end case;

      when STOP =>
        case counter(1 downto 0) is
          -- states 0..2: start condition
          when "00" =>
            sda <= '0';
          when "01" =>
            scl <= '1';
          when "10" =>
            sda  <= '1';
            last := true;
          when others => null;
        end case;
        
      when SEND_BYTE =>
        
        case counter(1 downto 0) is
          when "00" =>
            scl 	<= '0';
            sda <= value(7-to_integer(counter(4 downto 2)));
            if(counter(5) = '1') then
            	sda 	<= '1';		--release bus
            end if;
          when "01" =>
            scl <= '1';
          when "10" =>
          	scl <= '1';
          when "11" =>
            scl <= '0';
            sda <= value(7-to_integer(counter(4 downto 2)+1));		--shift on falling edge of scl
            if(counter(4 downto 2) = "111") then
            	sda 	<= '1';		--release bus
            end if;
            if(counter(5) = '1') then
              last := true;              
            end if;
          when others => null;
        end case;
    end case;

    if(last) then
      state_var <= next_state;
      counter   <= "000000000";
    else
      counter <= counter + 1;
    end if;
    
  end f_i2c_iterate;

  function f_sign_extend( x : signed; l : integer ) return unsigned is
    variable rv : unsigned(l-1 downto 0);
  begin
    rv ( x'length-1 downto 0) := unsigned(x);
    rv( l-1 downto x'length ) := (others => x(x'length-1));
    return rv;
  end f_sign_extend;

  begin

	  U_wb_slave : si549_if_wb
	    port map 
	    (
	    	rst_n_i					=> rst_n_i,
				clk_i        		=> clk_sys_i,        
				wb_cyc_i				=> wb_cyc_i,
				wb_stb_i				=> wb_stb_i,
				wb_adr_i 				=> wb_adr_i(4 downto 2),
				wb_sel_i 				=> wb_sel_i,
				wb_we_i 				=> wb_we_i,
				wb_dat_i 				=> wb_dat_i,
				wb_ack_o 				=> wb_ack_o,
				wb_err_o 				=> wb_err_o,
				wb_rty_o 				=> wb_rty_o,
				wb_stall_o 			=> wb_stall_o,
				wb_dat_o 				=> wb_dat_o,
	      si549_regs_i    => regs_in,
	      si549_regs_o    => regs_out
	   	);

  	--read only field of control reg for consistancy with si570 version
	  regs_in.CR_BUSY <= '1' when state /= IDLE else '0';

	  p_delta : process(clk_sys_i)
	  begin
	    if rising_edge(clk_sys_i) then
	      if rst_n_i = '0' then
	        	delta_new_p <= '0';
	        	delta_scaled_long 	<= (others => '0');
	        	delta_new   			<= (others => '0');
	      else
	        tm_dac_value_wr_d <= tm_dac_value_wr_i or regs_out.DEBUG_wr;
	        
	        if(tm_dac_value_wr_i = '1') then

	        	delta_scaled_long <= (signed('0' & tm_dac_value_i(15 downto 0)) - to_signed(32768, 17)) * signed('0' & regs_out.GAIN_GAIN_VALUE); --GAIN_GAIN_VALUE 8.8 format.
	        	delta_new   			<= (others => '0');
	        elsif(regs_out.DEBUG_wr = '1') then
	        	delta_scaled_long <= (signed('0' & regs_out.DEBUG_DAC_VAL(15 downto 0)) - to_signed(32768, 17)) * signed('0' & regs_out.GAIN_GAIN_VALUE);
	        	delta_new   			<= (others => '0');
	        end if;

	        if(tm_dac_value_wr_d = '1') then
	          delta_new <= std_logic_vector(f_sign_extend(delta_scaled_long(31 downto 8), delta_new'length));
	        end if;	        

	       	delta_new_p <= tm_dac_value_wr_d and regs_out.CR_ENABLE;	      
	      end if;
	    end if;
	  end process;

	  p_i2c_divider : process(clk_sys_i)
	  begin
	    if rising_edge(clk_sys_i) then
	      if rst_n_i = '0' then
	        i2c_divider <= (others => '0');
	        i2c_tick    <= '0';
	      else
	        if(i2c_divider = unsigned(regs_out.CR_CLK_DIV)) then
	          i2c_tick <= '1';
	          i2c_divider <= (others => '0');
	        else
	          i2c_tick <= '0';
	          i2c_divider <= i2c_divider + 1;
	        end if;
	      end if;
	    end if;
	  end process;

	  --writes updated adpll_delta value to si594 registers (in burst mode)
	  p_i2c_fsm : process(clk_sys_i)
	    variable i2c_last : boolean;
	  begin
	    if rising_edge(clk_sys_i) then
	      if rst_n_i = '0' then
	        state       <= IDLE;
	        seq_count   <= (others => '0');
	        scl_out_fsm <= '1';
	        sda_out_fsm <= '1';
	        delta_current 	<= (others => '0');
	      else
	        case state is
	          when IDLE =>
	            if(delta_new_p = '1') then
	              state <= SI_START0;
	              delta_current <= delta_new;
	            end if;
	          when SI_START0 =>
	            f_i2c_iterate(i2c_tick, seq_count, x"00", START, scl_out_fsm, sda_out_fsm, state, SI_ADDR0);
	          when SI_ADDR0 =>
	            f_i2c_iterate(i2c_tick, seq_count, regs_out.CR_I2C_ADDR, SEND_BYTE, scl_out_fsm, sda_out_fsm, state, SI_REG0);
	          when SI_REG0 =>
	            f_i2c_iterate(i2c_tick, seq_count, c_adpll_byte0_addr, SEND_BYTE, scl_out_fsm, sda_out_fsm, state, SI_BYTE0);
	          when SI_BYTE0 =>
	            f_i2c_iterate(i2c_tick, seq_count, delta_current(7 downto 0), SEND_BYTE, scl_out_fsm, sda_out_fsm, state, SI_BYTE1);
	          when SI_BYTE1 =>
	            f_i2c_iterate(i2c_tick, seq_count, delta_current(15 downto 8), SEND_BYTE, scl_out_fsm, sda_out_fsm, state, SI_BYTE2);
	          when SI_BYTE2 =>
	            f_i2c_iterate(i2c_tick, seq_count, delta_current(23 downto 16), SEND_BYTE, scl_out_fsm, sda_out_fsm, state, SI_STOP0);
	          when SI_STOP0 =>
	            f_i2c_iterate(i2c_tick, seq_count, x"00", STOP, scl_out_fsm, sda_out_fsm, state, IDLE);	            
	          when others => null;
	        end case;
	      end if;
	    end if;
	  end process;

	  regs_in.GPSR_scl <= scl_pad_i;
	  regs_in.GPSR_sda <= sda_pad_i;

	  p_host_i2c : process(clk_sys_i)
	  begin
	    if rising_edge(clk_sys_i) then
	      if(rst_n_i = '0') then
	        scl_out_host <= '1';
	        sda_out_host <= '1';
	      else
	        if(regs_out.GPSR_wr = '1' and regs_out.GPSR_scl = '1') then
	          scl_out_host <= '1';
	        end if;

	        if(regs_out.GPSR_wr = '1' and regs_out.GPSR_sda = '1') then
	          sda_out_host <= '1';
	        end if;

	        if(regs_out.GPCR_scl = '1') then
	          scl_out_host <= '0';
	        end if;

	        if(regs_out.GPCR_sda = '1') then
	          sda_out_host <= '0';
	        end if;	        
	      end if;
	    end if;
	  end process;

	  p_mux_i2c : process(clk_sys_i)
	  begin
	    if rising_edge(clk_sys_i) then
	      if(state = IDLE) then
	        scl_pad_oen_o <= scl_out_host;
	        sda_pad_oen_o <= sda_out_host;
	      else
	        scl_pad_oen_o <= scl_out_fsm;
	        sda_pad_oen_o <= sda_out_fsm;
	      end if;
	    end if;
	  end process;

	  wb_err_o <= '0';

  end architecture;
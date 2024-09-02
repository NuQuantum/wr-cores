package xwrf_gmii_pkg is 

  component xwrf_gmii is
    port (
        clk_sys_i           : in std_logic;
        rst_sys_n_i         : in std_logic;
    
        wrf_snk_i           : in  t_wrf_sink_in;
        wrf_snk_o           : out t_wrf_sink_out;
        wrf_src_i           : in  t_wrf_source_in;
        wrf_src_o           : out t_wrf_source_out;
        
        gmii_rx_rst_n_i     : in  std_logic;
        gmii_rx_125m_i      : in  std_logic;
        gmii_rxd_i          : in  std_logic_vector(7 downto 0);
        gmii_rxdv_i         : in  std_logic;
        gmii_rx_er          : in  std_logic;
    
        gmii_tx_125m_i      : in  std_logic;
        gmii_tx_rst_n_i     : in  std_logic;
        gmii_txdata_o       : out std_logic_vector(7 downto 0);
        gmii_txen_o         : out std_logic;
        gmii_tx_er_o        : out std_logic
    );
    end component;
  
end package;
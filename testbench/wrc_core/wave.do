onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/DUT/PERIPH/rst_n_i
add wave -noupdate /main/DUT/rst_net_n
add wave -noupdate /main/DUT/rst_wrc_n
add wave -noupdate /main/DUT/clk_sys_i
add wave -noupdate /main/clk_ref
add wave -noupdate /main/DUT/phy_tx_data_o
add wave -noupdate /main/DUT/phy_tx_k_o
add wave -noupdate /main/phy_rbclk
add wave -noupdate /main/DUT/phy_rx_data_i
add wave -noupdate /main/DUT/phy_rx_k_i
add wave -noupdate -expand -group WRPC_EP -expand /main/DUT/U_Endpoint/src_o
add wave -noupdate -expand -group WRPC_EP /main/DUT/U_Endpoint/src_i
add wave -noupdate -expand -group WRPC_EP /main/DUT/U_Endpoint/snk_o
add wave -noupdate -expand -group WRPC_EP -expand /main/DUT/U_Endpoint/snk_i
add wave -noupdate -expand -group WRPC_EP /main/DUT/U_Endpoint/U_Wrapped_Endpoint/regs_fromwb
add wave -noupdate -expand -group WRPC_EP /main/DUT/U_Endpoint/U_Wrapped_Endpoint/regs_towb
add wave -noupdate -expand -group WRPC_EP /main/DUT/U_Endpoint/U_Wrapped_Endpoint/pfilter_done_o
add wave -noupdate -expand -group WRPC_EP /main/DUT/U_Endpoint/U_Wrapped_Endpoint/pfilter_drop_o
add wave -noupdate -expand -group WRPC_EP /main/DUT/U_Endpoint/U_Wrapped_Endpoint/pfilter_pclass_o
add wave -noupdate -expand -group WRPC_EP /main/DUT/U_Endpoint/wb_i
add wave -noupdate -expand -group WRPC_EP /main/DUT/U_Endpoint/wb_o
add wave -noupdate -group EP_PCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_clk_i
add wave -noupdate -group EP_PCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_data_o
add wave -noupdate -group EP_PCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_k_o
add wave -noupdate -group EP_PCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_disparity_i
add wave -noupdate -group EP_PCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_enc_err_i
add wave -noupdate -group EP_PCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_state
add wave -noupdate -group EP_PCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/pcs_fab_i
add wave -noupdate -group EP_PCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/pcs_busy_o
add wave -noupdate -expand -group Minic /main/DUT/MINI_NIC/src_i
add wave -noupdate -expand -group Minic /main/DUT/MINI_NIC/src_o
add wave -noupdate -expand -group Minic /main/DUT/MINI_NIC/wb_i
add wave -noupdate -expand -group Minic /main/DUT/MINI_NIC/wb_o
add wave -noupdate -expand -group Minic /main/DUT/MINI_NIC/U_Wrapped_Minic/ntx_state
add wave -noupdate -expand -group Minic /main/DUT/MINI_NIC/U_Wrapped_Minic/tx_fifo_d
add wave -noupdate -expand -group Minic /main/DUT/MINI_NIC/U_Wrapped_Minic/tx_fifo_empty
add wave -noupdate -expand -group Minic /main/DUT/MINI_NIC/U_Wrapped_Minic/tx_fifo_full
add wave -noupdate -expand -group Minic /main/DUT/MINI_NIC/U_Wrapped_Minic/tx_fifo_q
add wave -noupdate -expand -group Minic /main/DUT/MINI_NIC/U_Wrapped_Minic/tx_fifo_rd
add wave -noupdate -expand -group Minic /main/DUT/MINI_NIC/U_Wrapped_Minic/tx_fifo_we
add wave -noupdate -expand -group Minic /main/DUT/MINI_NIC/U_Wrapped_Minic/tx_status_word
add wave -noupdate -group EP /main/EP/snk_ack_o
add wave -noupdate -group EP /main/EP/snk_adr_i
add wave -noupdate -group EP /main/EP/snk_cyc_i
add wave -noupdate -group EP /main/EP/snk_dat_i
add wave -noupdate -group EP /main/EP/snk_err_o
add wave -noupdate -group EP /main/EP/snk_rty_o
add wave -noupdate -group EP /main/EP/snk_sel_i
add wave -noupdate -group EP /main/EP/snk_stall_o
add wave -noupdate -group EP /main/EP/snk_stb_i
add wave -noupdate -group EP /main/EP/snk_we_i
add wave -noupdate -group EP /main/EP/src_ack_i
add wave -noupdate -group EP /main/EP/src_adr_o
add wave -noupdate -group EP /main/EP/src_cyc_o
add wave -noupdate -group EP /main/EP/src_dat_o
add wave -noupdate -group EP /main/EP/src_err_i
add wave -noupdate -group EP /main/EP/src_in
add wave -noupdate -group EP /main/EP/src_out
add wave -noupdate -group EP /main/EP/src_sel_o
add wave -noupdate -group EP /main/EP/src_stall_i
add wave -noupdate -group EP /main/EP/src_stb_o
add wave -noupdate -group EP /main/EP/src_we_o
add wave -noupdate -group EP /main/EP/regs_fromwb
add wave -noupdate -group EP /main/EP/regs_towb
add wave -noupdate -group EP /main/EP/wb_ack_o
add wave -noupdate -group EP /main/EP/wb_adr_i
add wave -noupdate -group EP /main/EP/wb_cyc_i
add wave -noupdate -group EP /main/EP/wb_dat_i
add wave -noupdate -group EP /main/EP/wb_dat_o
add wave -noupdate -group EP /main/EP/wb_in
add wave -noupdate -group EP /main/EP/wb_out
add wave -noupdate -group EP /main/EP/wb_sel_i
add wave -noupdate -group EP /main/EP/wb_stall_o
add wave -noupdate -group EP /main/EP/wb_stb_i
add wave -noupdate -group EP /main/EP/wb_we_i
add wave -noupdate -group DUT->EP-TXpath -expand /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_Tx_Path/dreq_pipe
add wave -noupdate -group DUT->EP-TXpath /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_Tx_Path/pcs_busy_i
add wave -noupdate -group DUT->EP-TXpath /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_Tx_Path/snk_i
add wave -noupdate -group DUT->EP-TXpath /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_Tx_Path/snk_o
add wave -noupdate -group DUT->EP-TXpath /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_Tx_Path/pcs_fab_o
add wave -noupdate -group DUT->EP-TXpath /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_Tx_Path/pcs_dreq_i
add wave -noupdate -group DUT->EP-TXpath /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_Tx_Path/ep_ctrl_i
add wave -noupdate -group DUT->EP-TXpath /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_Tx_Path/pcs_error_i
add wave -noupdate -group DUT->EP-TXpath -expand /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_Tx_Path/fab_pipe
add wave -noupdate -group DUT->EP-TXpath /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_Tx_Path/pcs_fab_o
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/an_tx_en_i
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/an_tx_en_synced
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/an_tx_val_i
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/clk_sys_i
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_almost_empty
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_almost_full
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_clear_n
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_empty
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_enough_data
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_fab
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_packed_in
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_packed_out
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_state
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_rd
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_ready
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_wr
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/mdio_mcr_pdown_i
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/mdio_mcr_pdown_synced
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/mdio_wr_spec_tx_cal_i
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/pcs_busy_o
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/pcs_dreq_o
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/pcs_error_o
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/pcs_fab_i
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_clk_i
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_data_o
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_disparity_i
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_enc_err_i
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_k_o
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/rmon_tx_underrun
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/rst_n_i
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/timestamp_trigger_p_a_o
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_busy
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_catch_disparity
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_cntr
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_cr_alternate
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_error
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_is_k
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_odata_reg
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_odd_length
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_state
add wave -noupdate -group DUT->EP-TxPCS /main/DUT/U_Endpoint/U_Wrapped_Endpoint/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_rdreq_toggle
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/an_tx_en_i
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_state
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/an_tx_en_synced
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/an_tx_val_i
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/clk_sys_i
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_almost_empty
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_almost_full
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_clear_n
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_empty
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_enough_data
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_fab
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_packed_in
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_packed_out
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_rd
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_ready
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/fifo_wr
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/mdio_mcr_pdown_i
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/mdio_mcr_pdown_synced
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/mdio_wr_spec_tx_cal_i
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/pcs_busy_o
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/pcs_dreq_o
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/pcs_error_o
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/pcs_fab_i
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_clk_i
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_data_o
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_disparity_i
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_enc_err_i
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/phy_tx_k_o
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/rmon_tx_underrun
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/rst_n_i
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/timestamp_trigger_p_a_o
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_busy
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_catch_disparity
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_cntr
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_cr_alternate
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_error
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_is_k
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_odata_reg
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_odd_length
add wave -noupdate -group EP->txPCS /main/EP/U_PCS_1000BASEX/gen_8bit/U_TX_PCS/tx_rdreq_toggle
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/clk_sys_i
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/demux
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/dmux_others
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/dmux_sel
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/dmux_sel_zero
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/dmux_select
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/dmux_snd_stat
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/dmux_status_reg
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/ep_snk_i
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/ep_snk_o
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/ep_snk_out_stall
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/ep_src_i
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/ep_src_o
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/ep_stall_mask
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/g_muxed_ports
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/mux
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/mux_class_i
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/mux_cycs
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/mux_rrobin
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/mux_select
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/mux_snk_i
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/mux_snk_o
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/mux_src_i
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/mux_src_o
add wave -noupdate -group DUT->MUX /main/DUT/U_WBP_Mux/rst_n_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/clk_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/rst_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/irq_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/fault_o
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/im_addr_o
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/im_rd_o
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/im_data_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/im_valid_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dm_addr_o
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dm_data_s_o
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dm_data_l_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dm_data_select_o
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dm_store_o
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dm_load_o
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dm_load_done_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dm_store_done_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dbg_force_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dbg_enabled_o
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dbg_insn_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dbg_insn_set_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dbg_insn_ready_o
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dbg_mbx_data_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dbg_mbx_write_i
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/dbg_mbx_data_o
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/f_stall
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x_stall
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x_kill
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d_stall
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d_kill
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d_stall_req
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/w_stall_req
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x_stall_req
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x_fault
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2f_pc_bra
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2f_bra
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2f_dbg_toggle
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/f2d_pc
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/f2d_ir
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/f2d_valid
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/rf_rs1
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/rf_rs2
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/rf_rd
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/rf_rd_value
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/rf_rd_ecc
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/rf_rd_ecc_flip
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/rf_rd_write
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_valid
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_pc
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_rs1
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_rs2
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_rd
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_fun
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_opcode
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_shifter_sign
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_load
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_store
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_undef
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_write_ecc
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_fix_ecc
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_imm
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_signed_alu_op
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_add_o
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_rd_source
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_rd_write
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_csr_sel
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_csr_imm
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_csr
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_mret
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_ebreak
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_csr_load_en
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_alu_op1
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_alu_op2
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_use_op1
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_use_op2
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_use_rs1
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_use_rs2
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_multiply
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_divide
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2w_rd
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2w_rd_value
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2w_rd_shifter
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2w_rd_multiply
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2w_dm_addr
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2w_rd_write
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2w_fun
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2w_store
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2w_load
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2w_rd_source
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2w_valid
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2w_ecc_flip
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x_rs2_value
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x_rs1_value
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x_rs1_ecc_err
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x_rs2_ecc_err
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/rf_bypass_rd_value
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/rf_bypass_rd_write
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/csr_time
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/csr_cycles
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/d2x_is_add
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/sys_tick
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2f_bra_d0
add wave -noupdate -group cpu /main/DUT/U_CPU/U_cpu_core/x2f_bra_d1
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/clk_sys_i
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/rst_n_i
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/irq_i
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dwb_o
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dwb_i
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/host_slave_i
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/host_slave_o
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/cpu_rst
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/cpu_rst_d
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/im_addr
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/im_data
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/im_valid
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/ha_im_addr
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/ha_im_wdata
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/ha_im_write
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/im_addr_muxed
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_addr
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_data_s
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_data_l
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_data_select
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_load
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_store
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_load_done
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_store_done
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_cycle_in_progress
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_is_wishbone
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_mem_rdata
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_wb_rdata
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_wb_write
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_select_wb
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dm_data_write
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dbg_insn
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/dwb_out
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/regs_in
add wave -noupdate -expand -group wrc-cpu /main/DUT/U_CPU/regs_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {402323834470 fs} 1} {{Cursor 2} {1203233669880 fs} 0} {{Cursor 3} {548446650000 fs} 0}
quietly wave cursor active 3
configure wave -namecolwidth 363
configure wave -valuecolwidth 163
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 fs} {2525250 ns}

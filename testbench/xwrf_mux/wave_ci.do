onerror {resume}

add wave  /main/DUT/U_Mux/clk_sys_i
add wave  /main/DUT/U_Mux/rst_n_i

add wave  /main/DUT/U_Mux/mux_class_i

add wave -divider ENDPOINT
#add wave -noupdate /main/DUT/U_Mux/ep_snk_i.cyc
#add wave -noupdate /main/DUT/U_Mux/ep_snk_i.stb
#add wave -noupdate /main/DUT/U_Mux/ep_snk_i.adr
#add wave -noupdate /main/DUT/U_Mux/ep_snk_i.sel
#add wave -noupdate /main/DUT/U_Mux/ep_snk_i.dat
#add wave -noupdate /main/DUT/U_Mux/ep_snk_o.ack
#add wave -noupdate /main/DUT/U_Mux/ep_snk_o.err
#add wave -noupdate /main/DUT/U_Mux/ep_snk_o.stall
add wave  /main/DUT/U_Mux/ep_src_o.adr
add wave  /main/DUT/U_Mux/ep_src_o.dat
add wave  /main/DUT/U_Mux/ep_src_o.sel
add wave  /main/DUT/U_Mux/ep_src_o.cyc
add wave  /main/DUT/U_Mux/ep_src_o.stb
add wave  /main/DUT/U_Mux/ep_src_i.ack
add wave  /main/DUT/U_Mux/ep_src_i.err
add wave  /main/DUT/U_Mux/ep_src_i.stall

add wave -divider MiNIC
add wave  /main/DUT/U_Mux/mux_snk_i(0).adr
add wave  /main/DUT/U_Mux/mux_snk_i(0).dat
add wave  /main/DUT/U_Mux/mux_snk_i(0).sel
add wave  /main/DUT/U_Mux/mux_snk_i(0).cyc
add wave  /main/DUT/U_Mux/mux_snk_i(0).stb
add wave  /main/DUT/U_Mux/mux_snk_o(0).ack
add wave  /main/DUT/U_Mux/mux_snk_o(0).err
add wave  /main/DUT/U_Mux/mux_snk_o(0).stall
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(0).cyc
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(0).stb
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(0).adr
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(0).sel
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(0).dat
#add wave -noupdate /main/DUT/U_Mux/mux_src_i(0).ack
#add wave -noupdate /main/DUT/U_Mux/mux_src_i(0).err
#add wave -noupdate /main/DUT/U_Mux/mux_src_i(0).stall

add wave -divider EXT
add wave  /main/DUT/U_Mux/mux_snk_i(1).adr
add wave  /main/DUT/U_Mux/mux_snk_i(1).dat
add wave  /main/DUT/U_Mux/mux_snk_i(1).sel
add wave  /main/DUT/U_Mux/mux_snk_i(1).cyc
add wave  /main/DUT/U_Mux/mux_snk_i(1).stb
add wave  /main/DUT/U_Mux/mux_snk_o(1).ack
add wave  /main/DUT/U_Mux/mux_snk_o(1).err
add wave  /main/DUT/U_Mux/mux_snk_o(1).stall
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(1).cyc
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(1).stb
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(1).adr
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(1).sel
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(1).dat
#add wave -noupdate /main/DUT/U_Mux/mux_src_i(1).ack
#add wave -noupdate /main/DUT/U_Mux/mux_src_i(1).err
#add wave -noupdate /main/DUT/U_Mux/mux_src_i(1).stall

add wave -divider MUX 
add wave  /main/DUT/U_Mux/mux_snk_i(2).adr
add wave  /main/DUT/U_Mux/mux_snk_i(2).dat
add wave  /main/DUT/U_Mux/mux_snk_i(2).sel
add wave  /main/DUT/U_Mux/mux_snk_i(2).cyc
add wave  /main/DUT/U_Mux/mux_snk_i(2).stb
add wave  /main/DUT/U_Mux/mux_snk_o(2).ack
add wave  /main/DUT/U_Mux/mux_snk_o(2).err
add wave  /main/DUT/U_Mux/mux_snk_o(2).stall
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(2).cyc
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(2).stb
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(2).adr
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(2).sel
#add wave -noupdate /main/DUT/U_Mux/mux_src_o(2).dat
#add wave -noupdate /main/DUT/U_Mux/mux_src_i(2).ack
#add wave -noupdate /main/DUT/U_Mux/mux_src_i(2).err
#add wave -noupdate /main/DUT/U_Mux/mux_src_i(2).stall

add wave -divider MUX
#add wave -noupdate /main/DUT/U_Mux/mux
#add wave -noupdate /main/DUT/U_Mux/mux_last
#add wave -noupdate /main/DUT/U_Mux/mux_extdat_reg
#add wave -noupdate /main/DUT/U_Mux/mux_ptpdat_reg
#add wave -noupdate /main/DUT/U_Mux/mux_extadr_reg
#add wave -noupdate /main/DUT/U_Mux/mux_ptpadr_reg
#add wave -noupdate /main/DUT/U_Mux/mux_extsel_reg
#add wave -noupdate /main/DUT/U_Mux/mux_ptpsel_reg
#add wave -noupdate /main/DUT/U_Mux/mux_extcyc_reg
#add wave -noupdate /main/DUT/U_Mux/mux_ptpcyc_reg
#add wave -noupdate /main/DUT/U_Mux/mux_extstb_reg
#add wave -noupdate /main/DUT/U_Mux/mux_ptpstb_reg
#add wave -noupdate /main/DUT/U_Mux/mux_pend_ext
#add wave -noupdate /main/DUT/U_Mux/mux_pend_ptp
#add wave -noupdate /main/DUT/U_Mux/force_stall
add wave  /main/DUT/U_Mux/mux
add wave  /main/DUT/U_Mux/mux_select
add wave  /main/DUT/U_Mux/demux
add wave  /main/DUT/U_Mux/dmux_status_reg
add wave  /main/DUT/U_Mux/dmux_snd_stat
add wave  /main/DUT/U_Mux/dmux_select
add wave  /main/DUT/U_Mux/dmux_sel
add wave  /main/DUT/U_Mux/DMUX_FSM/sel
add wave  /main/DUT/U_Mux/ep_stall_mask
null TreeUpdate [null SetDefaultTree]
wv.cursors.add -time {50325670 fs} -name {Cursor 1}
null configure wave -namecolwidth 350
null configure wave -valuecolwidth 100
null configure wave -justifyvalue left
null configure wave -signalnamewidth 1
null configure wave -snapdistance 10
null configure wave -datasetprefix 0
null configure wave -rowmargin 4
null configure wave -childrowmargin 2
null configure wave -gridoffset 0
null configure wave -gridperiod 1
null configure wave -griddelta 40
null configure wave -timeline 0
null configure wave -timelineunits ns
update
wv.zoom.range -from {0 fs} -to {262500 ns}


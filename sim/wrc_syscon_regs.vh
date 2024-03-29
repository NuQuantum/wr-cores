`define ADDR_SYSC_RSTR                 6'h0
`define SYSC_RSTR_TRIG_OFFSET 0
`define SYSC_RSTR_TRIG 32'h0fffffff
`define SYSC_RSTR_RST_OFFSET 28
`define SYSC_RSTR_RST 32'h10000000
`define ADDR_SYSC_GPSR                 6'h4
`define SYSC_GPSR_FMC_SCL_OFFSET 2
`define SYSC_GPSR_FMC_SCL 32'h00000004
`define SYSC_GPSR_FMC_SDA_OFFSET 3
`define SYSC_GPSR_FMC_SDA 32'h00000008
`define SYSC_GPSR_NET_RST_OFFSET 4
`define SYSC_GPSR_NET_RST 32'h00000010
`define SYSC_GPSR_BTN1_OFFSET 5
`define SYSC_GPSR_BTN1 32'h00000020
`define SYSC_GPSR_BTN2_OFFSET 6
`define SYSC_GPSR_BTN2 32'h00000040
`define SYSC_GPSR_SFP1_DET_OFFSET 7
`define SYSC_GPSR_SFP1_DET 32'h00000080
`define SYSC_GPSR_SFP1_SCL_OFFSET 8
`define SYSC_GPSR_SFP1_SCL 32'h00000100
`define SYSC_GPSR_SFP1_SDA_OFFSET 9
`define SYSC_GPSR_SFP1_SDA 32'h00000200
`define SYSC_GPSR_SPI_SCLK_OFFSET 10
`define SYSC_GPSR_SPI_SCLK 32'h00000400
`define SYSC_GPSR_SPI_NCS_OFFSET 11
`define SYSC_GPSR_SPI_NCS 32'h00000800
`define SYSC_GPSR_SPI_MOSI_OFFSET 12
`define SYSC_GPSR_SPI_MOSI 32'h00001000
`define SYSC_GPSR_SPI_MISO_OFFSET 13
`define SYSC_GPSR_SPI_MISO 32'h00002000
`define SYSC_GPSR_SFP2_DET_OFFSET 16
`define SYSC_GPSR_SFP2_DET 32'h00010000
`define SYSC_GPSR_SFP2_SCL_OFFSET 17
`define SYSC_GPSR_SFP2_SCL 32'h00020000
`define SYSC_GPSR_SFP2_SDA_OFFSET 18
`define SYSC_GPSR_SFP2_SDA 32'h00040000
`define ADDR_SYSC_GPCR                 6'h8
`define SYSC_GPCR_LED_STAT_OFFSET 0
`define SYSC_GPCR_LED_STAT 32'h00000001
`define SYSC_GPCR_LED_LINK_OFFSET 1
`define SYSC_GPCR_LED_LINK 32'h00000002
`define SYSC_GPCR_FMC_SCL_OFFSET 2
`define SYSC_GPCR_FMC_SCL 32'h00000004
`define SYSC_GPCR_FMC_SDA_OFFSET 3
`define SYSC_GPCR_FMC_SDA 32'h00000008
`define SYSC_GPCR_SFP1_SCL_OFFSET 8
`define SYSC_GPCR_SFP1_SCL 32'h00000100
`define SYSC_GPCR_SFP1_SDA_OFFSET 9
`define SYSC_GPCR_SFP1_SDA 32'h00000200
`define SYSC_GPCR_SPI_SCLK_OFFSET 10
`define SYSC_GPCR_SPI_SCLK 32'h00000400
`define SYSC_GPCR_SPI_CS_OFFSET 11
`define SYSC_GPCR_SPI_CS 32'h00000800
`define SYSC_GPCR_SPI_MOSI_OFFSET 12
`define SYSC_GPCR_SPI_MOSI 32'h00001000
`define SYSC_GPCR_SFP2_SCL_OFFSET 17
`define SYSC_GPCR_SFP2_SCL 32'h00020000
`define SYSC_GPCR_SFP2_SDA_OFFSET 18
`define SYSC_GPCR_SFP2_SDA 32'h00040000
`define ADDR_SYSC_HWFR                 6'hc
`define SYSC_HWFR_MEMSIZE_OFFSET 0
`define SYSC_HWFR_MEMSIZE 32'h0000000f
`define SYSC_HWFR_STORAGE_TYPE_OFFSET 8
`define SYSC_HWFR_STORAGE_TYPE 32'h00000300
`define SYSC_HWFR_MAPVER_OFFSET 12
`define SYSC_HWFR_MAPVER 32'h0000f000
`define SYSC_HWFR_STORAGE_SEC_OFFSET 16
`define SYSC_HWFR_STORAGE_SEC 32'hffff0000
`define ADDR_SYSC_HWIR                 6'h10
`define SYSC_HWIR_NAME_OFFSET 0
`define SYSC_HWIR_NAME 32'hffffffff
`define ADDR_SYSC_SDBFS                6'h14
`define SYSC_SDBFS_BADDR_OFFSET 0
`define SYSC_SDBFS_BADDR 32'hffffffff
`define ADDR_SYSC_TCR                  6'h18
`define SYSC_TCR_TDIV_OFFSET 0
`define SYSC_TCR_TDIV 32'h00000fff
`define SYSC_TCR_ENABLE_OFFSET 31
`define SYSC_TCR_ENABLE 32'h80000000
`define ADDR_SYSC_TVR                  6'h1c
`define ADDR_SYSC_DIAG_INFO            6'h20
`define SYSC_DIAG_INFO_VER_OFFSET 0
`define SYSC_DIAG_INFO_VER 32'h0000ffff
`define SYSC_DIAG_INFO_ID_OFFSET 16
`define SYSC_DIAG_INFO_ID 32'hffff0000
`define ADDR_SYSC_DIAG_NW              6'h24
`define SYSC_DIAG_NW_RW_OFFSET 0
`define SYSC_DIAG_NW_RW 32'h0000ffff
`define SYSC_DIAG_NW_RO_OFFSET 16
`define SYSC_DIAG_NW_RO 32'hffff0000
`define ADDR_SYSC_DIAG_CR              6'h28
`define SYSC_DIAG_CR_ADR_OFFSET 0
`define SYSC_DIAG_CR_ADR 32'h0000ffff
`define SYSC_DIAG_CR_RW_OFFSET 31
`define SYSC_DIAG_CR_RW 32'h80000000
`define ADDR_SYSC_DIAG_DAT             6'h2c
`define ADDR_SYSC_HWBLD                6'h30
`define SYSC_HWBLD_DATE_OFFSET 0
`define SYSC_HWBLD_DATE 32'hffffffff

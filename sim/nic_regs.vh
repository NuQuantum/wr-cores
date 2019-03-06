`define ADDR_NIC_CR                    9'h0
`define NIC_CR_RX_EN_OFFSET 0
`define NIC_CR_RX_EN 32'h00000001
`define NIC_CR_TX_EN_OFFSET 1
`define NIC_CR_TX_EN 32'h00000002
`define NIC_CR_RXTHR_EN_OFFSET 2
`define NIC_CR_RXTHR_EN 32'h00000004
`define NIC_CR_SW_RST_OFFSET 31
`define NIC_CR_SW_RST 32'h80000000
`define ADDR_NIC_SR                    9'h4
`define NIC_SR_BNA_OFFSET 0
`define NIC_SR_BNA 32'h00000001
`define NIC_SR_REC_OFFSET 1
`define NIC_SR_REC 32'h00000002
`define NIC_SR_TX_DONE_OFFSET 2
`define NIC_SR_TX_DONE 32'h00000004
`define NIC_SR_TX_ERROR_OFFSET 3
`define NIC_SR_TX_ERROR 32'h00000008
`define NIC_SR_CUR_TX_DESC_OFFSET 8
`define NIC_SR_CUR_TX_DESC 32'h00000700
`define NIC_SR_CUR_RX_DESC_OFFSET 16
`define NIC_SR_CUR_RX_DESC 32'h00070000
`define ADDR_NIC_RXBW                  9'h8
`define ADDR_NIC_MAXRXBW               9'hc
`define ADDR_NIC_EIC_IDR               9'h20
`define NIC_EIC_IDR_RCOMP_OFFSET 0
`define NIC_EIC_IDR_RCOMP 32'h00000001
`define NIC_EIC_IDR_TCOMP_OFFSET 1
`define NIC_EIC_IDR_TCOMP 32'h00000002
`define NIC_EIC_IDR_TXERR_OFFSET 2
`define NIC_EIC_IDR_TXERR 32'h00000004
`define ADDR_NIC_EIC_IER               9'h24
`define NIC_EIC_IER_RCOMP_OFFSET 0
`define NIC_EIC_IER_RCOMP 32'h00000001
`define NIC_EIC_IER_TCOMP_OFFSET 1
`define NIC_EIC_IER_TCOMP 32'h00000002
`define NIC_EIC_IER_TXERR_OFFSET 2
`define NIC_EIC_IER_TXERR 32'h00000004
`define ADDR_NIC_EIC_IMR               9'h28
`define NIC_EIC_IMR_RCOMP_OFFSET 0
`define NIC_EIC_IMR_RCOMP 32'h00000001
`define NIC_EIC_IMR_TCOMP_OFFSET 1
`define NIC_EIC_IMR_TCOMP 32'h00000002
`define NIC_EIC_IMR_TXERR_OFFSET 2
`define NIC_EIC_IMR_TXERR 32'h00000004
`define ADDR_NIC_EIC_ISR               9'h2c
`define NIC_EIC_ISR_RCOMP_OFFSET 0
`define NIC_EIC_ISR_RCOMP 32'h00000001
`define NIC_EIC_ISR_TCOMP_OFFSET 1
`define NIC_EIC_ISR_TCOMP 32'h00000002
`define NIC_EIC_ISR_TXERR_OFFSET 2
`define NIC_EIC_ISR_TXERR 32'h00000004
`define BASE_NIC_DTX                   9'h80
`define SIZE_NIC_DTX                   32'h20
`define BASE_NIC_DRX                   9'h100
`define SIZE_NIC_DRX                   32'h20

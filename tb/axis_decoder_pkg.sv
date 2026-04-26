`ifndef AXIS_DECODER_PKG
`define AXIS_DECODER_PKG

`include "axis_decoder_defines.sv"

package axis_decoder_pkg;

  typedef enum int {
    AXIS_DEC_INSTR_NONE = 0,
    AXIS_DEC_INSTR_A    = 1,
    AXIS_DEC_INSTR_B    = 2,
    AXIS_DEC_INSTR_C    = 3
  } axis_decoder_instr_type_e;

  typedef enum logic [1:0] {
    AXIS_DEC_ARB_OFF    = 2'h0,
    AXIS_DEC_ARB_ROUND  = 2'h1,
    AXIS_DEC_ARB_TARGET = 2'h2,
    AXIS_DEC_ARB_PRIOR  = 2'h3
  } axis_decoder_arb_mode_e;

  typedef bit [`AXI_DATA_O_W-1:0] axis_decoder_cmd_t;

  typedef struct {
    bit                       valid;
    axis_decoder_instr_type_e instr_type;
    logic [31:0]              raw;
    logic [31:0]              corrected;
    logic [3:0]               func;
    logic [7:0]               data0;
    logic [7:0]               data1;
    logic [5:0]               intr;
  } axis_decoder_instr_s;

  typedef struct {
    bit         enabled;
    logic [1:0] main_out;
    logic [1:0] alt_out;
    logic [7:0] stat_addr;
    logic [7:0] stat_irq_addr;
  } axis_decoder_route_rule_s;

  typedef struct {
    bit reset_round_robin;
    bit clear_fifos;
  } axis_decoder_reg_write_effect_s;

  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_INTR_BA = 8'h10;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_BA  = 8'hA0;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_CORE_BA = 8'hC0;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_DATA_BA = 8'hD0;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_FIFO_BA = 8'hF0;

  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_INTR_STAT = AXIS_DEC_INTR_BA + 8'h00;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_INTR_EN   = AXIS_DEC_INTR_BA + 8'h01;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_INTR_CLR  = AXIS_DEC_INTR_BA + 8'h02;

  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_CTRL          = AXIS_DEC_ARB_BA + 8'h00;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_ROUND_SET     = AXIS_DEC_ARB_BA + 8'h01;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_ROUND_STAT    = AXIS_DEC_ARB_BA + 8'h02;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_ROUND_IRQ     = AXIS_DEC_ARB_BA + 8'h03;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_TARGET0_SET   = AXIS_DEC_ARB_BA + 8'h04;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_TARGET0_STAT  = AXIS_DEC_ARB_BA + 8'h05;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_TARGET0_IRQ   = AXIS_DEC_ARB_BA + 8'h06;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_TARGET1_SET   = AXIS_DEC_ARB_BA + 8'h07;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_TARGET1_STAT  = AXIS_DEC_ARB_BA + 8'h08;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_TARGET1_IRQ   = AXIS_DEC_ARB_BA + 8'h09;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_TARGET2_SET   = AXIS_DEC_ARB_BA + 8'h0A;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_TARGET2_STAT  = AXIS_DEC_ARB_BA + 8'h0B;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_TARGET2_IRQ   = AXIS_DEC_ARB_BA + 8'h0C;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_PRIOR_SET     = AXIS_DEC_ARB_BA + 8'h0D;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_PRIOR_STAT    = AXIS_DEC_ARB_BA + 8'h0E;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_ARB_PRIOR_IRQ     = AXIS_DEC_ARB_BA + 8'h0F;

  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_CORE_ECC_EN       = AXIS_DEC_CORE_BA + 8'h00;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_CORE_PREPROC_EN   = AXIS_DEC_CORE_BA + 8'h01;

  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_FIFO_CLR          = AXIS_DEC_FIFO_BA + 8'h00;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_FIFO_DEPTH        = AXIS_DEC_FIFO_BA + 8'h01;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_FIFO_THRS         = AXIS_DEC_FIFO_BA + 8'h02;
  localparam logic [`APB_ADDR_W-1:0] AXIS_DEC_FIFO_IN_EN        = AXIS_DEC_FIFO_BA + 8'h0F;

  localparam logic [3:0] AXIS_DEC_OPCODE_A = 4'b0101;
  localparam logic [3:0] AXIS_DEC_OPCODE_B = 4'b1001;
  localparam logic [3:0] AXIS_DEC_OPCODE_C = 4'b1010;

  localparam logic [5:0] AXIS_DEC_INTR_FIFO_SAT = 6'b00_0001;
  localparam logic [5:0] AXIS_DEC_INTR_RES_ER   = 6'b00_0010;
  localparam logic [5:0] AXIS_DEC_INTR_ECC_2    = 6'b00_0100;
  localparam logic [5:0] AXIS_DEC_INTR_INV_OP   = 6'b00_1000;
  localparam logic [5:0] AXIS_DEC_INTR_CM_THRS  = 6'b01_0000;
  localparam logic [5:0] AXIS_DEC_INTR_NO_OUT   = 6'b10_0000;

endpackage

`endif //!AXIS_DECODER_PKG

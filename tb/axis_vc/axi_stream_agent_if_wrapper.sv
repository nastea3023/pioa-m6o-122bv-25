`ifndef AXI_STREAM_AGENT_IF_WRAPPER
`define AXI_STREAM_AGENT_IF_WRAPPER

interface axi_stream_agent_if_wrapper #(
  TDATA_W   = 1,
  TID_W     = 1,
  IS_MASTER = 1
) (input logic clk, rst_n);

  // AXI-stream signals
  axi_stream_agent_if intf(clk, rst_n);


  logic        [TDATA_W - 1 : 0] axis_data;
  logic        [TID_W   - 1 : 0] axis_id;
  logic                          axis_valid;
  logic                          axis_ready;
  logic                          axis_last;

  generate
    if (IS_MASTER == 0) begin
      assign intf.axis_data  = axis_data;
      assign intf.axis_id    = axis_id;
      assign intf.axis_valid = axis_valid;
      assign axis_ready      = intf.axis_ready;
      assign intf.axis_last  = axis_last;
    end else begin
      assign axis_data       = intf.axis_data;
      assign axis_id         = intf.axis_id;
      assign axis_valid      = intf.axis_valid;
      assign intf.axis_ready = axis_ready;
      assign axis_last       = intf.axis_last;
    end
  endgenerate

endinterface

`endif // !AXI_STREAM_AGENT_IF_WRAPPER

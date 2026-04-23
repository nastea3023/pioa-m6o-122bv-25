`ifndef AXI_STREAM_AGENT_IF
`define AXI_STREAM_AGENT_IF

interface axi_stream_agent_if(input logic clk, rst_n);

  // AXI-stream signals
  logic        [`AXI_MAX_DATA_W-1:0] axis_data;
  logic        [`AXI_ID_W    -1:0]   axis_id;
  logic                              axis_valid;
  logic                              axis_ready;
  logic                              axis_last;

endinterface

`endif // !AXI_STREAM_AGENT_IF
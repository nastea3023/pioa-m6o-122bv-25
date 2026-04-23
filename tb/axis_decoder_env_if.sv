`ifndef AXIS_DECODER_ENV_IF
`define AXIS_DECODER_ENV_IF

typedef virtual axi_stream_agent_if_wrapper #(.TDATA_W(`AXI_DATA_I_W), .TID_W(1), .IS_MASTER(1)) axis_mst_agent_if_wrapper_t;
typedef virtual axi_stream_agent_if_wrapper #(.TDATA_W(`AXI_DATA_O_W), .TID_W(1), .IS_MASTER(0)) axis_slv_agent_if_wrapper_t;

class axis_decoder_enf_if_array_wrapper;
  axis_mst_agent_if_wrapper_t mst_vif[$:`AXIS_DECODER_AXI_MS_NUM-1];
  axis_slv_agent_if_wrapper_t slv_vif[$:`AXIS_DECODER_AXI_SL_NUM-1];

  function void add_mst_if(axis_mst_agent_if_wrapper_t intf);
    mst_vif.push_back(intf);
  endfunction

  function axis_mst_agent_if_wrapper_t get_mst_if(int index);
    return mst_vif[index];
  endfunction

  function void add_slv_if(axis_slv_agent_if_wrapper_t intf);
    slv_vif.push_back(intf);
  endfunction

  function axis_slv_agent_if_wrapper_t get_slv_if(int index);
    return slv_vif[index];
  endfunction
endclass

interface axis_decoder_env_if();

  //Clock and Reset interfaces
  clk_agent_if clk_if();
  rst_agent_if rst_if();

  // Interrupt signals
  irq_agent_if irq_if();

  axi_stream_agent_if_wrapper #(
    .TDATA_W    (`AXI_DATA_I_W),
    .IS_MASTER  (1)
  ) axis_in_if [`AXIS_DECODER_AXI_MS_NUM] (clk_if.clk, rst_if.rst_n);

  axi_stream_agent_if_wrapper #(
    .TDATA_W    (`AXI_DATA_O_W),
    .IS_MASTER  (0)
  ) axis_out_if [`AXIS_DECODER_AXI_SL_NUM] (clk_if.clk, rst_if.rst_n);

  // Registers data interfaces
  apb_master_agent_if apb_if(clk_if.clk, rst_if.rst_n);

  axis_decoder_enf_if_array_wrapper wrapper = new();

  generate
    genvar i;
    for (i = 0; i < `AXIS_DECODER_AXI_MS_NUM; i++) begin
      initial begin
        wrapper.add_mst_if(axis_in_if[i]);
      end
    end
  endgenerate

  generate
    genvar k;
    for (k = 0; k < `AXIS_DECODER_AXI_SL_NUM; k++) begin
      initial begin
        wrapper.add_slv_if(axis_out_if[k]);
      end
    end
  endgenerate

  function axis_mst_agent_if_wrapper_t get_axi_in_if(int i);
    return wrapper.get_mst_if(i);
  endfunction

  function axis_slv_agent_if_wrapper_t get_axi_out_if(int k);
    return wrapper.get_slv_if(k);
  endfunction

endinterface

`endif // !AXIS_DECODER_ENV_IF

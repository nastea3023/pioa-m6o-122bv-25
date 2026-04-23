`ifndef AXI_STREAM_AGENT_CFG
`define AXI_STREAM_AGENT_CFG

class axi_stream_agent_cfg;

    virtual axi_stream_agent_if vif;

    bit master_has_tid_f;
    bit master_has_tlast_f;

    int slave_tready_active_dur_min = 1; 
    int slave_tready_active_dur_max = 1;
    int slave_tready_inactive_dur_min;
    int slave_tready_inactive_dur_max;

endclass

`endif //!AXI_STREAM_AGENT_CFG

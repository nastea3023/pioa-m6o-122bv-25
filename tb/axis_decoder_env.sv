`ifndef AXIS_DECODER_ENV
`define AXIS_DECODER_ENV

`include "clk_agent.sv"
`include "rst_agent.sv"
`include "axi_stream_agent_cfg.sv"
`include "axi_stream_master_agent.sv"
`include "axi_stream_slave_agent.sv"
`include "apb_master_agent.sv"
`include "irq_agent.sv"
`include "axis_decoder_scoreboard.sv"

class axis_decoder_env;

  // Agents instances
  clk_agent               clk_agent;
  rst_agent               rst_agent;

  axi_stream_agent_cfg    axis_master_cfg   [`AXIS_DECODER_AXI_MS_NUM];
  axi_stream_agent_cfg    axis_slave_cfg    [`AXIS_DECODER_AXI_SL_NUM];

  axi_stream_master_agent axis_master_agent [`AXIS_DECODER_AXI_MS_NUM];
  axi_stream_slave_agent  axis_slave_agent  [`AXIS_DECODER_AXI_SL_NUM];
  apb_master_agent        apb_master_agent;

  irq_agent               irq_agent;

  // Scoreboard instance
  axis_decoder_scoreboard scrb;

  // Mailbox handles
  mailbox                 rst2scrb;                           // From reset             to scoreboard
  mailbox                 in2scrb [`AXIS_DECODER_AXI_MS_NUM]; // From axi_stream_master to scoreboard
  mailbox                 out2scrb[`AXIS_DECODER_AXI_SL_NUM]; // From axi_stream_slave  to scoreboard
  mailbox                 apb2scrb;                           // From apb_master        to scoreboard
  mailbox                 irq2scrb;                           // From irq               to scoreboard

  // Virtual interface
  virtual axis_decoder_env_if vif;

  // Constructor
  function new(virtual axis_decoder_env_if vif);

    this.vif = vif;

    // Creating mailboxes
    this.rst2scrb            = new();
    this.apb2scrb            = new();
    this.irq2scrb            = new();

    foreach (axis_master_agent[i]) begin
      this.axis_master_cfg[i] = new();
      this.axis_master_cfg[i].vif = vif.get_axi_in_if(i).intf;
      this.axis_master_cfg[i].master_has_tid_f   = 1'b0;
      this.axis_master_cfg[i].master_has_tlast_f = 1'b0;
      this.in2scrb[i] = new();
      this.axis_master_agent[i] = new(axis_master_cfg[i], in2scrb[i]);
    end
    foreach (axis_slave_agent[i]) begin
      this.axis_slave_cfg[i] = new();
      this.axis_slave_cfg[i].vif = vif.get_axi_out_if(i).intf;
      this.axis_slave_cfg[i].slave_tready_active_dur_min   = 0;
      this.axis_slave_cfg[i].slave_tready_active_dur_max   = 20;
      this.axis_slave_cfg[i].slave_tready_inactive_dur_min = 0;
      this.axis_slave_cfg[i].slave_tready_inactive_dur_max = 20;
      this.out2scrb[i] = new();
      this.axis_slave_agent[i] = new(axis_slave_cfg[i], out2scrb[i]);
    end

    // Creating agents
    this.clk_agent           = new(vif.clk_if                         );
    this.rst_agent           = new(vif.rst_if,      rst2scrb          );
    this.apb_master_agent    = new(vif.apb_if,      apb2scrb          );
    this.irq_agent           = new(vif.irq_if,      irq2scrb          );

    // Creating scoreboard; you can write your code here...
    this.scrb = new(rst2scrb, apb2scrb, irq2scrb, in2scrb, out2scrb);

  endfunction : new

  // Test phases
  task pre_main();

  endtask
  
  task main();
    fork
      clk_agent.run();
      rst_agent.run();
      irq_agent.run();

      foreach (axis_master_agent[i]) begin
        axis_master_agent[i].run();
      end
      foreach (axis_slave_agent[i]) begin
        axis_slave_agent[i].run();
      end

      apb_master_agent.run();
      scrb.run();
    join_none
  endtask

  // Run task
  task run;
    pre_main();
    main();
  endtask

endclass

`endif // !AXIS_DECODER_ENV

`ifndef AXIS_DECODER_SCOREBOARD
`define AXIS_DECODER_SCOREBOARD

import axis_decoder_pkg::*;

`include "axis_decoder_scoreboard_models/axis_decoder_reg_model.sv"
`include "axis_decoder_scoreboard_models/axis_decoder_ecc_model.sv"
`include "axis_decoder_scoreboard_models/axis_decoder_core_model.sv"
`include "axis_decoder_scoreboard_models/axis_decoder_output_model.sv"
`include "axis_decoder_scoreboard_models/axis_decoder_arbiter_model.sv"

`define SCRB_ERROR(MSG) \
  begin \
    error_count++; \
    $error("TIME: %0t [axis_decoder_scoreboard] %s", $realtime, MSG); \
  end

class axis_decoder_scoreboard;

  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE BELOW OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */
  process scrb_task_job;
  int     error_count;
  int     apb_trans_count;
  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE ABOVE OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */

  mailbox rst2scrb;
  mailbox in2scrb  [`AXIS_DECODER_AXI_MS_NUM];
  mailbox out2scrb [`AXIS_DECODER_AXI_SL_NUM];
  mailbox apb2scrb;
  mailbox irq2scrb;

  axis_decoder_reg_model     reg_model;
  axis_decoder_ecc_model     ecc_model;
  axis_decoder_core_model    core_model;
  axis_decoder_output_model  output_model;
  axis_decoder_arbiter_model arbiter_model;

  function new(mailbox rst2scrb, apb2scrb, irq2scrb, in2scrb [`AXIS_DECODER_AXI_MS_NUM], out2scrb [`AXIS_DECODER_AXI_SL_NUM]);
  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE BELOW OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */
    this.error_count     = 0;
    this.apb_trans_count = 0;
  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE ABOVE OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */
    this.rst2scrb        = rst2scrb;
    this.in2scrb         = in2scrb;
    this.out2scrb        = out2scrb;
    this.apb2scrb        = apb2scrb;
    this.irq2scrb        = irq2scrb;

    build_models();
    reset_model();
  endfunction

  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE BELOW OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */
  task run();
    scrb_task_job = process::self();
    main();
  endtask
  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE ABOVE OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */

  task main();
    fork
      collect_reset();
      collect_irq();
      collect_apb();
      collect_axi_input();
      collect_axi_outputs();
    join
  endtask : main

  /* !!!-----------------------------------------------------!!! */
  /* !!! DO NOT DELETE TASK BELOW OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!-----------------------------------------------------!!! */
  task shutdown();
    foreach (out2scrb[i]) begin
      int pending;

      pending = output_model.pending_count(i);
      if ($test$plusargs("SCRB_STRICT_SHUTDOWN") && pending != 0) begin
        report_error($sformatf("Output %0d still has %0d expected command(s)", i, pending));
      end
    end
  endtask
  /* !!!-----------------------------------------------------!!! */
  /* !!! DO NOT DELETE TASK ABOVE OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!-----------------------------------------------------!!! */

  task automatic process_apb_transaction(apb_master_transaction tr);
    axis_decoder_reg_write_effect_s effect;
    logic [7:0] read_exp;

    apb_trans_count++;

    // Briefing constraint: do not score AXI-S/APB protocol features.
    // Invalid APB accesses are ignored here; the model checks DUT-visible
    // register behavior after completed monitor transactions.
    if (!reg_model.is_valid_addr(tr.addr)) begin
      return;
    end

    read_exp  = reg_model.read(tr.addr);

    if (!tr.is_write && tr.data !== read_exp) begin
      report_error($sformatf("CSR read mismatch at 0x%02h: exp=0x%02h act=0x%02h",
                             tr.addr, read_exp, tr.data));
    end

    if (tr.is_write) begin
      effect = reg_model.write(tr.addr, tr.data);
      apply_reg_write_effect(effect);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Build and reset
  // ---------------------------------------------------------------------------

  function void build_models();
    reg_model     = new();
    ecc_model     = new();
    output_model  = new();
    core_model    = new(reg_model, ecc_model);
    arbiter_model = new(reg_model, output_model);
  endfunction

  function void reset_model();
    reg_model.reset();
    output_model.reset();
    arbiter_model.reset();
  endfunction

  function void apply_reg_write_effect(axis_decoder_reg_write_effect_s effect);
    if (effect.clear_fifos) begin
      output_model.reset();
    end

    if (effect.reset_round_robin) begin
      arbiter_model.reset();
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Collectors
  // ---------------------------------------------------------------------------

  task collect_reset();
    rst_transaction tr;

    forever begin
      rst2scrb.get(tr);
      reset_model();
    end
  endtask

  task collect_irq();
    irq_transaction tr;

    forever begin
      irq2scrb.get(tr);
      check_irq(tr);
    end
  endtask

  task collect_apb();
    apb_master_transaction tr;

    forever begin
      apb2scrb.get(tr);
      process_apb_transaction(tr);
    end
  endtask

  task collect_axi_input();
    axi_stream_transaction tr;

    forever begin
      in2scrb[0].get(tr);
      predict_axi_input(tr);
    end
  endtask

  task collect_axi_outputs();
    foreach (out2scrb[i]) begin
      automatic int out_idx = i;
      fork
        collect_one_axi_output(out_idx);
      join_none
    end
  endtask

  task collect_one_axi_output(int out_idx);
    axi_stream_transaction tr;

    forever begin
      out2scrb[out_idx].get(tr);
      error_count += output_model.compare(out_idx, tr);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Prediction and checks
  // ---------------------------------------------------------------------------

  function void predict_axi_input(axi_stream_transaction tr);
    axis_decoder_instr_s instr;
    axis_decoder_cmd_t   cmd;

    foreach (tr.data[i]) begin
      instr = core_model.decode(tr.data[i][31:0]);

      if (instr.intr != 6'h00) begin
        reg_model.raise_intr(instr.intr);
      end else if (instr.valid) begin
        cmd = core_model.make_cmd(instr);
        arbiter_model.route(instr.instr_type, instr.func, cmd);
      end
    end
  endfunction

  function void check_irq(irq_transaction tr);
    if ($test$plusargs("SCRB_CHECK_IRQ") && tr.value !== reg_model.irq_expected()) begin
      report_error($sformatf("IRQ mismatch: exp=%0b act=%0b", reg_model.irq_expected(), tr.value));
    end
  endfunction

  function void report_error(string msg);
    `SCRB_ERROR(msg)
  endfunction

  `undef SCRB_ERROR

endclass

`endif // !AXIS_DECODER_SCOREBOARD

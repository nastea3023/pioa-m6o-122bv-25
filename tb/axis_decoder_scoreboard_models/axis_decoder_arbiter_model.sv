`ifndef AXIS_DECODER_ARBITER_MODEL
`define AXIS_DECODER_ARBITER_MODEL

class axis_decoder_arbiter_model;

  axis_decoder_reg_model    reg_model;
  axis_decoder_output_model output_model;

  int unsigned rr_out_idx;
  int unsigned rr_sent_on_cur_out;

  function new(axis_decoder_reg_model reg_model, axis_decoder_output_model output_model);
    this.reg_model    = reg_model;
    this.output_model = output_model;
    reset();
  endfunction

  function void reset();
    rr_out_idx         = 0;
    rr_sent_on_cur_out = 0;
  endfunction

  function void route(axis_decoder_instr_type_e instr_type,
                      logic [3:0] func,
                      axis_decoder_cmd_t cmd);
    axis_decoder_arb_mode_e mode;

    mode = axis_decoder_arb_mode_e'(reg_model.get(AXIS_DEC_ARB_CTRL)[1:0]);

    case (mode)
      AXIS_DEC_ARB_ROUND : route_round(func, cmd);
      AXIS_DEC_ARB_TARGET: route_target(instr_type, cmd);
      AXIS_DEC_ARB_PRIOR : route_prior(cmd);
      default: begin
      end
    endcase
  endfunction

  function void route_round(logic [3:0] func, axis_decoder_cmd_t cmd);
    logic [3:0] func_mask;
    int unsigned cm_per_out;

    func_mask  = reg_model.get(AXIS_DEC_ARB_ROUND_SET)[3:0];
    cm_per_out = reg_model.get(AXIS_DEC_ARB_ROUND_SET)[5:4];
    if (cm_per_out == 0) cm_per_out = 1;

    if ((func_mask & func) != func_mask) begin
      reg_model.inc_stat(AXIS_DEC_ARB_ROUND_STAT, AXIS_DEC_ARB_ROUND_IRQ);
      return;
    end

    push_to_output(rr_out_idx, cmd);
    rr_sent_on_cur_out++;

    if (rr_sent_on_cur_out >= cm_per_out) begin
      rr_sent_on_cur_out = 0;
      rr_out_idx = (rr_out_idx + 1) % `AXIS_DECODER_AXI_SL_NUM;
    end
  endfunction

  function void route_target(axis_decoder_instr_type_e instr_type, axis_decoder_cmd_t cmd);
    axis_decoder_route_rule_s rule;

    rule = target_rule_for(instr_type);
    if (!rule.enabled) return;
    if (!output_model.is_real_output(rule.main_out)) return;

    push_to_output(rule.main_out, cmd);
    reg_model.inc_stat(rule.stat_addr, rule.stat_irq_addr);

    if (output_model.is_real_output(rule.alt_out) && rule.alt_out != rule.main_out) begin
      push_to_output(rule.alt_out, cmd);
    end
  endfunction

  function void route_prior(axis_decoder_cmd_t cmd);
    axis_decoder_route_rule_s rule;

    rule = prior_rule();

    if (output_model.is_real_output(rule.main_out)) begin
      push_to_output(rule.main_out, cmd);
      reg_model.inc_stat(rule.stat_addr, rule.stat_irq_addr);
    end else if (output_model.is_real_output(rule.alt_out)) begin
      push_to_output(rule.alt_out, cmd);
      reg_model.inc_stat(rule.stat_addr, rule.stat_irq_addr);
    end
  endfunction

  function void push_to_output(int out_idx, axis_decoder_cmd_t cmd);
    int unsigned depth;
    int unsigned threshold;

    depth     = reg_model.get(AXIS_DEC_FIFO_DEPTH)[3:0];
    threshold = reg_model.get(AXIS_DEC_FIFO_THRS)[3:0];

    if (output_model.enqueue(out_idx, cmd, depth, threshold)) begin
      reg_model.raise_intr(AXIS_DEC_INTR_FIFO_SAT);
    end
  endfunction

  function axis_decoder_route_rule_s target_rule_for(axis_decoder_instr_type_e instr_type);
    axis_decoder_route_rule_s rule;
    logic [7:0] set_addr;

    case (instr_type)
      AXIS_DEC_INSTR_A: begin
        set_addr           = AXIS_DEC_ARB_TARGET0_SET;
        rule.stat_addr     = AXIS_DEC_ARB_TARGET0_STAT;
        rule.stat_irq_addr = AXIS_DEC_ARB_TARGET0_IRQ;
      end
      AXIS_DEC_INSTR_B: begin
        set_addr           = AXIS_DEC_ARB_TARGET1_SET;
        rule.stat_addr     = AXIS_DEC_ARB_TARGET1_STAT;
        rule.stat_irq_addr = AXIS_DEC_ARB_TARGET1_IRQ;
      end
      AXIS_DEC_INSTR_C: begin
        set_addr           = AXIS_DEC_ARB_TARGET2_SET;
        rule.stat_addr     = AXIS_DEC_ARB_TARGET2_STAT;
        rule.stat_irq_addr = AXIS_DEC_ARB_TARGET2_IRQ;
      end
      default: begin
        set_addr           = AXIS_DEC_ARB_TARGET0_SET;
        rule.stat_addr     = 8'h00;
        rule.stat_irq_addr = 8'h00;
      end
    endcase

    rule.enabled  = reg_model.get(set_addr)[0];
    rule.main_out = reg_model.get(set_addr)[5:4];
    rule.alt_out  = reg_model.get(set_addr)[7:6];
    return rule;
  endfunction

  function axis_decoder_route_rule_s prior_rule();
    prior_rule.enabled       = 1'b1;
    prior_rule.main_out      = reg_model.get(AXIS_DEC_ARB_PRIOR_SET)[1:0];
    prior_rule.alt_out       = reg_model.get(AXIS_DEC_ARB_PRIOR_SET)[3:2];
    prior_rule.stat_addr     = AXIS_DEC_ARB_PRIOR_STAT;
    prior_rule.stat_irq_addr = AXIS_DEC_ARB_PRIOR_IRQ;
  endfunction

endclass

`endif // AXIS_DECODER_ARBITER_MODEL

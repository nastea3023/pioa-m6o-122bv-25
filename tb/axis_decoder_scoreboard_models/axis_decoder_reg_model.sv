`ifndef AXIS_DECODER_REG_MODEL
`define AXIS_DECODER_REG_MODEL

class axis_decoder_reg_model;

  logic [7:0] regs [256];
  bit         irq_exp;

  function new();
    reset();
  endfunction

  function void reset();
    foreach (regs[i]) begin
      regs[i] = 8'h00;
    end

    regs[AXIS_DEC_CORE_ECC_EN]     = 8'h01;
    regs[AXIS_DEC_CORE_PREPROC_EN] = 8'h01;

    regs[AXIS_DEC_ARB_ROUND_SET]   = 8'h10;
    regs[AXIS_DEC_ARB_TARGET0_SET] = 8'hF0;
    regs[AXIS_DEC_ARB_TARGET1_SET] = 8'hF0;
    regs[AXIS_DEC_ARB_TARGET2_SET] = 8'hF0;
    regs[AXIS_DEC_ARB_PRIOR_SET]   = 8'h0F;

    regs[AXIS_DEC_FIFO_DEPTH]      = 8'h0F;
    regs[AXIS_DEC_FIFO_THRS]       = 8'h0F;
    regs[AXIS_DEC_INTR_EN]         = 8'h3F;
    irq_exp                        = 1'b0;
  endfunction

  function bit is_valid_addr(logic [7:0] addr);
    return is_intr_addr(addr) || is_arb_addr(addr) ||
           is_core_addr(addr) || is_data_addr(addr) ||
           is_fifo_addr(addr);
  endfunction

  function logic [7:0] read(logic [7:0] addr);
    if (addr == AXIS_DEC_INTR_CLR) return 8'h00;
    return regs[addr] & read_mask(addr);
  endfunction

  function axis_decoder_reg_write_effect_s write(logic [7:0] addr, logic [7:0] data);
    axis_decoder_reg_write_effect_s effect;

    effect.reset_round_robin = 1'b0;
    effect.clear_fifos       = 1'b0;

    if (addr == AXIS_DEC_INTR_STAT) return effect;

    if (addr == AXIS_DEC_INTR_EN) begin
      regs[addr] = data & 8'h3F;
      update_irq();
      return effect;
    end

    if (addr == AXIS_DEC_INTR_CLR) begin
      regs[AXIS_DEC_INTR_STAT] &= ~(data & 8'h3F);
      update_irq();
      return effect;
    end

    if (is_stat_addr(addr)) begin
      if (data == 8'h00) begin
        regs[addr] = 8'h00;
        update_irq();
      end
      return effect;
    end

    if (addr == AXIS_DEC_ARB_ROUND_SET) begin
      regs[addr][3:0] = data[3:0];
      if (data[5:4] != 2'h0) begin
        regs[addr][5:4] = data[5:4];
        effect.reset_round_robin = 1'b1;
      end
      return effect;
    end

    if (addr == AXIS_DEC_FIFO_CLR) begin
      regs[addr] = data & 8'h01;
      if (data[0]) begin
        regs[addr] = 8'h00;
        effect.clear_fifos = 1'b1;
      end
      return effect;
    end

    if (addr == AXIS_DEC_FIFO_DEPTH) begin
      if (data[3:0] != 4'h0) regs[addr] = data & 8'h0F;
      return effect;
    end

    regs[addr] = data & read_mask(addr);
    if (is_irq_cfg_addr(addr)) update_irq();
    return effect;
  endfunction

  function void raise_intr(logic [5:0] intr_mask);
    regs[AXIS_DEC_INTR_STAT] |= intr_mask;
    update_irq();
  endfunction

  function void inc_stat(logic [7:0] stat_addr, logic [7:0] stat_irq_addr);
    regs[stat_addr] = regs[stat_addr] + 8'h01;

    if (regs[stat_irq_addr] != 8'h00 && regs[stat_addr] >= regs[stat_irq_addr]) begin
      raise_intr(AXIS_DEC_INTR_CM_THRS);
    end
  endfunction

  function bit irq_expected();
    return irq_exp;
  endfunction

  function logic [7:0] get(logic [7:0] addr);
    return regs[addr];
  endfunction

  function bit bit_is_set(logic [7:0] addr, int bit_idx);
    return regs[addr][bit_idx];
  endfunction

  function void update_irq();
    irq_exp = ((regs[AXIS_DEC_INTR_STAT] & regs[AXIS_DEC_INTR_EN] & 8'h3F) != 8'h00);
  endfunction

  function logic [7:0] read_mask(logic [7:0] addr);
    if (addr == AXIS_DEC_INTR_STAT || addr == AXIS_DEC_INTR_EN) return 8'h3F;
    if (addr == AXIS_DEC_CORE_ECC_EN || addr == AXIS_DEC_CORE_PREPROC_EN) return 8'h01;
    if (addr == AXIS_DEC_FIFO_CLR || addr == AXIS_DEC_FIFO_IN_EN) return 8'h01;
    if (addr == AXIS_DEC_FIFO_DEPTH || addr == AXIS_DEC_FIFO_THRS) return 8'h0F;
    if (addr == AXIS_DEC_ARB_CTRL) return 8'h03;
    if (addr == AXIS_DEC_ARB_ROUND_SET) return 8'h3F;
    if (is_target_set_addr(addr)) return 8'hF1;
    if (addr == AXIS_DEC_ARB_PRIOR_SET) return 8'h0F;
    return 8'hFF;
  endfunction

  function bit is_intr_addr(logic [7:0] addr);
    return addr inside {[AXIS_DEC_INTR_STAT:AXIS_DEC_INTR_CLR]};
  endfunction

  function bit is_arb_addr(logic [7:0] addr);
    return addr inside {[AXIS_DEC_ARB_CTRL:AXIS_DEC_ARB_PRIOR_IRQ]};
  endfunction

  function bit is_core_addr(logic [7:0] addr);
    return addr inside {[AXIS_DEC_CORE_ECC_EN:AXIS_DEC_CORE_PREPROC_EN]};
  endfunction

  function bit is_data_addr(logic [7:0] addr);
    return addr inside {[AXIS_DEC_DATA_BA:AXIS_DEC_DATA_BA + 8'h0F]};
  endfunction

  function bit is_fifo_addr(logic [7:0] addr);
    return addr inside {AXIS_DEC_FIFO_CLR, AXIS_DEC_FIFO_DEPTH,
                        AXIS_DEC_FIFO_THRS, AXIS_DEC_FIFO_IN_EN};
  endfunction

  function bit is_stat_addr(logic [7:0] addr);
    return addr inside {AXIS_DEC_ARB_ROUND_STAT,
                        AXIS_DEC_ARB_TARGET0_STAT,
                        AXIS_DEC_ARB_TARGET1_STAT,
                        AXIS_DEC_ARB_TARGET2_STAT,
                        AXIS_DEC_ARB_PRIOR_STAT};
  endfunction

  function bit is_irq_cfg_addr(logic [7:0] addr);
    return addr inside {AXIS_DEC_INTR_EN,
                        AXIS_DEC_ARB_ROUND_IRQ,
                        AXIS_DEC_ARB_TARGET0_IRQ,
                        AXIS_DEC_ARB_TARGET1_IRQ,
                        AXIS_DEC_ARB_TARGET2_IRQ,
                        AXIS_DEC_ARB_PRIOR_IRQ};
  endfunction

  function bit is_target_set_addr(logic [7:0] addr);
    return addr inside {AXIS_DEC_ARB_TARGET0_SET,
                        AXIS_DEC_ARB_TARGET1_SET,
                        AXIS_DEC_ARB_TARGET2_SET};
  endfunction

endclass

`endif // AXIS_DECODER_REG_MODEL

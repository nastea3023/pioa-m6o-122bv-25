`ifndef AXIS_DECODER_CORE_MODEL
`define AXIS_DECODER_CORE_MODEL

class axis_decoder_core_model;

  axis_decoder_reg_model reg_model;
  axis_decoder_ecc_model ecc_model;

  function new(axis_decoder_reg_model reg_model, axis_decoder_ecc_model ecc_model);
    this.reg_model = reg_model;
    this.ecc_model = ecc_model;
  endfunction

  function axis_decoder_instr_s decode(logic [31:0] raw_instr);
    axis_decoder_instr_s instr;
    logic [31:0] checked;
    logic [5:0]  ecc_intr;

    instr.valid      = 1'b0;
    instr.raw        = raw_instr;
    instr.corrected  = raw_instr;
    instr.func       = 4'h0;
    instr.data0      = 8'h00;
    instr.data1      = 8'h00;
    instr.intr       = 6'h00;
    instr.instr_type = AXIS_DEC_INSTR_NONE;

    checked = raw_instr;
    if (ecc_enabled()) begin
      checked = ecc_model.correct(raw_instr, ecc_intr);
      if (ecc_intr != 6'h00) begin
        instr.intr = ecc_intr;
        return instr;
      end
    end

    instr.corrected  = checked;
    instr.instr_type = decode_instr_type(checked[3:0]);

    if (instr.instr_type == AXIS_DEC_INSTR_NONE) begin
      instr.intr = AXIS_DEC_INTR_INV_OP;
      return instr;
    end

    if (!reserved_bits_ok(checked, instr.instr_type)) begin
      instr.intr = AXIS_DEC_INTR_RES_ER;
      return instr;
    end

    fill_operands(instr);
    if (preproc_enabled()) begin
      preprocess(instr.func, instr.data0, instr.data1);
    end

    instr.valid = 1'b1;
    return instr;
  endfunction

  function axis_decoder_cmd_t make_cmd(axis_decoder_instr_s instr);
    return {4'h5, instr.func, instr.data1, instr.data0};
  endfunction

  function bit ecc_enabled();
    return reg_model.bit_is_set(AXIS_DEC_CORE_ECC_EN, 0);
  endfunction

  function bit preproc_enabled();
    return reg_model.bit_is_set(AXIS_DEC_CORE_PREPROC_EN, 0);
  endfunction

  function axis_decoder_instr_type_e decode_instr_type(logic [3:0] opcode);
    case (opcode)
      AXIS_DEC_OPCODE_A: return AXIS_DEC_INSTR_A;
      AXIS_DEC_OPCODE_B: return AXIS_DEC_INSTR_B;
      AXIS_DEC_OPCODE_C: return AXIS_DEC_INSTR_C;
      default:           return AXIS_DEC_INSTR_NONE;
    endcase
  endfunction

  function bit reserved_bits_ok(logic [31:0] instr, axis_decoder_instr_type_e instr_type);
    case (instr_type)
      AXIS_DEC_INSTR_A: return (instr[25:22] == 4'b0011) &&
                                (instr[13:10] == 4'b1010) &&
                                (instr[5:4]   == 2'b11);
      AXIS_DEC_INSTR_B: return (instr[25:24] == 2'b11) &&
                                (instr[19]    == 1'b0) &&
                                (instr[10:8]  == 3'b101);
      AXIS_DEC_INSTR_C: return (instr[21:20] == 2'b10);
      default:          return 1'b0;
    endcase
  endfunction

  function void fill_operands(ref axis_decoder_instr_s instr);
    logic [3:0] reg0;
    logic [3:0] reg1;

    case (instr.instr_type)
      AXIS_DEC_INSTR_A: begin
        instr.func = instr.corrected[21:18];
        reg1       = instr.corrected[17:14];
        reg0       = instr.corrected[9:6];
        instr.data0 = preproc_enabled() ? reg_model.get(AXIS_DEC_DATA_BA + reg0) : {4'h0, reg0};
        instr.data1 = preproc_enabled() ? reg_model.get(AXIS_DEC_DATA_BA + reg1) : {4'h0, reg1};
      end
      AXIS_DEC_INSTR_B: begin
        instr.func  = instr.corrected[23:20];
        reg0        = instr.corrected[7:4];
        instr.data0 = preproc_enabled() ? reg_model.get(AXIS_DEC_DATA_BA + reg0) : {4'h0, reg0};
        instr.data1 = instr.corrected[18:11];
      end
      AXIS_DEC_INSTR_C: begin
        instr.func  = instr.corrected[25:22];
        instr.data0 = instr.corrected[11:4];
        instr.data1 = instr.corrected[19:12];
      end
      default: begin
      end
    endcase
  endfunction

  function void preprocess(logic [3:0] func, ref logic [7:0] data0, ref logic [7:0] data1);
    logic [7:0] tmp;

    case (func)
      4'b0010, 4'b0011: data0 = ~data0;
      4'b0110, 4'b0111: data1 = ~data1;
      4'b0101: begin
        tmp   = data0;
        data0 = data1;
        data1 = tmp;
      end
      4'b1000, 4'b1001: data0 = data0 << 1;
      4'b1100, 4'b1101: data1 = data1 << 1;
      4'b1010, 4'b1011,
      4'b1110, 4'b1111: data0 = mirror8(data0);
      default: begin
      end
    endcase
  endfunction

  function logic [7:0] mirror8(logic [7:0] data);
    for (int i = 0; i < 8; i++) begin
      mirror8[i] = data[7-i];
    end
  endfunction

endclass

`endif // AXIS_DECODER_CORE_MODEL

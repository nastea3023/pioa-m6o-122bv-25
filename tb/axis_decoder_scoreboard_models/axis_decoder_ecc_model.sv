`ifndef AXIS_DECODER_ECC_MODEL
`define AXIS_DECODER_ECC_MODEL

class axis_decoder_ecc_model;

  function logic [31:0] correct(logic [31:0] raw_instr, output logic [5:0] intr);
    logic [25:0] data;
    logic [4:0]  got_parity;
    logic [4:0]  calc_parity;
    logic [4:0]  syndrome;
    bit          parity_mismatch;
    int          data_bit_idx;

    correct         = raw_instr;
    intr            = 6'h00;
    data            = raw_instr[25:0];
    got_parity      = raw_instr[31:27];
    calc_parity     = calc_hamming_parity(data);
    syndrome        = got_parity ^ calc_parity;
    parity_mismatch = (^({got_parity, raw_instr[26], data}) != 1'b0);

    if (syndrome != 5'h00 && !parity_mismatch) begin
      intr = AXIS_DEC_INTR_ECC_2;
    end else if (syndrome != 5'h00 && parity_mismatch) begin
      data_bit_idx = hamming_pos_to_data_idx(syndrome);
      if (data_bit_idx >= 0 && data_bit_idx < 26) begin
        correct[data_bit_idx] = ~correct[data_bit_idx];
      end
    end
  endfunction

  function logic [4:0] calc_hamming_parity(logic [25:0] data);
    int data_idx;
    logic [31:1] codeword;

    codeword = '0;
    data_idx = 0;
    for (int pos = 1; pos <= 31; pos++) begin
      if (!is_hamming_parity_pos(pos)) begin
        codeword[pos] = data[data_idx];
        data_idx++;
      end
    end

    for (int p = 0; p < 5; p++) begin
      calc_hamming_parity[p] = 1'b0;
      for (int pos = 1; pos <= 31; pos++) begin
        if ((pos & (1 << p)) != 0) begin
          calc_hamming_parity[p] ^= codeword[pos];
        end
      end
    end
  endfunction

  function bit is_hamming_parity_pos(int pos);
    return pos inside {1, 2, 4, 8, 16};
  endfunction

  function int hamming_pos_to_data_idx(int pos);
    int data_idx;

    data_idx = 0;
    for (int i = 1; i <= 31; i++) begin
      if (!is_hamming_parity_pos(i)) begin
        if (i == pos) return data_idx;
        data_idx++;
      end
    end

    return -1;
  endfunction

endclass

`endif // AXIS_DECODER_ECC_MODEL

`ifndef AXIS_DECODER_OUTPUT_MODEL
`define AXIS_DECODER_OUTPUT_MODEL

class axis_decoder_output_model;

  axis_decoder_cmd_t exp_q [`AXIS_DECODER_AXI_SL_NUM][$];
  int unsigned       fifo_level [`AXIS_DECODER_AXI_SL_NUM];

  function void reset();
    foreach (exp_q[i]) begin
      exp_q[i].delete();
      fifo_level[i] = 0;
    end
  endfunction

  function bit enqueue(int out_idx, axis_decoder_cmd_t cmd, int unsigned depth, int unsigned threshold);
    if (!is_real_output(out_idx)) return 1'b0;

    exp_q[out_idx].push_back(cmd);
    fifo_level[out_idx]++;

    if (threshold > depth) threshold = depth;
    return threshold != 0 && fifo_level[out_idx] >= threshold;
  endfunction

  function int compare(int out_idx, axi_stream_transaction tr);
    axis_decoder_cmd_t actual;
    axis_decoder_cmd_t expected;

    compare = 0;

    foreach (tr.data[i]) begin
      actual = tr.data[i][`AXI_DATA_O_W-1:0];
      pop_level(out_idx);

      if (exp_q[out_idx].size() == 0) begin
        compare++;
        $error("TIME: %0t [axis_decoder_output_model] Unexpected AXI output[%0d] command 0x%06h",
               $realtime, out_idx, actual);
      end else begin
        expected = exp_q[out_idx].pop_front();
        if (actual !== expected) begin
          compare++;
          $error("TIME: %0t [axis_decoder_output_model] AXI output[%0d] mismatch: exp=0x%06h act=0x%06h",
                 $realtime, out_idx, expected, actual);
        end
      end
    end
  endfunction

  function int pending_count(int out_idx);
    if (!is_real_output(out_idx)) return 0;
    return exp_q[out_idx].size();
  endfunction

  function bit is_real_output(int out_idx);
    return out_idx >= 0 && out_idx < `AXIS_DECODER_AXI_SL_NUM;
  endfunction

  function void pop_level(int out_idx);
    if (is_real_output(out_idx) && fifo_level[out_idx] > 0) begin
      fifo_level[out_idx]--;
    end
  endfunction

endclass

`endif // AXIS_DECODER_OUTPUT_MODEL

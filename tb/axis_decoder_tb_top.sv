`ifndef AXIS_DECODER_TB_TOP
`define AXIS_DECODER_TB_TOP

`include "axis_file_tracer.sv"
`include "apb3_file_tracer.sv"
`include "axis_decoder_defines.sv"
`include "axis_decoder_env_if.sv"
`include "axis_decoder_env.sv"
`include "axis_decoder_base_test.svp"
`include "axis_decoder_clk_rst_test.svp"
`include "axis_decoder_reg_test.svp"
`include "axis_decoder_direct_test.svp"
`include "axis_decoder_arbiter_base_test.svp"
`include "axis_decoder_arbiter_round_test.svp"
`include "axis_decoder_arbiter_target_test.svp"
`include "axis_decoder_arbiter_prior_test.svp"
`include "axis_decoder_core_test.svp"
`include "axis_decoder_data_reg_test.svp"
`include "axis_decoder_fifo_test.svp"
`include "axis_decoder_arbiter_intr_test.svp"
`include "axis_decoder_core_interrupt_test.svp"
`include "axis_decoder_fifo_interrupt_test.svp"
`include "axis_decoder_reset_on_the_fly_test.svp"

module axis_decoder_tb_top;

  axis_decoder_env_if  env_if();

  axis_decoder_env     env;

  axis_decoder_base_test              test;
  axis_decoder_clk_rst_test           clk_rst_test;
  axis_decoder_reg_test               reg_test;
  axis_decoder_direct_test            direct_test;
  axis_decoder_arbiter_round_test     arbiter_round_test;
  axis_decoder_arbiter_target_test    arbiter_target_test;
  axis_decoder_arbiter_prior_test     arbiter_prior_test;
  axis_decoder_core_test              core_test;
  axis_decoder_data_reg_test          data_reg_test;
  axis_decoder_fifo_test              fifo_test;
  axis_decoder_core_interrupt_test    core_interrupt_test;
  axis_decoder_arbiter_intr_test      arbiter_intr_test;
  axis_decoder_fifo_interrupt_test    fifo_interrupt_test;
  axis_decoder_reset_on_the_fly_test  reset_on_the_fly_test;

  // AXI-S Slave interface
  logic [`AXI_DATA_I_W-1:0] tdata_s_i  [`AXIS_DECODER_AXI_MS_NUM];
  logic                     tvalid_s_i [`AXIS_DECODER_AXI_MS_NUM];
  logic                     tready_s_o [`AXIS_DECODER_AXI_MS_NUM];

  // AXI-S Master interface
  logic [`AXI_DATA_O_W-1:0] tdata_m_o  [`AXIS_DECODER_AXI_SL_NUM];
  logic                     tvalid_m_o [`AXIS_DECODER_AXI_SL_NUM];
  logic                     tready_m_i [`AXIS_DECODER_AXI_SL_NUM];

  // DUT instance
  axi_stream_decoder_top #(
    .AXI_TDATA_WIDTH_IN (`AXI_DATA_I_W           ),
    .AXI_TDATA_WIDTH_OUT(`AXI_DATA_O_W           ),
    .APB_PADDR_WIDTH    (`APB_ADDR_W             ),
    .APB_PDATA_WIDTH    (`APB_DATA_W             ),
    .OUT_NUM            (`AXIS_DECODER_AXI_SL_NUM)
  ) top (
    .clk_i       (env_if.clk_if.clk    ),
    .rst_n_i     (env_if.rst_if.rst_n  ),
    .irq_o       (env_if.irq_if.irq    ),

    .paddr_i     (env_if.apb_if.paddr  ),
    .prdata_o    (env_if.apb_if.prdata ),
    .pwdata_i    (env_if.apb_if.pwdata ),
    .pready_o    (env_if.apb_if.pready ),
    .penable_i   (env_if.apb_if.penable),
    .pwrite_i    (env_if.apb_if.pwrite ),
    .pslverr_o   (env_if.apb_if.pslverr),
    .psel_i      (1'b1                 ),

    .tdata_s_i   (tdata_s_i [0]        ),
    .tvalid_s_i  (tvalid_s_i[0]        ),
    .tready_s_o  (tready_s_o[0]        ),

    .tdata_m_o   (tdata_m_o            ),
    .tvalid_m_o  (tvalid_m_o           ),
    .tready_m_i  (tready_m_i           )
  );

  `ifdef TRACER_EN
    apb3_file_tracer #(
      .ADDR_WIDTH(`APB_ADDR_W),
      .DATA_WIDTH(`APB_DATA_W),
      .LOG_FILE  ("apb_trace.log")
    ) apb_tracer (
      .pclk   (env_if.clk_if.clk    ),
      .presetn(env_if.rst_if.rst_n  ),
      .paddr  (env_if.apb_if.paddr  ),
      .psel   (1'b1                 ),
      .penable(env_if.apb_if.penable),
      .pwrite (env_if.apb_if.pwrite ),
      .pwdata (env_if.apb_if.pwdata ),
      .prdata (env_if.apb_if.prdata ),
      .pready (env_if.apb_if.pready ),
      .pslverr(env_if.apb_if.pslverr)
    );

    generate;
      for (genvar i = 0; i < `AXIS_DECODER_AXI_MS_NUM; ++i) begin : gen_axis_in_tracers
        axis_file_tracer #(
          .DATA_WIDTH(`AXI_DATA_I_W),
          .LOG_FILE  ($sformatf("axis_in_trace_%0d.log", i))
        ) axis_in_tracer (
          .clk    (env_if.clk_if.clk),
          .aresetn(env_if.rst_if.rst_n),
          .tdata  (tdata_s_i [i]),
          .tvalid (tvalid_s_i[i]),
          .tready (tready_s_o[i])
        );
      end
    endgenerate

    generate;
      for (genvar i = 0; i < `AXIS_DECODER_AXI_SL_NUM; ++i) begin : gen_axis_out_tracers
        axis_file_tracer #(
          .DATA_WIDTH(`AXI_DATA_O_W),
          .LOG_FILE  ($sformatf("axis_out_trace_%0d.log", i))
        ) axis_out_tracer (
          .clk    (env_if.clk_if.clk),
          .aresetn(env_if.rst_if.rst_n),
          .tdata  (tdata_m_o [i]),
          .tvalid (tvalid_m_o[i]),
          .tready (tready_m_i[i])
        );
      end
    endgenerate
  `endif // TRACER_EN

  generate
    for (genvar i = 0; i < `AXIS_DECODER_AXI_MS_NUM; i++) begin
      assign tdata_s_i[i]  = env_if.axis_in_if[i].axis_data;
      assign tvalid_s_i[i] = env_if.axis_in_if[i].axis_valid;
      assign env_if.axis_in_if[i].axis_ready = tready_s_o[i];
    end

    for (genvar k = 0; k < `AXIS_DECODER_AXI_SL_NUM; k++) begin
      assign env_if.axis_out_if[k].axis_data  = tdata_m_o[k];
      assign env_if.axis_out_if[k].axis_valid = tvalid_m_o[k];
      assign tready_m_i[k] = env_if.axis_out_if[k].axis_ready;
    end
  endgenerate


  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE BELOW OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */
  // Top process
  initial begin
    // Set time format
    $timeformat(-12, 0, " ps", 10);

    if ($test$plusargs("REG_TEST")) begin
      env = new(env_if);
      reg_test = new(env);
      reg_test.test_name = "REG_TEST";
      reg_test.run();
      wait(reg_test.end_of_test_evt.triggered);
    end

    if ($test$plusargs("ARBITER_ROUND_TEST")) begin
      env = new(env_if);
      arbiter_round_test = new(env);
      arbiter_round_test.test_name = "ARBITER_ROUND_TEST";
      arbiter_round_test.run();
      wait(arbiter_round_test.end_of_test_evt.triggered);
    end

    if ($test$plusargs("ARBITER_TARGET_TEST")) begin
      env = new(env_if);
      arbiter_target_test = new(env);
      arbiter_target_test.test_name = "ARBITER_TARGET_TEST";
      arbiter_target_test.run();
      wait(arbiter_target_test.end_of_test_evt.triggered);
    end

    if ($test$plusargs("ARBITER_PRIOR_TEST")) begin
      env = new(env_if);
      arbiter_prior_test = new(env);
      arbiter_prior_test.test_name = "ARBITER_PRIOR_TEST";
      arbiter_prior_test.run();
      wait(arbiter_prior_test.end_of_test_evt.triggered);
    end

    if ($test$plusargs("CORE_TEST")) begin
      env = new(env_if);
      core_test = new(env);
      core_test.test_name = "CORE_TEST";
      core_test.run();
      wait(core_test.end_of_test_evt.triggered);
    end

    if ($test$plusargs("DATA_REG_TEST")) begin
      env = new(env_if);
      data_reg_test = new(env);
      data_reg_test.test_name = "DATA_REG_TEST";
      data_reg_test.run();
      wait(data_reg_test.end_of_test_evt.triggered);
    end

    if ($test$plusargs("FIFO_TEST")) begin
      env = new(env_if);
      fifo_test = new(env);
      fifo_test.test_name = "FIFO_TEST";
      fifo_test.run();
      wait(fifo_test.end_of_test_evt.triggered);
    end

    if ($test$plusargs("CORE_INTERRUPT_TEST")) begin
      env = new(env_if);
      core_interrupt_test = new(env);
      core_interrupt_test.test_name = "CORE_INTERRUPT_TEST";
      core_interrupt_test.run();
      wait(core_interrupt_test.end_of_test_evt.triggered);
    end

    if ($test$plusargs("ARBITER_INTR_TEST")) begin
      env = new(env_if);
      arbiter_intr_test = new(env);
      arbiter_intr_test.test_name = "ARBITER_INTR_TEST";
      arbiter_intr_test.run();
      wait(arbiter_intr_test.end_of_test_evt.triggered);
    end

    if ($test$plusargs("FIFO_INTERRUPT_TEST")) begin
      env = new(env_if);
      fifo_interrupt_test = new(env);
      fifo_interrupt_test.test_name = "FIFO_INTERRUPT_TEST";
      fifo_interrupt_test.run();
      wait(fifo_interrupt_test.end_of_test_evt.triggered);
    end

    if ($test$plusargs("RESET_ON_THE_FLY_TEST")) begin
      env = new(env_if);
      reset_on_the_fly_test = new(env);
      reset_on_the_fly_test.test_name = "RESET_ON_THE_FLY_TEST";
      reset_on_the_fly_test.run();
      wait(reset_on_the_fly_test.end_of_test_evt.triggered);
    end

    #(10 * `CLOCK_PERIOD);
    if (env == null) begin
      $warning("--- NO TEST WAS RUN! ---");
    end
    $finish();
  end
  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE ABOVE OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */

endmodule : axis_decoder_tb_top

`endif // !AXIS_DECODER_TB_TOP

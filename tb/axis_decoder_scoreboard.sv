`ifndef AXIS_DECODER_SCOREBOARD
`define AXIS_DECODER_SCOREBOARD

import axis_decoder_pkg::*;

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

  // Your variables here...

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

  // You can write your code here...

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
    rst_transaction        coll_rst_transaction;
    irq_transaction        coll_irq_transaction;
    apb_master_transaction coll_apb_transaction;
    axi_stream_transaction coll_axi_in_transaction;

    fork

      forever begin
        rst2scrb.get(coll_rst_transaction);
        // You can write your code here...
      end

      forever begin
        irq2scrb.get(coll_irq_transaction);
        // You can write your code here...
      end

      forever begin
        apb2scrb.get(coll_apb_transaction);
        process_apb_transaction(coll_apb_transaction);
      end

      forever begin : write_axi_in_to_queue
        in2scrb[0].get(coll_axi_in_transaction);
        // You can write your code here...
      end

      begin : write_axi_out_to_queue
        foreach (out2scrb[i]) begin
          automatic axi_stream_transaction coll_axi_out_transaction;
          automatic int k = i;
          fork
            forever begin
              out2scrb[k].get(coll_axi_out_transaction);
              // You can write your code here...
            end
          join_none
        end
      end

      // You can write your code here...

    join
  endtask : main

  /* !!!-----------------------------------------------------!!! */
  /* !!! DO NOT DELETE TASK BELOW OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!-----------------------------------------------------!!! */
  task shutdown();
    // You can write your code here...
  endtask
  /* !!!-----------------------------------------------------!!! */
  /* !!! DO NOT DELETE TASK ABOVE OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!-----------------------------------------------------!!! */

  task automatic process_apb_transaction(apb_master_transaction coll_apb_transaction);
    // You can write your code here...
  endtask

  // You can write your code here...

endclass

`endif // !AXIS_DECODER_SCOREBOARD

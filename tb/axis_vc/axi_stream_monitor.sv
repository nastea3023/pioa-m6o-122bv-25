`ifndef AXI_STREAM_MONITOR
`define AXI_STREAM_MONITOR

class axi_stream_monitor;

  mailbox mon_outside;

  axi_stream_agent_cfg     cfg;

  axi_stream_transaction transaction;

  event first_hs;
  event tlast;

  function new(axi_stream_agent_cfg  cfg, mailbox mon_outside, event first_hs);
    this.cfg             = cfg;
    this.mon_outside     = mon_outside;
    this.first_hs        = first_hs;
  endfunction

  task monitor_transaction();
    // Interface listening
    forever begin
      @(posedge cfg.vif.clk)
      if (cfg.vif.axis_valid && cfg.vif.axis_ready) begin
        transaction.data.push_back(cfg.vif.axis_data);
        transaction.id = cfg.vif.axis_id;
        if (transaction.data.size() == 1) begin
          ->first_hs;
        end
        if (!cfg.master_has_tlast_f) begin
          break;
        end else if (cfg.vif.axis_last) begin
          ->tlast;
          break;
        end
      end
    end
  endtask

  function void pre_main();
    // You can write your code here...
  endfunction

  task main();
    forever begin
      wait(!$isunknown(cfg.vif.rst_n));
      @(posedge cfg.vif.rst_n);
      fork
        begin
          forever begin
            transaction = new();
            monitor_transaction();
            if ($test$plusargs("TRAN_INFO")) begin
              transaction.display("[axi_stream_monitor]");
            end
            mon_outside.put(transaction);
          end
        end
        begin
          @(negedge cfg.vif.rst_n);
          transaction = null;
        end
      join_any
      disable fork;
    end  
  endtask

  // Run task
  task run;
    pre_main();
    main();
  endtask

endclass : axi_stream_monitor

`endif //!AXI_STREAM_MONITOR
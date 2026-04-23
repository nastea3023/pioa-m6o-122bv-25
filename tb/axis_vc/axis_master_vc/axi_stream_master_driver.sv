`ifndef AXI_STREAM_MASTER_DRIVER
`define AXI_STREAM_MASTER_DRIVER

import axi_stream_pkg::*;

class axi_stream_master_driver;

  axi_stream_agent_cfg        cfg;
  mailbox                     to_driver;

  axi_stream_transaction transaction;

  function new(axi_stream_agent_cfg cfg, mailbox to_driver);
    this.to_driver = to_driver;
    this.cfg       = cfg;
  endfunction

  task drive_transaction();
    e_axis_driver_state state = DRIVE_INITIAL;
    int i = 0;
    forever begin
      @(posedge cfg.vif.clk)
      case (state)
        DRIVE_INITIAL:
          begin
            cfg.vif.axis_valid <= 1;
            cfg.vif.axis_data  <= transaction.data[i];
            if (cfg.master_has_tid_f) 
              cfg.vif.axis_id    <= transaction.id;
            if (cfg.master_has_tlast_f && i == transaction.data.size()-1) begin
              cfg.vif.axis_last <= 1;
            end
            state = DRIVE;
          end
        DRIVE:
          begin
            if (cfg.vif.axis_ready) begin
              if (i < transaction.data.size()-1) begin
                i++;
                cfg.vif.axis_data  <= transaction.data[i];
                if (cfg.master_has_tid_f) 
                  cfg.vif.axis_id    <= transaction.id;
                if (cfg.master_has_tlast_f && i == transaction.data.size()-1) begin
                  cfg.vif.axis_last <= 1;
                end
              end else begin
                cfg.vif.axis_data  <= 0;
                cfg.vif.axis_id    <= 0;
                cfg.vif.axis_valid <= 0;
                cfg.vif.axis_last  <= 0;
                break;
              end
            end
          end
      endcase
    end
  endtask

  function void pre_main();
    // You can write your code here...
  endfunction

  task main();
    forever begin
      wait(!$isunknown(cfg.vif.rst_n));
      fork
        begin
          @(posedge cfg.vif.rst_n);
          forever begin
          to_driver.get(transaction);
          if ($test$plusargs("TRAN_INFO")) begin
            transaction.display("[axi_stream_master_driver]");
          end
          drive_transaction();
        end
        end
        begin
          @(negedge cfg.vif.rst_n);
          cfg.vif.axis_data  <= 0;
          cfg.vif.axis_id    <= 0;
          cfg.vif.axis_valid <= 0;
          cfg.vif.axis_last  <= 0;
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

endclass : axi_stream_master_driver

`endif //!AXI_STREAM_MASTER_DRIVER

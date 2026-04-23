`ifndef AXI_STREAM_SLAVE_DRIVER
`define AXI_STREAM_SLAVE_DRIVER

import axi_stream_pkg::*;

class axi_stream_slave_driver;

  axi_stream_agent_cfg        cfg;

  function new(axi_stream_agent_cfg cfg);
    this.cfg = cfg;
  endfunction

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
            randomize_tready();
          end
        end
        begin
          @(negedge cfg.vif.rst_n);
          cfg.vif.axis_ready <= 0;
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


  task randomize_tready();
    int active_duration;
    int inactive_duration;

    active_duration   = $urandom_range( cfg.slave_tready_active_dur_min  , cfg.slave_tready_active_dur_max   );
    inactive_duration = $urandom_range( cfg.slave_tready_inactive_dur_min, cfg.slave_tready_inactive_dur_max );

    repeat(active_duration) begin
      cfg.vif.axis_ready <= '1;
      @(posedge cfg.vif.clk);
    end

    repeat(inactive_duration) begin
      cfg.vif.axis_ready <= '0;
      @(posedge cfg.vif.clk);
    end
  endtask

endclass : axi_stream_slave_driver

`endif //!AXI_STREAM_SLAVE_DRIVER
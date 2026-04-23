`ifndef AXI_STREAM_TRANSACTION
`define AXI_STREAM_TRANSACTION

class axi_stream_transaction;

  // Declaring the transaction fields
  rand logic        [`AXI_MAX_DATA_W-1:0] data [$];
  rand logic        [`AXI_ID_W      -1:0] id      ;


  function void display(string name);
    $display("-------------------------");
    $display("TIME: %0t", $realtime);
    $display("-------------------------");
    $display("- %s ", name);
    $display("-------------------------");
    $display("- Data: ");
    $display("%p", data);
    $display("- Data Size: ");
    $display("%d", data.size());
    $display("-------------------------");
    $display("- Id: ");
    $display("%d", id);
    $display("-------------------------");
  endfunction
  
  function void copy(axi_stream_transaction src);
      this.data = src.data;
      this.id = src.id;
  endfunction
endclass : axi_stream_transaction

`endif //!AXI_STREAM_TRANSACTION

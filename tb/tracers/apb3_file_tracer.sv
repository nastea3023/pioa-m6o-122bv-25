module apb3_file_tracer #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LOG_FILE   = "apb_trace.log"
)(
    input logic                  pclk,
    input logic                  presetn,
    input logic [ADDR_WIDTH-1:0] paddr,
    input logic                  psel,
    input logic                  penable,
    input logic                  pwrite,
    input logic [DATA_WIDTH-1:0] pwdata,
    input logic [DATA_WIDTH-1:0] prdata,
    input logic                  pready,
    input logic                  pslverr
);

    int fd;

    initial begin
        fd = $fopen(LOG_FILE, "w");
        if (!fd) $fatal(2, "Failed to create log file %s", LOG_FILE);
        $fdisplay(fd, "Time | Type  | Address | Data | Status");
        $fdisplay(fd, "--------------------------------------------------");
    end

    final begin
        $fclose(fd);
    end

    always @(posedge pclk) begin
        if (presetn)
            if(psel && penable && pready) begin
            if (pwrite) begin
                $fdisplay(fd, "%0t | WRITE | 0x%h | 0x%h | %s",
                        $time, paddr, pwdata, pslverr ? "ERROR" : "OK");
            end else begin
                $fdisplay(fd, "%0t | READ  | 0x%h | 0x%h | %s",
                        $time, paddr, prdata, pslverr ? "ERROR" : "OK");
            end
            // $display("[APB] Addr: %h Data: %h", paddr, pwrite ? pwdata : prdata);
        end
    end

endmodule : apb3_file_tracer

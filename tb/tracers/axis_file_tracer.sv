module axis_file_tracer #(
    parameter DATA_WIDTH = 32,
    parameter LOG_FILE   = "axis_trace.log"
)(
    input logic                   clk,
    input logic                   aresetn,
    input logic [DATA_WIDTH-1:0]  tdata,
    input logic                   tvalid,
    input logic                   tready
);

    int fd;

    initial begin
        fd = $fopen(LOG_FILE, "w");
        if (!fd) $fatal(2, "Failed to create log file %s", LOG_FILE);
        $fdisplay(fd, "Time         | Data ");
        $fdisplay(fd, "--------------------------");
    end

    always @(posedge clk) begin
        if (aresetn) begin
            if (tvalid && tready) begin
                $fdisplay(fd, "%t | 0x%h", $time, tdata);
            end
        end
    end

    final begin
        if (fd) $fclose(fd);
    end

endmodule : axis_file_tracer

module mux_cdc #(
    parameter DATA_W = 8)(
    input  wire              clk_a,
    input  wire              clk_b,
    input  wire              rst_n,
    // Source domain (clk_a)
    input  wire [DATA_W-1:0] data_a,
    input  wire              sel_a,   // toggle signal
    // Destination domain (clk_b)
    output reg  [DATA_W-1:0] data_b
);

// ───────── Domain A (Source) ─────────
reg [DATA_W-1:0] data_new;
reg [DATA_W-1:0] data_old;
reg              sel_reg;

always @(posedge clk_a or negedge rst_n) begin
    if (!rst_n) begin
        data_new <= 0;
        data_old <= 0;
        sel_reg  <= 0;
    end else begin
        sel_reg  <= sel_a;
        data_old <= data_new;   // previous stable value
        data_new <= data_a;     // capture new data
    end
end

// ───────── Synchronizer (clk_b) ─────────
reg sel_ff1, sel_ff2;

always @(posedge clk_b or negedge rst_n) begin
    if (!rst_n) begin
        sel_ff1 <= 0;
        sel_ff2 <= 0;
    end else begin
        sel_ff1 <= sel_reg;
        sel_ff2 <= sel_ff1;
    end
end

// ───────── MUX + Capture (clk_b) ─────────
wire [DATA_W-1:0] mux_out;

assign mux_out = (sel_ff2) ? data_new : data_old;

always @(posedge clk_b or negedge rst_n) begin
    if (!rst_n)
        data_b <= 0;
    else
        data_b <= mux_out;
end
endmodule

//testbench
`timescale 1ns/1ps
module tb_mux_cdc();
parameter DATA_W = 8;
reg clk_a;
reg clk_b;
reg rst_n;

reg [DATA_W-1:0] data_a;
reg sel_a;
wire [DATA_W-1:0] data_b;

// DUT
mux_cdc #(DATA_W) dut (
    .clk_a(clk_a),
    .clk_b(clk_b),
    .rst_n(rst_n),
    .data_a(data_a),
    .sel_a(sel_a),
    .data_b(data_b)
);

// 🔷 Clock Generation (different frequencies)
initial begin
    clk_a = 0;
    forever #5 clk_a = ~clk_a;   // 100 MHz
end
initial begin
    clk_b = 0;
    forever #7 clk_b = ~clk_b;   // ~71 MHz (async)
end


// 🔷 Stimulus
initial begin
 $display("Time\tclk_a\tclk_b\tsel_a\tdata_a\tdata_b");
    $monitor("%0t\t%b\t%b\t%b\t%h\t%h",
              $time, clk_a, clk_b, sel_a, data_a, data_b);
    rst_n = 0;
    data_a = 0;
    sel_a  = 0;

    #20;
    rst_n = 1;

    // Apply multiple transfers
    repeat (10) begin
        @(posedge clk_a);

        // Change data
        data_a = $random;

        // Toggle select (IMPORTANT for mux CDC)
        sel_a = ~sel_a;

        // Wait some cycles before next transfer
        repeat (3) @(posedge clk_a);
    end

    #100;
    $finish;
end
endmodule

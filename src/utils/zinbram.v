module zmem #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 10,
    parameter LATENCY = 1,
    parameter M = 1024,
    parameter N = 7
)(
    input                          clk,
    input                          rst_n,
    input                          readEn,
    input                          writeEn,
    input  [ADDR_WIDTH-1:0]        addr1,
    input  [ADDR_WIDTH-1:0]        addr2,   
    input  [DATA_WIDTH-1:0]        din1,    

    output reg [DATA_WIDTH-1:0]    dout1,
    output reg [DATA_WIDTH-1:0]    dout2,
    output reg                     dout_valid
);

reg [M*N*DATA_WIDTH-1:0] Zmem;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Zmem <= 0;
        dout1 <= 0;
        dout2 <= 0;
        dout_valid <= 0;
    end else if (readEn) begin
        dout1 <= Zmem[addr1*DATA_WIDTH +: DATA_WIDTH];
        dout2 <= Zmem[addr2*DATA_WIDTH +: DATA_WIDTH];
        dout_valid <= 1'b1; 
    end else if (writeEn) begin
        Zmem[addr1*DATA_WIDTH +: DATA_WIDTH] <= din1;
        dout_valid <= 1'b0;  
    end
    else begin
        dout_valid <= 1'b0;
    end
end

endmodule
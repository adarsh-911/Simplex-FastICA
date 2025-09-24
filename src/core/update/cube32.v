module sequential_cuber #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_WIDTH = 10
) (
    input                           clk,
    input                           rst_n,
    input                           start,
    input  signed [DATA_WIDTH-1:0]  data_in,
    
    output reg signed [DATA_WIDTH-1:0] cube_out,
    output reg                      valid_out
);

    // Pipeline registers for 3-stage cubing
    reg signed [DATA_WIDTH-1:0]     data_reg_stage1;
    reg signed [DATA_WIDTH-1:0]     data_reg_stage2;
    reg signed [2*DATA_WIDTH-1:0]   square_reg;
    reg                             valid_stage1;
    reg                             valid_stage2;
    
    // Intermediate cube result (3*DATA_WIDTH bits)
    wire signed [3*DATA_WIDTH-1:0]  cube_full;
    assign cube_full = square_reg * data_reg_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg_stage1 <= {DATA_WIDTH{1'b0}};
            data_reg_stage2 <= {DATA_WIDTH{1'b0}};
            square_reg      <= {(2*DATA_WIDTH){1'b0}};
            cube_out        <= {DATA_WIDTH{1'b0}};
            valid_stage1    <= 1'b0;
            valid_stage2    <= 1'b0;
            valid_out       <= 1'b0;
        end else begin
            // Stage 1: Register input
            if (start) begin
                data_reg_stage1 <= data_in;
                valid_stage1    <= 1'b1;
            end else begin
                valid_stage1    <= 1'b0;
            end
            
            // Stage 2: Calculate square and pass data forward
            if (valid_stage1) begin
                square_reg      <= data_reg_stage1 * data_reg_stage1;
                data_reg_stage2 <= data_reg_stage1;
                valid_stage2    <= 1'b1;
            end else begin
                valid_stage2    <= 1'b0;
            end
            
            // Stage 3: Calculate cube and normalize
            if (valid_stage2) begin
                // Proper normalization: cube (3*DATA_WIDTH) shifted by 2*FRAC_WIDTH
                // Extract the properly scaled result
                cube_out  <= cube_full[2*FRAC_WIDTH +: DATA_WIDTH];
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule
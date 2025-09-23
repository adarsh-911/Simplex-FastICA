module w_diff_norm #(
    // call this after norm_5d block. Output is || w_in - w_prev ||
    parameter N = 7,
    parameter DATA_WIDTH = 32,
    parameter ANGLE_WIDTH = 16,
    parameter CORDIC_STAGES = 16
) (
    input                          clk,
    input                          rst_n,
    input                          en,
    input  [N*DATA_WIDTH-1:0]      w_in,

    input                          cordic_vec_opvld,
    input  signed [DATA_WIDTH-1:0] cordic_vec_xout,

    output reg                     ica_cordic_vec_en,
    output reg signed [DATA_WIDTH-1:0] ica_cordic_vec_xin,
    output reg signed [DATA_WIDTH-1:0] ica_cordic_vec_yin,
    output reg                     ica_cordic_vec_angle_calc_en,

    output reg signed [DATA_WIDTH-1:0] norm_out,
    output reg                     output_valid
);

    reg [N*DATA_WIDTH-1:0] w_prev;
    reg [2:0] counter;
    reg active;

    wire signed [DATA_WIDTH-1:0] w_in_wire [0:N-1];
    wire signed [DATA_WIDTH-1:0] w_prev_wire [0:N-1];
    wire signed [DATA_WIDTH-1:0] diff_wire [0:N-1];

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_wires
            assign w_in_wire[i] = w_in[i*DATA_WIDTH +: DATA_WIDTH];
            assign w_prev_wire[i] = w_prev[i*DATA_WIDTH +: DATA_WIDTH];
            assign diff_wire[i] = w_in_wire[i] - w_prev_wire[i];
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_prev <= {N*DATA_WIDTH{1'b0}};
            counter <= 3'b0;
            active <= 1'b0;
            ica_cordic_vec_en <= 1'b0;
            ica_cordic_vec_xin <= {DATA_WIDTH{1'b0}};
            ica_cordic_vec_yin <= {DATA_WIDTH{1'b0}};
            ica_cordic_vec_angle_calc_en <= 1'b0;
            norm_out <= {DATA_WIDTH{1'b0}};
            output_valid <= 1'b0;
        end else begin
            ica_cordic_vec_en <= 1'b0;
            output_valid <= 1'b0;
            
            if (en && !active) begin
                active <= 1'b1;
                counter <= 3'b0;
                ica_cordic_vec_en <= 1'b1;
                ica_cordic_vec_xin <= diff_wire[0];
                ica_cordic_vec_yin <= diff_wire[1];
                ica_cordic_vec_angle_calc_en <= 1'b0;
                counter <= counter + 1;
            end else if (active) begin
                if (counter <= N-2) begin
                    if (cordic_vec_opvld == 1) begin
                        ica_cordic_vec_en <= 1'b1;
                        ica_cordic_vec_xin <= diff_wire[counter+1];
                        ica_cordic_vec_yin <= cordic_vec_xout;
                        ica_cordic_vec_angle_calc_en <= 1'b0;
                        counter <= counter + 1;
                    end
                end else if (counter == N-1 && cordic_vec_opvld == 1) begin
                    norm_out <= cordic_vec_xout;
                    output_valid <= 1'b1;
                    active <= 1'b0;
                    w_prev <= w_in;
                    counter <= 3'b0;
                end
            end
        end
    end

endmodule
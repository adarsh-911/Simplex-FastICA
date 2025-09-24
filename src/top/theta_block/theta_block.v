`timescale 1ns / 1ps
module sequential_cordic_processor #(
    parameter DATA_WIDTH    = 16,
    parameter ANGLE_WIDTH   = 16,
    parameter N_DIM         = 7,
    parameter CORDIC_WIDTH  = 22,
    parameter CORDIC_STAGES = 16
) (

    input clk,
    input nreset,
    input start,
    input signed [DATA_WIDTH*N_DIM-1:0]  w_in_flat,
    input signed [DATA_WIDTH-1:0]  cordic_xout,
    input signed [ANGLE_WIDTH-1:0] cordic_angle_out,
    input  cordic_op_vld,
    output reg cordic_nrst,
    output reg  cordic_en,
    output reg  signed [DATA_WIDTH-1:0]  cordic_xin,
    output reg  signed [DATA_WIDTH-1:0]  cordic_yin,
    output reg  signed [(N_DIM-1)*ANGLE_WIDTH-1:0] theta_out,
    output reg  done
);

    // FSM State Definition
    localparam S_IDLE      = 2'b00;
    localparam S_CALCULATE = 2'b01;
    localparam S_WAIT      = 2'b10;
    localparam S_DONE      = 2'b11;

    reg [1:0] state;

    // Internal Signals
    integer i;

    reg [$clog2(N_DIM-1)-1:0] calc_count;
    reg signed [DATA_WIDTH-1:0] w_current [0:N_DIM-1];
    reg signed [DATA_WIDTH-1:0] xf_reg;
    //reg  cordic_en;
   // reg  signed [DATA_WIDTH-1:0]  cordic_xin;
   // reg  signed [DATA_WIDTH-1:0]  cordic_yin;
   // wire signed [DATA_WIDTH-1:0]  cordic_xout;
   // wire signed [ANGLE_WIDTH-1:0] cordic_angle_out;
   // wire cordic_op_vld;

    // Single CORDIC Vectoring Core Instantiation
   /* reg cordic_nrst;
    CORDIC_Vectoring_top1 #(
        .DATA_WIDTH(DATA_WIDTH),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES),
        .ANGLE_WIDTH(ANGLE_WIDTH)
    ) single_cordic_core (
        .clk(clk),
        .nreset(cordic_nrst),
        .vec_en(cordic_en),
        .x_vec_in(cordic_xin),
        .y_vec_in(cordic_yin),
        .angle_calc_enable_in(cordic_en),
        .x_vec_out(cordic_xout),
        .angle_out(cordic_angle_out),
        .output_valid_o(cordic_op_vld)
    );*/

    // Main Control and Datapath FSM
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            // Reset all internal state and outputs
            state       <= S_IDLE;
            calc_count  <= 0;
            cordic_en   <= 1'b0;
            done        <= 1'b0;
            theta_out   <= 0;
            xf_reg      <= 0;
            cordic_xin  <= 0;
            cordic_yin  <= 0;
            cordic_nrst <= 0;
            done <= 0;
        end else begin
            //cordic_en <= 1'b0;
            //done      <= 1'b0;

            // FSM state transitions and logic
            case (state)
                S_IDLE: begin
                    if (start) begin
                        for (i = 0; i < N_DIM; i = i + 1) begin
                            w_current[i] <= w_in_flat[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
                        end
                        calc_count <= 0;
                        state      <= S_CALCULATE;
                    end
                end

                S_CALCULATE: begin
                    
                    cordic_nrst <= 1;
                    cordic_en <= 1'b1;
                    if (calc_count == 0) begin
                        cordic_xin <= w_current[0];
                        cordic_yin <= w_current[1];
                    end else begin
                        cordic_xin <= w_current[calc_count + 1];
                        cordic_yin <= xf_reg;
                    end
                  
                    state <= S_WAIT;
                end

                S_WAIT: begin
                    if (cordic_op_vld) begin
                        // Latch the results
                        xf_reg <= cordic_xout;
                        theta_out[(calc_count+1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] <= cordic_angle_out;

                        if (calc_count == N_DIM - 2) begin
                            state <= S_DONE;
                        end else begin
                            calc_count <= calc_count + 1;
                            state      <= S_CALCULATE;
                        end
                        cordic_nrst <= 0;
                    end
                    
                end

                S_DONE: begin
                    done  <= 1'b1;
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule


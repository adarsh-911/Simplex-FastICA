`timescale 1ns / 1ps
module tb_process_vector;

    localparam DATA_WIDTH    = 16;
    localparam ANGLE_WIDTH   = 16;
    localparam N_DIM         = 7;
    localparam CORDIC_WIDTH  = 22;
    localparam CORDIC_STAGES = 16;
    localparam CLK_PERIOD    = 10; // ns

   
    reg clk;
    reg nreset;
    reg start;
    reg signed [DATA_WIDTH*N_DIM-1:0] W_tb;

  
    wire signed [DATA_WIDTH-1:0]  cordic_xout;
    wire signed [ANGLE_WIDTH-1:0] cordic_angle_out;
    wire cordic_op_vld;
    wire cordic_en; 
    wire signed [DATA_WIDTH-1:0]  cordic_xin;
    wire signed [DATA_WIDTH-1:0]  cordic_yin;
    wire cordic_nrst;

 
    wire signed [(N_DIM-1)*ANGLE_WIDTH-1:0] theta_out;
    wire done_out;

  
    integer i;
    reg signed [ANGLE_WIDTH-1:0] temp_theta;


    sequential_cordic_processor #(
        .DATA_WIDTH(DATA_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .N_DIM(N_DIM)
    ) dut (
        .clk(clk),
        .nreset(nreset),
        .start(start),
        .w_in_flat(W_tb),
        .theta_out(theta_out),
        .done(done_out),
        // Connections to the CORDIC core
        .cordic_xout(cordic_xout),
        .cordic_angle_out(cordic_angle_out),
        .cordic_op_vld(cordic_op_vld),
        .cordic_xin(cordic_xin),
        .cordic_yin(cordic_yin),
        .cordic_nrst(cordic_nrst),
        .cordic_en(cordic_en)
    );

    
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
        // Outputs back to the controller
        .x_vec_out(cordic_xout),
        .angle_out(cordic_angle_out),
        .output_valid_o(cordic_op_vld),
        // Unused outputs of the CORDIC core
        .micro_angle_o(),
        .quad_out(),
        .vec_microRot_out_start()
    );


    always # (CLK_PERIOD / 2) clk = ~clk;

 
    initial begin
        $display("==========================================================");
        $display("Testbench for Controller/Datapath Started at %0t", $time);
        clk    = 0;
        nreset = 1'b0; // Assert system reset
        start  = 1'b0;
        W_tb   = 0;

        # (CLK_PERIOD * 2);
        nreset = 1'b1; // De-assert system reset
        $display("Reset de-asserted at %0t", $time);

        # (CLK_PERIOD);

        // Define the 7D test vector W = [w7, w6, w5, w4, w3, w2, w1]
        W_tb = {16'sd1000, 16'sd500, 16'sd500, 16'sd0, 16'sd2000, 16'sd1000, 16'sd1000};
        $display("Applying test vector and pulsing start...");

        start = 1'b1;
        # (CLK_PERIOD);
        start = 1'b0;

        wait (done_out);

        # (CLK_PERIOD);
        $display("----------------------------------------------------------");
        $display("Calculation complete at time %0t", $time);
        $display("Final Outputs (fixed-point integer representation):");

        // Display the results using a loop
        for (i=0; i < N_DIM-1; i=i+1) begin
            temp_theta = theta_out[(i+1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH];
            $display("  theta[%0d] = %d (0x%h)", i+1, $signed(temp_theta), temp_theta);
        end

        $display("----------------------------------------------------------");

        # (CLK_PERIOD * 5);
        $display("Testbench Finished at %0t", $time);
        $display("==========================================================");
        $finish;
    end

endmodule


`timescale 1ns / 1ps
module gso_top_tb;

    // Parameters for the test
    localparam DATA_WIDTH    = 16;
    localparam ANGLE_WIDTH   = 16;
    localparam N_DIM         = 7;
    localparam K_VECTORS     = N_DIM - 1;
    localparam CORDIC_WIDTH  = 22;
    localparam CORDIC_STAGES = 16;

    // Testbench Control Signals
    reg clk;
    reg rst_n;
    reg en; 
    reg [2:0] k_in;
    reg signed [DATA_WIDTH*N_DIM-1:0] w_in_flat;
    reg signed [ANGLE_WIDTH*K_VECTORS*K_VECTORS-1:0] thetas_in_flat;


    wire signed [DATA_WIDTH*N_DIM-1:0] w_out_flat;
    wire done;
    wire cordic_rot_en;
    wire signed [DATA_WIDTH-1:0]  cordic_rot_xin_reg;
    wire signed [DATA_WIDTH-1:0]  cordic_rot_yin_reg;
    wire signed [ANGLE_WIDTH-1:0] cordic_rot_angle_in_reg;
    wire signed [DATA_WIDTH-1:0]  cordic_rot_xout;
    wire signed [DATA_WIDTH-1:0]  cordic_rot_yout;
    wire cordic_rot_opvld;
    wire cordic_rot_angle_microRot_n;
    wire cordic_rot_microRot_ext_vld;
    wire [1:0] cordic_rot_quad_in;

    // 1. Instantiate the GSO Controller (your modified design)
    gso_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .N_DIM(N_DIM),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES)
    ) gso_controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .k_in(k_in),
        .w_in_flat(w_in_flat),
        .thetas_in_flat(thetas_in_flat),
        .cordic_rot_xout(cordic_rot_xout),
        .cordic_rot_yout(cordic_rot_yout),
        .cordic_rot_opvld(cordic_rot_opvld),
        .w_out_flat(w_out_flat),
        .done(done),
        .cordic_rot_en(cordic_rot_en),
        .cordic_rot_xin_reg(cordic_rot_xin_reg),
        .cordic_rot_yin_reg(cordic_rot_yin_reg),
        .cordic_rot_angle_in_reg(cordic_rot_angle_in_reg),
        .cordic_rot_angle_microRot_n(cordic_rot_angle_microRot_n),
        .cordic_rot_microRot_ext_vld(cordic_rot_microRot_ext_vld),
        .cordic_rot_quad_in(cordic_rot_quad_in)
    );

    // 2. Instantiate the CORDIC block
    CORDIC_doubly_pipe_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES)
    ) cordic_inst (
        .clk(clk),
        .nreset(rst_n),
        .cordic_vec_en(1'b0),
        .cordic_vec_xin(0), 
        .cordic_vec_yin(0), 
        .cordic_vec_angle_calc_en(1'b0),
        .cordic_rot_en(cordic_rot_en),
        .cordic_rot_xin(cordic_rot_xin_reg),
        .cordic_rot_yin(cordic_rot_yin_reg),
        .cordic_rot_angle_microRot_n(cordic_rot_angle_microRot_n),
        .cordic_rot_angle_in(cordic_rot_angle_in_reg),
        .cordic_rot_microRot_ext_in(0),
        .cordic_rot_microRot_ext_vld(cordic_rot_microRot_ext_vld),
        .cordic_rot_quad_in(cordic_rot_quad_in),
        .cordic_vec_opvld(), .cordic_vec_xout(), .vec_quad(), .vec_angle_out(), .vec_microRot_dir(), .vec_microRot_out_start(),
        .cordic_rot_opvld(cordic_rot_opvld),
        .cordic_rot_xout(cordic_rot_xout),
        .cordic_rot_yout(cordic_rot_yout)
    );


    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Sequence
    integer i, j;
    initial begin
        $display("SIM_INFO: Initializing hierarchical testbench...");
        en = 1'b0;
        k_in = 0;
        w_in_flat = 0;
        thetas_in_flat = 0;
        rst_n = 1'b0; // Use rst_n
        #20;
        rst_n = 1'b1;
        #10;

        $display("SIM_INFO: Setting up test case for W3 (k=3)");
        k_in = 3;
        for (i = 0; i < N_DIM; i = i + 1) begin
            w_in_flat[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH] = $signed(100 + i*10);
        end
        for (j = 0; j < k_in - 1; j = j + 1) begin
            for (i = 0; i < K_VECTORS; i = i + 1) begin
                thetas_in_flat[(j*K_VECTORS + i + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed( (16'h0200 * (j+1)) + i );
            end
        end
        #10;

        $display("SIM_INFO: Asserting ENABLE signal...");
        en = 1'b1; // Use en
        #10;
        en = 1'b0;

        $display("SIM_INFO: Waiting for DONE signal...");
        wait(done);
        $display("SIM_INFO: DONE signal received at time %t", $time);
        $display("Final Q3[0] = %d", w_out_flat[DATA_WIDTH-1:0]);
        #100;
        $finish;
    end

endmodule

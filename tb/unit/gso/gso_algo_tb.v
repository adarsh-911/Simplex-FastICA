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

    // Wires to connect the GSO controller and the CORDIC block
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

    // 1. Instantiate the GSO Controller
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
        .cordic_vec_en(1'b0), .cordic_vec_xin(16'b0), .cordic_vec_yin(16'b0), .cordic_vec_angle_calc_en(1'b0),
        .cordic_rot_en(cordic_rot_en),
        .cordic_rot_xin(cordic_rot_xin_reg),
        .cordic_rot_yin(cordic_rot_yin_reg),
        .cordic_rot_angle_microRot_n(cordic_rot_angle_microRot_n),
        .cordic_rot_angle_in(cordic_rot_angle_in_reg),
        .cordic_rot_microRot_ext_in(16'b0),
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
    integer i;
    initial begin
        $display("SIM_INFO: Initializing custom testbench...");
        en = 1'b0;
        k_in = 0;
        w_in_flat = 0;
        thetas_in_flat = 0;
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
        #10;

        // --- STEP 1: Set k_in ---
        $display("SIM_INFO: Setting up test case for W3 (k=3)");
        k_in = 3;

        // --- STEP 2: Provide custom W_in vector ---
        $display("SIM_INFO: Loading custom W_in vector.");
        w_in_flat[(0+1)*DATA_WIDTH-1 -: DATA_WIDTH] = $signed(100);
        w_in_flat[(1+1)*DATA_WIDTH-1 -: DATA_WIDTH] = $signed(110);
        w_in_flat[(2+1)*DATA_WIDTH-1 -: DATA_WIDTH] = $signed(120);
        w_in_flat[(3+1)*DATA_WIDTH-1 -: DATA_WIDTH] = $signed(130);
        w_in_flat[(4+1)*DATA_WIDTH-1 -: DATA_WIDTH] = $signed(140);
        w_in_flat[(5+1)*DATA_WIDTH-1 -: DATA_WIDTH] = $signed(150);
        w_in_flat[(6+1)*DATA_WIDTH-1 -: DATA_WIDTH] = $signed(160);

        // --- STEP 3: Provide custom theta_in values ---
        $display("SIM_INFO: Loading custom theta values.");
        // Thetas for Q1 (j=0)
        thetas_in_flat[(0*K_VECTORS + 0 + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed(16'hf081);//1a3b
        thetas_in_flat[(0*K_VECTORS + 1 + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed(16'h3869);//4fb1
        thetas_in_flat[(0*K_VECTORS + 2 + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed(16'h17d9);//1fbf
        thetas_in_flat[(0*K_VECTORS + 3 + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed(16'h4c75);//3c61
        thetas_in_flat[(0*K_VECTORS + 4 + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed(16'h2ea1);//4731
        thetas_in_flat[(0*K_VECTORS + 5 + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed(16'h2b57);//2f09

        // Thetas for Q2 (j=1)
        thetas_in_flat[(1*K_VECTORS + 0 + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed(16'h3b81); //c321
        thetas_in_flat[(1*K_VECTORS + 1 + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed(16'h5109); //2363
        thetas_in_flat[(1*K_VECTORS + 2 + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed(16'h35d3); //3457
        thetas_in_flat[(1*K_VECTORS + 3 + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed(16'h2baf); //515f
        thetas_in_flat[(1*K_VECTORS + 4 + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed(16'h551d);//2151
        thetas_in_flat[(1*K_VECTORS + 5 + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH] = $signed(16'h3e73);//3ce9
        #10;

        $display("SIM_INFO: Asserting ENABLE signal...");
        en = 1'b1;
        #10;
        en = 1'b0;

        $display("SIM_INFO: Waiting for DONE signal...");
        wait(done);
        $display("SIM_INFO: DONE signal received at time %t", $time);
        $display("Final Q3[0] = %h", w_out_flat[DATA_WIDTH-1:0]);
        $display("Final Q3[6] = %h", w_out_flat[7*DATA_WIDTH-1 -: DATA_WIDTH]);
        #1000;
        $finish;
    end

  initial begin
    $dumpfile("build/sim/icarus/dump.vcd");
    $dumpvars(0, gso_top_tb);
  end

endmodule

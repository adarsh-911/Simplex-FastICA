`timescale 1ns / 1ps

module tb_5d_pipe();
    parameter DIMENSIONS = 5;
    parameter DATA_WIDTH = 32;
    parameter CORDIC_WIDTH = 38;      
    parameter CORDIC_STAGES = 16;
    parameter ANGLE_WIDTH = 16;
    parameter CLOCK_PERIOD = 10;

    // Inputs
    reg clk;
    reg nreset;
    reg [DIMENSIONS*DATA_WIDTH-1:0] w_in;
    reg start;
    reg [1:0] scica_stage_in;  

    // Outputs
    wire [DIMENSIONS*DATA_WIDTH-1:0] W_out;
    wire done;

    // CORDIC interface signals
    wire ica_cordic_vec_en;
    wire signed [DATA_WIDTH-1:0] ica_cordic_vec_xin;
    wire signed [DATA_WIDTH-1:0] ica_cordic_vec_yin;
    wire ica_cordic_vec_angle_calc_en;
    wire ica_cordic_rot1_en;
    wire signed [DATA_WIDTH-1:0] ica_cordic_rot1_xin;
    wire signed [DATA_WIDTH-1:0] ica_cordic_rot1_yin;
    wire [CORDIC_STAGES-1:0] ica_cordic_rot1_microRot_in;
    wire [1:0] ica_cordic_rot1_quad_in;
    wire cordic_vec_opvld;
    wire signed [DATA_WIDTH-1:0] cordic_vec_xout;
    wire [CORDIC_STAGES-1:0] cordic_vec_microRot_out;
    wire [1:0] cordic_vec_quad_out;
    wire cordic_vec_microRot_out_start;
    wire signed [ANGLE_WIDTH-1:0] cordic_vec_angle_out;
    wire cordic_rot1_opvld;
    wire signed [DATA_WIDTH-1:0] cordic_rot1_xout;
    wire signed [DATA_WIDTH-1:0] cordic_rot1_yout;
    wire ica_cordic_rot1_angle_microRot_n;
    wire ica_cordic_rot1_microRot_ext_vld;

    wire cordic_nrst;

    integer cycle_count;
    integer start_cycle;
    integer end_cycle;

    always @(posedge clk) begin
        if (!nreset)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end


    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end

        initial begin
        nreset = 0;
        w_in = 0;
        start = 0;
        scica_stage_in = 2'b01;
        #20 nreset = 1;
        

        // Test 1: 
        w_in = {32'h00000000, 32'h00000000, 32'h00000000, 32'h00040000, 32'h00030000}; 
        start = 1;
        start_cycle = cycle_count;   // mark cycle when start is asserted
        #20 start = 0;
        wait(done);
        end_cycle = cycle_count;  
        $display("Test 1 took %0d cycles", end_cycle - start_cycle);
        #20;
        $display("Test 1 Input: %h, Output: %h", w_in, W_out);
        $display("Input Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f",
         $itor($signed(w_in[159:128]))/65536.0,   // w5 (V component)
         $itor($signed(w_in[127:96]))/65536.0,   // w4 (W component)
         $itor($signed(w_in[95:64]))/65536.0,   // w3 (Z component)
         $itor($signed(w_in[63:32]))/65536.0,   // w2 (Y component)  
         $itor($signed(w_in[31:0]))/65536.0);   // w1 (X component)

        $display("Output Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f", 
         $itor($signed(W_out[159:128]))/65536.0,  // w5 (V component)
         $itor($signed(W_out[127:96]))/65536.0,   // w4 (W component)
         $itor($signed(W_out[95:64]))/65536.0,    // w3 (Z component)
         $itor($signed(W_out[63:32]))/65536.0,    // w2 (Y component)
         $itor($signed(W_out[31:0]))/65536.0);   // w1 (X component)
        #50;


        // Test 2: 
        $display("Test 2:(w5,w4,w3,w2,w1) format (15.0, 0.0, 1.0, 0.0, 3.0)");
        w_in = {32'h00030000, 32'h00000000, 32'h00040000, 32'h00000000, 32'h00000000}; 
        start = 1;
        #20 start = 0;
        wait(done);
        #20;
        $display("Test 1 Input: %h, Output: %h", w_in, W_out);
        // Print inputs in decimal Q15.16 format
        $display("Input Decimal: w4=%.0f, w3=%.0f, w2=%.0f, w1=%.0f, w0=%.0f",
         $itor($signed(w_in[159:128]))/65536.0,   // w5 (V component)
         $itor($signed(w_in[127:96]))/65536.0,   // w4 (W component)
         $itor($signed(w_in[95:64]))/65536.0,   // w3 (Z component)
         $itor($signed(w_in[63:32]))/65536.0,   // w2 (Y component)  
         $itor($signed(w_in[31:0]))/65536.0);   // w1 (X component)

        // Print outputs in decimal Q15.16 format
        $display("Output Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f", 
         $itor($signed(W_out[159:128]))/65536.0,  // w5 (V component)
         $itor($signed(W_out[127:96]))/65536.0,   // w4 (W component)
         $itor($signed(W_out[95:64]))/65536.0,    // w3 (Z component)
         $itor($signed(W_out[63:32]))/65536.0,    // w2 (Y component)
         $itor($signed(W_out[31:0]))/65536.0);   // w1 (X component)
        #50;

        // Test 3:  (3, 0, -4, 20, 5)  
        $display("Test 2: Mixed signs (3.0, 0.0, -4.0, 20.0, 5.0)");
        w_in = {32'h00030000, 32'h00000000, 32'hFFFC0000, 32'h00140000, 32'h00050000};
        start = 1;
        #20 start = 0;
        wait(done);
        #20;
        $display("Test 3 Input: %h, Output: %h", w_in, W_out);
        // Print inputs in decimal Q15.16 format
        $display("Input Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f",
         $itor($signed(w_in[159:128]))/65536.0,   // w5 (V component)
         $itor($signed(w_in[127:96]))/65536.0,   // w4 (W component)
         $itor($signed(w_in[95:64]))/65536.0,   // w3 (Z component)
         $itor($signed(w_in[63:32]))/65536.0,   // w2 (Y component)  
         $itor($signed(w_in[31:0]))/65536.0);   // w1 (X component)

        // Print outputs in decimal Q15.16 format
        $display("Output Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f", 
         $itor($signed(W_out[159:128]))/65536.0,  // w5 (V component)
         $itor($signed(W_out[127:96]))/65536.0,   // w4 (W component)
         $itor($signed(W_out[95:64]))/65536.0,    // w3 (Z component)
         $itor($signed(W_out[63:32]))/65536.0,    // w2 (Y component)
         $itor($signed(W_out[31:0]))/65536.0);   // w1 (X component)
        #50;


        // Test 4: Mixed large and small (32767.0, -0.5, 123.25, -45.75, 0.03125)
        $display("Test 4: Mixed large/small (32767.0, -0.5, 123.25, -45.75, 0.03125)");
        w_in = {32'h7FFF0000, 32'hFFFF8000, 32'h007B4000, 32'hFFD3C000, 32'h00000800};
        start = 1;
        #20 start = 0;
        wait(done);
        #20;
        $display("Test 4 Input: %h, Output: %h", w_in, W_out);
        $display("Input Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f",
                $itor($signed(w_in[159:128]))/65536.0,
                $itor($signed(w_in[127:96]))/65536.0,
                $itor($signed(w_in[95:64]))/65536.0,
                $itor($signed(w_in[63:32]))/65536.0,
                $itor($signed(w_in[31:0]))/65536.0);
        $display("Output Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f",
                $itor($signed(W_out[159:128]))/65536.0,
                $itor($signed(W_out[127:96]))/65536.0,
                $itor($signed(W_out[95:64]))/65536.0,
                $itor($signed(W_out[63:32]))/65536.0,
                $itor($signed(W_out[31:0]))/65536.0);
        #50;


        // Test 5: Mixed edge case (-32768.0, 0.000015, 2500.5, -0.25, 16.75)
        $display("Test 5: Mixed edge case (-32768.0, 0.000015, 2500.5, -0.25, 16.75)");
        w_in = {32'h80000000, 32'h00000001, 32'h09C48000, 32'hFFFFC000, 32'h0010C000};
        start = 1;
        #20 start = 0;
        wait(done);
        #20;
        $display("Test 5 Input: %h, Output: %h", w_in, W_out);
        $display("Input Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f",
                $itor($signed(w_in[159:128]))/65536.0,
                $itor($signed(w_in[127:96]))/65536.0,
                $itor($signed(w_in[95:64]))/65536.0,
                $itor($signed(w_in[63:32]))/65536.0,
                $itor($signed(w_in[31:0]))/65536.0);
        $display("Output Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f",
                $itor($signed(W_out[159:128]))/65536.0,
                $itor($signed(W_out[127:96]))/65536.0,
                $itor($signed(W_out[95:64]))/65536.0,
                $itor($signed(W_out[63:32]))/65536.0,
                $itor($signed(W_out[31:0]))/65536.0);
        #50;


        // Test 6: Mixed variety (1024.125, -8192.75, 0.5, -16384.0, 3.1416)
        $display("Test 6: Mixed variety (1024.125, -8192.75, 0.5, -16384.0, 3.1416)");
        w_in = {32'h04002000, 32'hE000C000, 32'h00008000, 32'hC0000000, 32'h0003243F};
        start = 1;
        #20 start = 0;
        wait(done);
        #20;
        $display("Test 6 Input: %h, Output: %h", w_in, W_out);
        $display("Input Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f",
                $itor($signed(w_in[159:128]))/65536.0,
                $itor($signed(w_in[127:96]))/65536.0,
                $itor($signed(w_in[95:64]))/65536.0,
                $itor($signed(w_in[63:32]))/65536.0,
                $itor($signed(w_in[31:0]))/65536.0);
        $display("Output Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f",
                $itor($signed(W_out[159:128]))/65536.0,
                $itor($signed(W_out[127:96]))/65536.0,
                $itor($signed(W_out[95:64]))/65536.0,
                $itor($signed(W_out[63:32]))/65536.0,
                $itor($signed(W_out[31:0]))/65536.0);
        #50;
        #50 $finish;
    end

    // Instantiate norm_5d
    norm_5d #(
        .DIMENSIONS(DIMENSIONS),
        .DATA_WIDTH(DATA_WIDTH),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES),
        .ANGLE_WIDTH(ANGLE_WIDTH)
    ) uut (
        .clk(clk),
        .nreset(nreset),
        .w_in(w_in),
        .start(start),
        .W_out(W_out),
        .done(done),
        .cordic_nrst(cordic_nrst),
        .ica_cordic_vec_en(ica_cordic_vec_en),
        .ica_cordic_vec_xin(ica_cordic_vec_xin),
        .ica_cordic_vec_yin(ica_cordic_vec_yin),
        .ica_cordic_vec_angle_calc_en(ica_cordic_vec_angle_calc_en),
        .ica_cordic_rot1_en(ica_cordic_rot1_en),
        .ica_cordic_rot1_xin(ica_cordic_rot1_xin),
        .ica_cordic_rot1_yin(ica_cordic_rot1_yin),
        .ica_cordic_rot1_microRot_in(ica_cordic_rot1_microRot_in),
        .ica_cordic_rot1_quad_in(ica_cordic_rot1_quad_in),
        .cordic_vec_opvld(cordic_vec_opvld),
        .cordic_vec_xout(cordic_vec_xout),
        .cordic_vec_microRot_out(cordic_vec_microRot_out),
        .cordic_vec_quad_out(cordic_vec_quad_out),
        .cordic_vec_microRot_out_start(cordic_vec_microRot_out_start),
        .cordic_vec_angle_out(cordic_vec_angle_out),
        .cordic_rot1_opvld(cordic_rot1_opvld),
        .cordic_rot1_xout(cordic_rot1_xout),
        .cordic_rot1_yout(cordic_rot1_yout),
        .ica_cordic_rot1_angle_microRot_n(ica_cordic_rot1_angle_microRot_n),
        .ica_cordic_rot1_microRot_ext_vld(ica_cordic_rot1_microRot_ext_vld)
    );

    // CORDIC wrapper instantiation
    SCICA_CORDIC_wrapper #(
        .DATA_WIDTH(DATA_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES)
    ) cordic_wrapper (
        .clk(clk),
        .nreset(cordic_nrst),
        .scica_stage_in(scica_stage_in),
        
        // ICA Vectoring
        .ica_cordic_vec_en(ica_cordic_vec_en),
        .ica_cordic_vec_xin(ica_cordic_vec_xin),
        .ica_cordic_vec_yin(ica_cordic_vec_yin),
        .ica_cordic_vec_angle_calc_en(ica_cordic_vec_angle_calc_en),

        // ICA Rotation1
        .ica_cordic_rot1_en(ica_cordic_rot1_en),
        .ica_cordic_rot1_xin(ica_cordic_rot1_xin),
        .ica_cordic_rot1_yin(ica_cordic_rot1_yin),
        .ica_cordic_rot1_angle_in({ANGLE_WIDTH{1'b0}}),
        .ica_cordic_rot1_microRot_ext_in(ica_cordic_rot1_microRot_in),
        .ica_cordic_rot1_quad_in(ica_cordic_rot1_quad_in),
        .ica_cordic_rot1_angle_microRot_n(ica_cordic_rot1_angle_microRot_n),
        .ica_cordic_rot1_microRot_ext_vld(ica_cordic_rot1_microRot_ext_vld),
        
        // ICA Rotation2 (unused)
        .ica_cordic_rot2_en(1'b0),
        .ica_cordic_rot2_xin({DATA_WIDTH{1'b0}}),
        .ica_cordic_rot2_yin({DATA_WIDTH{1'b0}}),
        .ica_cordic_rot2_quad_in(2'b00),
        .ica_cordic_rot2_microRot_in({CORDIC_STAGES{1'b0}}),

        // EVD (unused)
        .evd_cordic_vec_en(1'b0),
        .evd_cordic_vec_xin({DATA_WIDTH{1'b0}}),
        .evd_cordic_vec_yin({DATA_WIDTH{1'b0}}),
        .evd_cordic_vec_angle_calc_en(1'b0),
        .evd_cordic_rot1_en(1'b0),
        .evd_cordic_rot1_xin({DATA_WIDTH{1'b0}}),
        .evd_cordic_rot1_yin({DATA_WIDTH{1'b0}}),
        .evd_cordic_rot1_angle_microRot_n(1'b0),
        .evd_cordic_rot1_angle_in({ANGLE_WIDTH{1'b0}}),
        .evd_cordic_rot2_en(1'b0),
        .evd_cordic_rot2_xin({DATA_WIDTH{1'b0}}),
        .evd_cordic_rot2_yin({DATA_WIDTH{1'b0}}),
        .evd_cordic_rot2_angle_microRot_n(1'b0),
        
        // FFT (unused)
        .fft_cordic_rot_en(1'b0),
        .fft_cordic_rot_xin({DATA_WIDTH{1'b0}}),
        .fft_cordic_rot_yin({DATA_WIDTH{1'b0}}),
        .fft_cordic_rot_angle_in({ANGLE_WIDTH{1'b0}}),
        
        // K-means (unused)
        .kmeans_cordic_vec_en(1'b0),
        .kmeans_cordic_vec_xin({DATA_WIDTH{1'b0}}),
        .kmeans_cordic_vec_yin({DATA_WIDTH{1'b0}}),
        
        // Outputs
        .cordic_vec_opvld(cordic_vec_opvld),
        .cordic_vec_xout(cordic_vec_xout),
        .cordic_vec_microRot_out(cordic_vec_microRot_out),
        .cordic_vec_quad_out(cordic_vec_quad_out),
        .cordic_vec_microRot_out_start(cordic_vec_microRot_out_start),
        .cordic_vec_angle_out(cordic_vec_angle_out),
        
        .cordic_rot1_opvld(cordic_rot1_opvld),
        .cordic_rot1_xout(cordic_rot1_xout),
        .cordic_rot1_yout(cordic_rot1_yout)
    );

    initial begin
      $dumpfile("out_norm_5d.vcd");
      $dumpvars(0);
    end

endmodule
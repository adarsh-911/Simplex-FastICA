`timescale 1ns / 1ps

module tb_updateTop();

    parameter N = 7;
    parameter M = 8;
    parameter DATA_WIDTH = 16;
    parameter FRAC_WIDTH = 10;
    parameter CORDIC_WIDTH = 22;
    parameter ANGLE_WIDTH = 16;
    parameter CORDIC_STAGES = 16;
    parameter CLK_PERIOD = 10;
    parameter LOGM = 3;

    reg clk;
    reg rst_n;
    reg nreset;
    reg en;
    reg [N*DATA_WIDTH-1:0] W_in;
    reg [N*M*DATA_WIDTH-1:0] Z_in;
    reg [1:0] scica_stage_in;
    
    wire ica_cordic_vec_en;
    wire signed [DATA_WIDTH-1:0] ica_cordic_vec_xin;
    wire signed [DATA_WIDTH-1:0] ica_cordic_vec_yin;
    wire ica_cordic_vec_angle_calc_en;
    wire ica_cordic_rot1_en;
    wire signed [DATA_WIDTH-1:0] ica_cordic_rot1_xin;
    wire signed [DATA_WIDTH-1:0] ica_cordic_rot1_yin;
    wire signed [ANGLE_WIDTH-1:0] ica_cordic_rot1_angle_in;
    wire ica_cordic_rot1_angle_microRot_n;
    wire [CORDIC_STAGES-1:0] ica_cordic_rot1_microRot_ext_in;
    wire ica_cordic_rot1_microRot_ext_vld;
    wire [1:0] ica_cordic_rot1_quad_in;
    
    wire cordic_vec_opvld;
    wire signed [DATA_WIDTH-1:0] cordic_vec_xout;
    wire [1:0] cordic_vec_quad_out;
    wire cordic_vec_microRot_out_start;
    wire cordic_rot1_opvld;
    wire signed [DATA_WIDTH-1:0] cordic_rot1_xout;
    
    // Keep unused CORDIC outputs for the CORDIC wrapper
    wire [CORDIC_STAGES-1:0] cordic_vec_microRot_out;
    wire signed [ANGLE_WIDTH-1:0] cordic_vec_angle_out;
    wire signed [DATA_WIDTH-1:0] cordic_rot1_yout;
    wire cordic_rot2_opvld;
    wire signed [DATA_WIDTH-1:0] cordic_rot2_xout;
    wire signed [DATA_WIDTH-1:0] cordic_rot2_yout;
    wire ica_cordic_rot2_en;
    wire signed [DATA_WIDTH-1:0] ica_cordic_rot2_xin;
    wire signed [DATA_WIDTH-1:0] ica_cordic_rot2_yin;
    wire [1:0] ica_cordic_rot2_quad_in;
    wire [CORDIC_STAGES-1:0] ica_cordic_rot2_microRot_in;
    
    wire [N*DATA_WIDTH-1:0] W_out;
    wire output_valid;

    reg [DATA_WIDTH-1:0] W_test [0:N-1];
    reg [DATA_WIDTH-1:0] Z_test [0:(N*M)-1];
    reg [DATA_WIDTH-1:0] expected [0:N-1];
    integer vector_count;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $readmemh("_W_in.mem", W_test);
        $readmemh("_Z_in.mem", Z_test);
        $readmemh("_expected.mem", expected);
        
        $dumpfile("tb_updateTop.vcd");
        $dumpvars(0, tb_updateTop);
        
        vector_count = 0;
        rst_n = 0; nreset = 0; en = 0; W_in = 0; Z_in = 0; scica_stage_in = 2'b01;
        #30;
        rst_n = 1; nreset = 1;
        #20;
        
        run_test();
        
        #100;
        $finish;
    end

    task run_test;
        integer i, j;
        begin
            for (i = 0; i < N; i = i + 1)
                W_in[i*DATA_WIDTH +: DATA_WIDTH] = W_test[i];
            
            for (i = 0; i < M; i = i + 1)
                for (j = 0; j < N; j = j + 1)
                    Z_in[(i*N + j)*DATA_WIDTH +: DATA_WIDTH] = Z_test[i*N + j];
            
            $display("Starting test with:");
            $display("W_in: %h", W_in);
            $display("Z_in: %h", Z_in);
            
            en = 1;
            wait (output_valid == 1);
            en = 0;
            
            $display("Test Results:");
            for (i = 0; i < N; i = i + 1) begin
                // if (W_out[i*DATA_WIDTH +: DATA_WIDTH] == expected[i])
                //     $display("PASS: Vector %0d, W[%0d] = %04x (Expected = %04x)", 
                //             vector_count, i, W_out[i*DATA_WIDTH +: DATA_WIDTH], expected[i]);
                // else
                //     $display("FAIL: Vector %0d, W[%0d] = %04x, Expected = %04x", 
                //             vector_count, i, W_out[i*DATA_WIDTH +: DATA_WIDTH], expected[i]);
                $display("Vector %0d, W[%0d] = %04x (Expected = %04x)", 
                        vector_count, i, W_out[i*DATA_WIDTH +: DATA_WIDTH], expected[i]);
            end
            
            vector_count = vector_count + 1;
            #10;
            rst_n = 0;
            #10;
            rst_n = 1;
            #20;
        end
    endtask

    updateTop #(
        .N(N), .M(M), .DATA_WIDTH(DATA_WIDTH), .FRAC_WIDTH(FRAC_WIDTH),
        .CORDIC_WIDTH(CORDIC_WIDTH), .ANGLE_WIDTH(ANGLE_WIDTH), .CORDIC_STAGES(CORDIC_STAGES), .LOGM(LOGM)
    ) uut_updateTop (
        .clk(clk), 
        .rst_n(rst_n), 
        .en(en), 
        .W_in(W_in), 
        .Z_in(Z_in),
        .cordic_vec_opvld(cordic_vec_opvld), 
        .cordic_vec_xout(cordic_vec_xout),
        .cordic_vec_quad_out(cordic_vec_quad_out),
        .cordic_vec_microRot_out_start(cordic_vec_microRot_out_start), 
        .cordic_rot1_opvld(cordic_rot1_opvld), 
        .cordic_rot1_xout(cordic_rot1_xout), 
        .ica_cordic_vec_en(ica_cordic_vec_en), 
        .ica_cordic_vec_xin(ica_cordic_vec_xin),
        .ica_cordic_vec_yin(ica_cordic_vec_yin), 
        .ica_cordic_vec_angle_calc_en(ica_cordic_vec_angle_calc_en),
        .ica_cordic_rot1_en(ica_cordic_rot1_en), 
        .ica_cordic_rot1_xin(ica_cordic_rot1_xin),
        .ica_cordic_rot1_yin(ica_cordic_rot1_yin), 
        .ica_cordic_rot1_angle_in(ica_cordic_rot1_angle_in),
        .ica_cordic_rot1_angle_microRot_n(ica_cordic_rot1_angle_microRot_n),
        .ica_cordic_rot1_microRot_ext_in(ica_cordic_rot1_microRot_ext_in),
        .ica_cordic_rot1_microRot_ext_vld(ica_cordic_rot1_microRot_ext_vld),
        .ica_cordic_rot1_quad_in(ica_cordic_rot1_quad_in), 
        .W_out(W_out), 
        .output_valid(output_valid)
    );

    SCICA_CORDIC_wrapper #(
        .DATA_WIDTH(DATA_WIDTH), .CORDIC_STAGES(CORDIC_STAGES), .CORDIC_WIDTH(CORDIC_WIDTH), .ANGLE_WIDTH(ANGLE_WIDTH)
    ) dut_cordic (
        .clk(clk), .nreset(nreset), .scica_stage_in(scica_stage_in),
        .ica_cordic_vec_en(ica_cordic_vec_en), .ica_cordic_vec_xin(ica_cordic_vec_xin),
        .ica_cordic_vec_yin(ica_cordic_vec_yin), .ica_cordic_vec_angle_calc_en(ica_cordic_vec_angle_calc_en),
        .ica_cordic_rot1_en(ica_cordic_rot1_en), .ica_cordic_rot1_xin(ica_cordic_rot1_xin),
        .ica_cordic_rot1_yin(ica_cordic_rot1_yin), .ica_cordic_rot1_angle_in(ica_cordic_rot1_angle_in),
        .ica_cordic_rot1_angle_microRot_n(ica_cordic_rot1_angle_microRot_n),
        .ica_cordic_rot1_microRot_ext_in(ica_cordic_rot1_microRot_ext_in),
        .ica_cordic_rot1_microRot_ext_vld(ica_cordic_rot1_microRot_ext_vld),
        .ica_cordic_rot1_quad_in(ica_cordic_rot1_quad_in), .ica_cordic_rot2_en(ica_cordic_rot2_en),
        .ica_cordic_rot2_xin(ica_cordic_rot2_xin), .ica_cordic_rot2_yin(ica_cordic_rot2_yin),
        .ica_cordic_rot2_quad_in(ica_cordic_rot2_quad_in), .ica_cordic_rot2_microRot_in(ica_cordic_rot2_microRot_in),
        .cordic_vec_opvld(cordic_vec_opvld), .cordic_vec_xout(cordic_vec_xout),
        .cordic_vec_microRot_out(cordic_vec_microRot_out), .cordic_vec_quad_out(cordic_vec_quad_out),
        .cordic_vec_microRot_out_start(cordic_vec_microRot_out_start), .cordic_vec_angle_out(cordic_vec_angle_out),
        .cordic_rot1_opvld(cordic_rot1_opvld), .cordic_rot1_xout(cordic_rot1_xout), .cordic_rot1_yout(cordic_rot1_yout),
        .cordic_rot2_opvld(cordic_rot2_opvld), .cordic_rot2_xout(cordic_rot2_xout), .cordic_rot2_yout(cordic_rot2_yout)
    );

endmodule
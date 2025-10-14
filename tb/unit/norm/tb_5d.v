`timescale 1ns / 1ps

module tb_5d_pipe();
    parameter DIMENSIONS = 5;
    parameter DATA_WIDTH = 32;
    parameter CORDIC_WIDTH = 38;      
    parameter CORDIC_STAGES = 16;
    parameter ANGLE_WIDTH = 16;
    parameter CLOCK_PERIOD = 10;
    
    reg clk;
    reg nreset;
    reg [DIMENSIONS*DATA_WIDTH-1:0] w_in;
    reg [DIMENSIONS*DATA_WIDTH-1:0] w_in_temp [0:0];
    reg start;
    reg [1:0] scica_stage_in;  

    wire [DIMENSIONS*DATA_WIDTH-1:0] W_out;
    wire done;

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
    integer fd;

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
        //w_in = {160'hfffefffffffefffffffefffffffefffffffeffff}; 
        //w_in = {160'h0010000000100000001000000010000000100000}; 
        //w_in = {160'hffffffffffffffffffffffffffffffffffffffff}; 
        //w_in = {32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};
        //$dumpfile("build/sim/icarus/dump.vcd");
        //$dumpvars(0, tb_5d_pipe);
        $readmemh("sw-test/unit/norm/_wTest.mem", w_in_temp);
        w_in = w_in_temp[0];

        start = 1;
        #20 start = 0;
        start_cycle = cycle_count;  
        wait(done);
        end_cycle = cycle_count;  
        $display("Test 1 took %0d cycles", end_cycle - start_cycle);
        #20;

        fd = $fopen("sw-test/unit/norm/out/sim.raw", "w");
        $fwrite(fd, "%h", W_out);
        /*
        $display("Input Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f",
         $itor($signed(w_in[159:128]))/1048576.0,
         $itor($signed(w_in[127:96]))/1048576.0,
         $itor($signed(w_in[95:64]))/1048576.0,
         $itor($signed(w_in[63:32]))/1048576.0,
         $itor($signed(w_in[31:0]))/1048576.0);

        $display("Output Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f", 
         $itor($signed(W_out[159:128]))/1048576.0,
         $itor($signed(W_out[127:96]))/1048576.0,
         $itor($signed(W_out[95:64]))/1048576.0,
         $itor($signed(W_out[63:32]))/1048576.0,
         $itor($signed(W_out[31:0]))/1048576.0);
        #50;

        $display("Test 2:(w5,w4,w3,w2,w1) format (15.0, 0.0, 1.0, 0.0, 3.0)");
        w_in = {32'h00f00000, 32'h00000000, 32'h00100000, 32'h00000000, 32'h00300000}; 
        start = 1;
        #20 start = 0;
        start_cycle = cycle_count;  
        wait(done);
        end_cycle = cycle_count;  
        $display("Test 2 took %0d cycles", end_cycle - start_cycle);
        #20;
        $display("Input Decimal: w4=%.0f, w3=%.0f, w2=%.0f, w1=%.0f, w0=%.0f",
         $itor($signed(w_in[159:128]))/1048576.0,
         $itor($signed(w_in[127:96]))/1048576.0,
         $itor($signed(w_in[95:64]))/1048576.0,
         $itor($signed(w_in[63:32]))/1048576.0,
         $itor($signed(w_in[31:0]))/1048576.0);

        $display("Output Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f", 
         $itor($signed(W_out[159:128]))/1048576.0,
         $itor($signed(W_out[127:96]))/1048576.0,
         $itor($signed(W_out[95:64]))/1048576.0,
         $itor($signed(W_out[63:32]))/1048576.0,
         $itor($signed(W_out[31:0]))/1048576.0);
        #50;

        $display("Test 3: Mixed signs (3.0, 0.0, -4.0, 20.0, 5.0)");
        w_in = {32'h00300000, 32'h00000000, 32'hFFC00000, 32'h01400000, 32'h00500000};
        start = 1;
        #20 start = 0;
        start_cycle = cycle_count;  
        wait(done);
        end_cycle = cycle_count;  
        $display("Test 3 took %0d cycles", end_cycle - start_cycle);
        #20;
        $display("Input Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f",
         $itor($signed(w_in[159:128]))/1048576.0,
         $itor($signed(w_in[127:96]))/1048576.0,
         $itor($signed(w_in[95:64]))/1048576.0,
         $itor($signed(w_in[63:32]))/1048576.0,
         $itor($signed(w_in[31:0]))/1048576.0);

        $display("Output Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f", 
         $itor($signed(W_out[159:128]))/1048576.0,
         $itor($signed(W_out[127:96]))/1048576.0,
         $itor($signed(W_out[95:64]))/1048576.0,
         $itor($signed(W_out[63:32]))/1048576.0,
         $itor($signed(W_out[31:0]))/1048576.0);
        #50;


        $display("Test 4: small positive values ");
        w_in = {32'h00000100, 32'h00000100, 32'h00000100, 32'h00000100, 32'h00000100};
        start = 1;
        #20 start = 0;
        start_cycle = cycle_count;  
        wait(done);
        end_cycle = cycle_count;  
        $display("Test 4 took %0d cycles", end_cycle - start_cycle);
        #20;
        $display("Input Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f",
         $itor($signed(w_in[159:128]))/1048576.0,
         $itor($signed(w_in[127:96]))/1048576.0,
         $itor($signed(w_in[95:64]))/1048576.0,
         $itor($signed(w_in[63:32]))/1048576.0,
         $itor($signed(w_in[31:0]))/1048576.0);

        $display("Output Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f", 
         $itor($signed(W_out[159:128]))/1048576.0,
         $itor($signed(W_out[127:96]))/1048576.0,
         $itor($signed(W_out[95:64]))/1048576.0,
         $itor($signed(W_out[63:32]))/1048576.0,
         $itor($signed(W_out[31:0]))/1048576.0);
         */

        // $display("Test 5: all zeroes (0,0,0,0,0)");
        // w_in = {32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000}; 
        // start = 1;
        // #20 start = 0;
        // start_cycle = cycle_count;  
        // wait(done);
        // end_cycle = cycle_count;  
        // $display("Test 5 took %0d cycles", end_cycle - start_cycle);
        // #20;
        // $display("Input Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f",
        //  $itor($signed(w_in[159:128]))/1048576.0,
        //  $itor($signed(w_in[127:96]))/1048576.0,
        //  $itor($signed(w_in[95:64]))/1048576.0,
        //  $itor($signed(w_in[63:32]))/1048576.0,
        //  $itor($signed(w_in[31:0]))/1048576.0); 

        // $display("Output Decimal: w4=%.6f, w3=%.6f, w2=%.6f, w1=%.6f, w0=%.6f", 
        //  $itor($signed(W_out[159:128]))/1048576.0,
        //  $itor($signed(W_out[127:96]))/1048576.0,
        //  $itor($signed(W_out[95:64]))/1048576.0,
        //  $itor($signed(W_out[63:32]))/1048576.0,
        //  $itor($signed(W_out[31:0]))/1048576.0);
         
        #50 $finish;
    end

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
    /*

    SCICA_CORDIC_wrapper #(
        .DATA_WIDTH(DATA_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES)
    ) cordic_wrapper (
        .clk(clk),
        .nreset(cordic_nrst),
        .scica_stage_in(scica_stage_in),
        .ica_cordic_vec_en(ica_cordic_vec_en),
        .ica_cordic_vec_xin(ica_cordic_vec_xin),
        .ica_cordic_vec_yin(ica_cordic_vec_yin),
        .ica_cordic_vec_angle_calc_en(ica_cordic_vec_angle_calc_en),
        .ica_cordic_rot1_en(ica_cordic_rot1_en),
        .ica_cordic_rot1_xin(ica_cordic_rot1_xin),
        .ica_cordic_rot1_yin(ica_cordic_rot1_yin),
        .ica_cordic_rot1_angle_in({ANGLE_WIDTH{1'b0}}),
        .ica_cordic_rot1_microRot_ext_in(ica_cordic_rot1_microRot_in),
        .ica_cordic_rot1_quad_in(ica_cordic_rot1_quad_in),
        .ica_cordic_rot1_angle_microRot_n(ica_cordic_rot1_angle_microRot_n),
        .ica_cordic_rot1_microRot_ext_vld(ica_cordic_rot1_microRot_ext_vld),
        .ica_cordic_rot2_en(1'b0),
        .ica_cordic_rot2_xin({DATA_WIDTH{1'b0}}),
        .ica_cordic_rot2_yin({DATA_WIDTH{1'b0}}),
        .ica_cordic_rot2_quad_in(2'b00),
        .ica_cordic_rot2_microRot_in({CORDIC_STAGES{1'b0}}),
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
        .fft_cordic_rot_en(1'b0),
        .fft_cordic_rot_xin({DATA_WIDTH{1'b0}}),
        .fft_cordic_rot_yin({DATA_WIDTH{1'b0}}),
        .fft_cordic_rot_angle_in({ANGLE_WIDTH{1'b0}}),
        .kmeans_cordic_vec_en(1'b0),
        .kmeans_cordic_vec_xin({DATA_WIDTH{1'b0}}),
        .kmeans_cordic_vec_yin({DATA_WIDTH{1'b0}}),
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
    */

    CORDIC_doubly_pipe_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES)
    ) u_cordic (
        .clk(clk),
        .nreset(cordic_nrst),

        .cordic_vec_en(ica_cordic_vec_en),
        .cordic_vec_xin(ica_cordic_vec_xin),
        .cordic_vec_yin(ica_cordic_vec_yin),
        .cordic_vec_angle_calc_en(ica_cordic_vec_angle_calc_en),

        .cordic_rot_en(ica_cordic_rot1_en),
        .cordic_rot_xin(ica_cordic_rot1_xin),
        .cordic_rot_yin(ica_cordic_rot1_yin),
        .cordic_rot_angle_microRot_n(ica_cordic_rot1_angle_microRot_n),
        .cordic_rot_angle_in({ANGLE_WIDTH{1'b0}}),
        .cordic_rot_microRot_ext_in(ica_cordic_rot1_microRot_in),
        .cordic_rot_microRot_ext_vld(ica_cordic_rot1_microRot_ext_vld),
        .cordic_rot_quad_in(ica_cordic_rot1_quad_in),

        .cordic_vec_opvld(cordic_vec_opvld),
        .cordic_vec_xout(cordic_vec_xout),
        .vec_quad(cordic_vec_quad_out),
        .vec_angle_out(cordic_vec_angle_out),
        .vec_microRot_dir(cordic_vec_microRot_out),
        .vec_microRot_out_start(cordic_vec_microRot_out_start),

        .cordic_rot_opvld(cordic_rot1_opvld),
        .cordic_rot_xout(cordic_rot1_xout),
        .cordic_rot_yout(cordic_rot1_yout)
        );
    
  initial begin
    $dumpfile("build/sim/icarus/dump.vcd");
    $dumpvars(0, tb_5d_pipe);
  end

endmodule

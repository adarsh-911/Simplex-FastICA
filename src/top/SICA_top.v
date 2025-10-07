`timescale 1ns / 1ps

module sica_top#(
    parameter DATA_WIDTH      = 16,
    parameter DIM             = 5,
    parameter SAMPLES         = 1024,
    parameter MAX_ITERATIONS  = 100,

    parameter FRAC_WIDTH = 20,
    parameter LOGM = 10,
    parameter LATENCY = 1,
    parameter ADDR_WIDTH = 10,

    // CORDIC Parameters
    parameter CORDIC_WIDTH    = 22,
    parameter ANGLE_WIDTH     = 16,
    parameter CORDIC_STAGES   = 16
)(
    // System Signals
    input clk,
    input nreset, 
    input sica_start,

    // Serial Input from EMD block
    input signed [DATA_WIDTH-1:0] serial_z_in,
    input serial_z_valid,
    input load_data,

    // Final Status Outputs
    output reg sica_complete,
    output reg signed [DATA_WIDTH*DIM*SAMPLES-1:0] s_est
);

    localparam THRESHOLD = (1 << 5);

    // FSM States
    localparam S_IDLE                = 5'b00000;
    localparam S_LOAD_DATA           = 5'b00001;
    localparam S_INIT_K              = 5'b00010;
    localparam S_INIT_VECTORS        = 5'b00011;
    localparam S_GSO                 = 5'b00100;
    localparam S_CHECK_SIMPLEX       = 5'b00101;
    localparam S_NORMALIZE           = 5'b00110;
    localparam S_CONVERGENCE         = 5'b00111;
    localparam S_CONVERGENCE_CHECK   = 5'b01000;
    localparam S_UPDATE              = 5'b01001;
    localparam S_ITER_DONE           = 5'b01010;
    localparam S_THETA_BLOCK         = 5'b01011;
    localparam S_FINISH_K            = 5'b01100;
    localparam S_ESTIMATION          = 5'b01101;
    localparam S_COMPLETE            = 5'b01110;

    reg [4:0] state;

    // Data Storage
    reg signed [DATA_WIDTH*DIM*DIM-1:0] w_mat;
    reg signed [DATA_WIDTH*DIM-1:0] w_curr;

    // Counters
    reg [$clog2(DIM)-1:0] k_idx;
    reg [$clog2(MAX_ITERATIONS)-1:0] iter_count;
    reg [$clog2(SAMPLES*DIM)-1:0] load_count;
    
    wire [DATA_WIDTH-1:0] Z_in1, Z_in2;
    wire [ADDR_WIDTH-1:0] addr1, addr2;
    wire Z_in_en;

    // Enable flags for each processing block
    reg updt_en, gso_en, norm_en, conv_en, est_en, theta_en;
    // Reset flags
    reg updt_nrst, gso_nrst, norm_nrst, conv_nrst, est_nrst, theta_nrst;

    integer i;

    // Done flags from each processing block
    wire updt_done, gso_done, norm_done, conv_done, est_done, theta_done;
    wire [DATA_WIDTH*DIM-1:0] gso_w_out, updt_w_out, norm_out;
    wire [DATA_WIDTH-1:0] conv_out;
    wire [0:ANGLE_WIDTH*(DIM-1)-1] theta_out;

    reg norm_diff;

    // Data wires between blocks
    //wire signed [DATA_WIDTH*DIM*SAMPLES-1:0] s_est;
    reg [0:DATA_WIDTH*DIM*SAMPLES-1] z_in;
    reg [0:ANGLE_WIDTH*(DIM-1)-1] thetas;
    reg done_load;
    reg zmem_writeEn;
    //Variables used in the modules
        //Mux
        wire mux_en, mux_nrst;
        reg [2:0] cordic_input_mux_block;

        wire gso_cordic_vec_en, gso_cordic_rot_en, gso_cordic_vec_angle_calc_en, gso_cordic_rot_microRot_ext_vld, gso_cordic_nrst, gso_cordic_rot_angle_microRot_n;
        wire [DATA_WIDTH-1:0] gso_cordic_vec_xin, gso_cordic_vec_yin,  gso_cordic_rot_xin, gso_cordic_rot_yin;
        wire [ANGLE_WIDTH-1:0]  gso_cordic_rot_angle_in;
        wire [CORDIC_STAGES-1:0] gso_cordic_rot_microRot_ext_in;
        wire [1:0] gso_cordic_rot_quad_in;

        wire norm_cordic_vec_en, norm_cordic_rot_en, norm_cordic_vec_angle_calc_en, norm_cordic_rot_angle_microRot_n, norm_cordic_rot_microRot_ext_vld, norm_cordic_nrst;
        wire [DATA_WIDTH-1:0] norm_cordic_vec_xin, norm_cordic_vec_yin, norm_cordic_rot_xin, norm_cordic_rot_yin;
        wire [ANGLE_WIDTH-1:0] norm_cordic_rot_angle_in;
        wire [CORDIC_STAGES-1:0] norm_cordic_rot_microRot_ext_in;
        wire [1:0] norm_cordic_rot_quad_in;
        
        wire est_cordic_vec_en, est_cordic_rot_en, est_cordic_vec_angle_calc_en, est_cordic_rot_angle_microRot_n, est_cordic_rot_microRot_ext_vld, est_cordic_nrst;
        wire [DATA_WIDTH-1:0] est_cordic_vec_xin, est_cordic_vec_yin, est_cordic_rot_xin, est_cordic_rot_yin;
        wire [ANGLE_WIDTH-1:0] est_cordic_rot_angle_in;
        wire [CORDIC_STAGES-1:0] est_cordic_rot_microRot_ext_in;
        wire [1:0] est_cordic_rot_quad_in;

        wire updt_cordic_vec_en, updt_cordic_rot_en, updt_cordic_vec_angle_calc_en, updt_cordic_rot_angle_microRot_n, updt_cordic_rot_microRot_ext_vld, updt_cordic_nrst;
        wire [DATA_WIDTH-1:0] updt_cordic_vec_xin, updt_cordic_vec_yin, updt_cordic_rot_xin, updt_cordic_rot_yin;
        wire [ANGLE_WIDTH-1:0] updt_cordic_rot_angle_in;
        wire [CORDIC_STAGES-1:0] updt_cordic_rot_microRot_ext_in;
        wire [1:0] updt_cordic_rot_quad_in;

        wire conv_cordic_vec_en, conv_cordic_rot_en, conv_cordic_vec_angle_calc_en, conv_cordic_rot_angle_microRot_n, conv_cordic_rot_microRot_ext_vld, conv_cordic_nrst;
        wire [DATA_WIDTH-1:0] conv_cordic_vec_xin, conv_cordic_vec_yin, conv_cordic_rot_xin, conv_cordic_rot_yin;
        wire [ANGLE_WIDTH-1:0] conv_cordic_rot_angle_in;
        wire [CORDIC_STAGES-1:0] conv_cordic_rot_microRot_ext_in;
        wire [1:0] conv_cordic_rot_quad_in;

        wire theta_cordic_vec_en, theta_cordic_rot_en, theta_cordic_vec_angle_calc_en, theta_cordic_rot_angle_microRot_n, theta_cordic_rot_microRot_ext_vld, theta_cordic_nrst;
        wire [DATA_WIDTH-1:0] theta_cordic_vec_xin, theta_cordic_vec_yin, theta_cordic_rot_xin, theta_cordic_rot_yin;
        wire [ANGLE_WIDTH-1:0] theta_cordic_rot_angle_in;
        wire [CORDIC_STAGES-1:0] theta_cordic_rot_microRot_ext_in;
        wire [1:0] theta_cordic_rot_quad_in;
        
        //Common 
        wire cordic_vec_en, cordic_rot_en,  cordic_vec_angle_calc_en, cordic_rot_angle_microRot_n, cordic_rot_microRot_ext_vld;
        wire [DATA_WIDTH-1:0] cordic_vec_xin, cordic_vec_yin, cordic_rot_xin, cordic_rot_yin;
        wire [ANGLE_WIDTH-1:0] cordic_rot_angle_in;
        wire [CORDIC_STAGES-1:0] cordic_rot_microRot_ext_in;
        wire [1:0] cordic_rot_quad_in;

        //Common cordic o/p
        wire cordic_nrst, cordic_vec_opvld, vec_microRot_out_start, cordic_rot_opvld;
        wire [DATA_WIDTH-1:0]  cordic_vec_xout, cordic_rot_xout, cordic_rot_yout;
        wire [ANGLE_WIDTH-1:0] vec_angle_out;
        wire [CORDIC_STAGES-1:0] vec_microRot_dir;
        wire [1:0] vec_quad;
        //GSO
        reg [2:0]kin;
        //Theta block
        reg [ANGLE_WIDTH*(DIM-1)*(DIM-1)-1:0] thetas_in_flat;
        reg [DATA_WIDTH-1:0]xf, theta_xout, theta_yout;
    //Instantiating modules
    CONTROL_MUX_CORDIC #(
        .DATA_WIDTH(DATA_WIDTH),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES)
    ) mux_inst(
        .clk(clk),
        .en(mux_en), 
        .nrst(nreset), 
        .block(cordic_input_mux_block), 
        //GSO MUX
        .gso_cordic_vec_en(gso_cordic_vec_en),
        .gso_cordic_rot_en(gso_cordic_rot_en),

        .gso_cordic_vec_xin(gso_cordic_vec_xin),
        .gso_cordic_vec_yin(gso_cordic_vec_yin),
        .gso_cordic_vec_angle_calc_en(gso_cordic_vec_angle_calc_en),

        .gso_cordic_rot_quad_in(gso_cordic_rot_quad_in),
        .gso_cordic_rot_xin(gso_cordic_rot_xin),
        .gso_cordic_rot_yin(gso_cordic_rot_yin),
        .gso_cordic_rot_angle_in(gso_cordic_rot_angle_in),
        .gso_cordic_rot_microRot_ext_in(gso_cordic_rot_microRot_ext_in),
        .gso_cordic_rot_angle_microRot_n(gso_cordic_rot_angle_microRot_n),
        .gso_cordic_rot_microRot_ext_vld(gso_cordic_rot_microRot_ext_vld),
        .gso_cordic_nrst(gso_cordic_nrst),

        // NORMALIZATION MUX
        .norm_cordic_vec_en(norm_cordic_vec_en),
        .norm_cordic_rot_en(norm_cordic_rot_en),

        .norm_cordic_vec_xin(norm_cordic_vec_xin),
        .norm_cordic_vec_yin(norm_cordic_vec_yin),
        .norm_cordic_vec_angle_calc_en(norm_cordic_vec_angle_calc_en),

        .norm_cordic_rot_quad_in(norm_cordic_rot_quad_in),
        .norm_cordic_rot_xin(norm_cordic_rot_xin),
        .norm_cordic_rot_yin(norm_cordic_rot_yin),
        .norm_cordic_rot_angle_in(norm_cordic_rot_angle_in),
        .norm_cordic_rot_microRot_ext_in(norm_cordic_rot_microRot_ext_in),
        .norm_cordic_rot_angle_microRot_n(norm_cordic_rot_angle_microRot_n),
        .norm_cordic_rot_microRot_ext_vld(norm_cordic_rot_microRot_ext_vld),
        .norm_cordic_nrst(norm_cordic_nrst),

        // UPDATE MUX
        .updt_cordic_vec_en(updt_cordic_vec_en),
        .updt_cordic_rot_en(updt_cordic_rot_en),

        .updt_cordic_vec_xin(updt_cordic_vec_xin),
        .updt_cordic_vec_yin(updt_cordic_vec_yin),
        .updt_cordic_vec_angle_calc_en(updt_cordic_vec_angle_calc_en),

        .updt_cordic_rot_quad_in(updt_cordic_rot_quad_in),
        .updt_cordic_rot_xin(updt_cordic_rot_xin),
        .updt_cordic_rot_yin(updt_cordic_rot_yin),
        .updt_cordic_rot_angle_in(updt_cordic_rot_angle_in),
        .updt_cordic_rot_microRot_ext_in(updt_cordic_rot_microRot_ext_in),
        .updt_cordic_rot_angle_microRot_n(updt_cordic_rot_angle_microRot_n),
        .updt_cordic_rot_microRot_ext_vld(updt_cordic_rot_microRot_ext_vld),
        .updt_cordic_nrst(updt_cordic_nrst),

        // ESTIMATION MUX
        .est_cordic_vec_en(est_cordic_vec_en),
        .est_cordic_rot_en(est_cordic_rot_en),

        .est_cordic_vec_xin(est_cordic_vec_xin),
        .est_cordic_vec_yin(est_cordic_vec_yin),
        .est_cordic_vec_angle_calc_en(est_cordic_vec_angle_calc_en),

        .est_cordic_rot_quad_in(est_cordic_rot_quad_in),
        .est_cordic_rot_xin(est_cordic_rot_xin),
        .est_cordic_rot_yin(est_cordic_rot_yin),
        .est_cordic_rot_angle_in(est_cordic_rot_angle_in),
        .est_cordic_rot_microRot_ext_in(est_cordic_rot_microRot_ext_in),
        .est_cordic_rot_angle_microRot_n(est_cordic_rot_angle_microRot_n),
        .est_cordic_rot_microRot_ext_vld(est_cordic_rot_microRot_ext_vld),
        .est_cordic_nrst(est_cordic_nrst),

        // CONVERGENCE MUX
        .conv_cordic_vec_en(conv_cordic_vec_en),
        .conv_cordic_rot_en(conv_cordic_rot_en),

        .conv_cordic_vec_xin(conv_cordic_vec_xin),
        .conv_cordic_vec_yin(conv_cordic_vec_yin),
        .conv_cordic_vec_angle_calc_en(conv_cordic_vec_angle_calc_en),

        .conv_cordic_rot_quad_in(conv_cordic_rot_quad_in),
        .conv_cordic_rot_xin(conv_cordic_rot_xin),
        .conv_cordic_rot_yin(conv_cordic_rot_yin),
        .conv_cordic_rot_angle_in(conv_cordic_rot_angle_in),
        .conv_cordic_rot_microRot_ext_in(conv_cordic_rot_microRot_ext_in),
        .conv_cordic_rot_angle_microRot_n(conv_cordic_rot_angle_microRot_n),
        .conv_cordic_rot_microRot_ext_vld(conv_cordic_rot_microRot_ext_vld),
        .conv_cordic_nrst(conv_cordic_nrst),

        // THETA MUX
        .theta_cordic_vec_en(theta_cordic_vec_en),
        .theta_cordic_rot_en(theta_cordic_rot_en),

        .theta_cordic_vec_xin(theta_cordic_vec_xin),
        .theta_cordic_vec_yin(theta_cordic_vec_yin),
        .theta_cordic_vec_angle_calc_en(theta_cordic_vec_angle_calc_en),

        .theta_cordic_rot_quad_in(theta_cordic_rot_quad_in),
        .theta_cordic_rot_xin(theta_cordic_rot_xin),
        .theta_cordic_rot_yin(theta_cordic_rot_yin),
        .theta_cordic_rot_angle_in(theta_cordic_rot_angle_in),
        .theta_cordic_rot_microRot_ext_in(theta_cordic_rot_microRot_ext_in),
        .theta_cordic_rot_angle_microRot_n(theta_cordic_rot_angle_microRot_n),
        .theta_cordic_rot_microRot_ext_vld(theta_cordic_rot_microRot_ext_vld),
        .theta_cordic_nrst(theta_cordic_nrst),

        // OUTPUT TO CORDIC(MUX OUTPUT)
        .cordic_vec_en(cordic_vec_en),
        .cordic_rot_en(cordic_rot_en),

        .cordic_vec_xin(cordic_vec_xin),
        .cordic_vec_yin(cordic_vec_yin),
        .cordic_vec_angle_calc_en(cordic_vec_angle_calc_en),

        .cordic_rot_quad_in(cordic_rot_quad_in),
        .cordic_rot_xin(cordic_rot_xin),
        .cordic_rot_yin(cordic_rot_yin),
        .cordic_rot_angle_in(cordic_rot_angle_in),
        .cordic_rot_microRot_ext_in(cordic_rot_microRot_ext_in),
        .cordic_rot_angle_microRot_n(cordic_rot_angle_microRot_n),
        .cordic_rot_microRot_ext_vld(cordic_rot_microRot_ext_vld),

        .nreset(cordic_nrst)
        );
    
    //MAIN CORDIC MODULE
    CORDIC_doubly_pipe_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES)
    ) u_cordic (
        .clk(clk),
        .nreset(cordic_nrst),

        .cordic_vec_en(cordic_vec_en),
        .cordic_vec_xin(cordic_vec_xin),
        .cordic_vec_yin(cordic_vec_yin),
        .cordic_vec_angle_calc_en(cordic_vec_angle_calc_en),

        .cordic_rot_en(cordic_rot_en),
        .cordic_rot_xin(cordic_rot_xin),
        .cordic_rot_yin(cordic_rot_yin),
        .cordic_rot_angle_microRot_n(cordic_rot_angle_microRot_n),
        .cordic_rot_angle_in(cordic_rot_angle_in),
        .cordic_rot_microRot_ext_in(cordic_rot_microRot_ext_in),
        .cordic_rot_microRot_ext_vld(cordic_rot_microRot_ext_vld),
        .cordic_rot_quad_in(cordic_rot_quad_in),

        .cordic_vec_opvld(cordic_vec_opvld),
        .cordic_vec_xout(cordic_vec_xout),
        .vec_quad(vec_quad),
        .vec_angle_out(vec_angle_out),
        .vec_microRot_dir(vec_microRot_dir),
        .vec_microRot_out_start(vec_microRot_out_start),

        .cordic_rot_opvld(cordic_rot_opvld),
        .cordic_rot_xout(cordic_rot_xout),
        .cordic_rot_yout(cordic_rot_yout)
        );

    //Estimation Block
    ESTIMATION_TOP #(
        .DATA_WIDTH(DATA_WIDTH), 
        .DIM(DIM), 
        .SAMPLES(SAMPLES),
        .ANGLE_WIDTH(ANGLE_WIDTH), 
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES)
    ) est_inst (
        .en(est_en), 
        .rstn(est_nrst), ////////////////////////////////////CHECK
        .clk(clk),
        .Z_IN(z_in), 
        .W_MAT(w_mat), 
        .est_opvld(est_done),
        //CORDIC VEC
        .vec_quad(vec_quad), 
        .cordic_vec_opvld(cordic_vec_opvld), 
        .cordic_vec_xout(cordic_vec_xout),
        .vec_angle_out(vec_angle_out), 
        .cordic_vec_en(est_cordic_vec_en), 
        .cordic_vec_xin(est_cordic_vec_xin),
        .cordic_vec_yin(est_cordic_vec_yin), 
        .cordic_vec_angle_calc_en(est_cordic_vec_angle_calc_en),

        //CORDIC ROT
        .cordic_rot_opvld(cordic_rot_opvld), 
        .cordic_rot_xout(cordic_rot_xout), 
        .cordic_rot_yout(cordic_rot_yout),
        .vec_microRot_dir(vec_microRot_dir), 
        .vec_microRot_out_start(vec_microRot_out_start), 
        .cordic_rot_en(est_cordic_rot_en), 
        .cordic_rot_quad_in(est_cordic_rot_quad_in), 
        .cordic_rot_xin(est_cordic_rot_xin),
        .cordic_rot_yin(est_cordic_rot_yin), 
        .cordic_rot_angle_in(est_cordic_rot_angle_in), 
        .cordic_rot_microRot_ext_in(est_cordic_rot_microRot_ext_in),
        .cordic_rot_angle_microRot_n(est_cordic_rot_angle_microRot_n), 
        .cordic_rot_microRot_ext_vld(est_cordic_rot_microRot_ext_vld),
        .cordic_nrst(mux_nrst) //////////////////////////CHECK
    );

    //GSO Block
    gso_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .N_DIM(DIM),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES)
    ) gso_controller_inst (
        .clk(clk),
        .rst_n(gso_nrst),
        .en(gso_en),
        .k_in(k_idx + 3'b1),
        .w_in_flat(w_curr), 
        .thetas_in_flat(thetas_in_flat),
        .cordic_rot_xout(cordic_rot_xout),
        .cordic_rot_yout(cordic_rot_yout),
        .cordic_rot_opvld(cordic_rot_opvld),
        .w_out_flat(gso_w_out),
        .done(gso_done),
        .cordic_rot_en(gso_cordic_rot_en),
        .cordic_rot_xin_reg(gso_cordic_rot_xin),
        .cordic_rot_yin_reg(gso_cordic_rot_yin),
        .cordic_rot_angle_in_reg(gso_cordic_rot_angle_in),
        .cordic_rot_angle_microRot_n(gso_cordic_rot_angle_microRot_n),
        .cordic_rot_microRot_ext_vld(gso_cordic_rot_microRot_ext_vld),
        .cordic_rot_quad_in(gso_cordic_rot_quad_in)
    );

    //Normalisation block
    norm_5d #(
        .DIMENSIONS(DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES),
        .ANGLE_WIDTH(ANGLE_WIDTH)
    ) uut (
        .clk(clk),
        .nreset(norm_nrst), ///////CHECK
        .w_in(w_curr),
        .start(norm_en),
        .W_out(norm_out),
        .done(norm_done),
        .cordic_nrst(cordic_nrst),
        .ica_cordic_vec_en(norm_cordic_vec_en),
        .ica_cordic_vec_xin(norm_cordic_vec_xin),
        .ica_cordic_vec_yin(norm_cordic_vec_yin),
        .ica_cordic_vec_angle_calc_en(norm_cordic_vec_angle_calc_en),
        .ica_cordic_rot1_en(norm_cordic_rot_en),
        .ica_cordic_rot1_xin(norm_cordic_rot_xin),
        .ica_cordic_rot1_yin(norm_cordic_rot_yin),
        .ica_cordic_rot1_microRot_in(norm_cordic_rot_microRot_ext_in), ////////////CHECK
        .ica_cordic_rot1_quad_in(norm_cordic_rot_quad_in),
        .cordic_vec_opvld(cordic_vec_opvld),
        .cordic_vec_xout(cordic_vec_xout),
        .cordic_vec_microRot_out(vec_microRot_dir),
        .cordic_vec_quad_out(vec_quad),
        .cordic_vec_microRot_out_start(vec_microRot_out_start),
        .cordic_vec_angle_out(vec_angle_out),
        .cordic_rot1_opvld(cordic_rot_opvld),
        .cordic_rot1_xout(cordic_rot_xout),
        .cordic_rot1_yout(cordic_rot_yout),
        .ica_cordic_rot1_angle_microRot_n(norm_cordic_rot_angle_microRot_n),
        .ica_cordic_rot1_microRot_ext_vld(norm_cordic_rot_microRot_ext_vld)
    );

    //Update block
    updateTop #(
        .N(DIM), 
        .M(SAMPLES), 
        .DATA_WIDTH(DATA_WIDTH), 
        .FRAC_WIDTH(FRAC_WIDTH), 
        .CORDIC_WIDTH(CORDIC_WIDTH), 
        .ANGLE_WIDTH(ANGLE_WIDTH), 
        .CORDIC_STAGES(CORDIC_STAGES), 
        .LOGM(LOGM) 
    ) uut_updateTop (
        .clk(clk), 
        .rst_n(updt_nrst), 
        .en(updt_en), 
        .W_in(w_curr), 
        .Z_in1(Z_in1), /////////////////////ADD
        .Z_in2(Z_in2), ///////////////////ADD
        .cordic_vec_opvld(cordic_vec_opvld), 
        .cordic_vec_xout(cordic_vec_xout),
        .cordic_vec_quad_out(vec_quad),
        .cordic_vec_microRot_out_start(vec_microRot_out_start),//CHECK
        .cordic_rot1_opvld(cordic_rot_opvld), 
        .cordic_rot1_xout(cordic_rot_xout), 
        .ica_cordic_vec_en(updt_cordic_vec_en), 
        .ica_cordic_vec_xin(updt_cordic_vec_xin),
        .ica_cordic_vec_yin(updt_cordic_vec_yin), 
        .ica_cordic_vec_angle_calc_en(updt_cordic_vec_angle_calc_en),
        .ica_cordic_rot1_en(updt_cordic_rot_en), 
        .ica_cordic_rot1_xin(updt_cordic_rot_xin),
        .ica_cordic_rot1_yin(updt_cordic_rot_yin), 
        .ica_cordic_rot1_angle_in(updt_cordic_rot_angle_in),
        .ica_cordic_rot1_angle_microRot_n(updt_cordic_rot_angle_microRot_n),
        .ica_cordic_rot1_microRot_ext_in(updt_cordic_rot_microRot_ext_in),
        .ica_cordic_rot1_microRot_ext_vld(updt_cordic_rot_microRot_ext_vld),
        .ica_cordic_rot1_quad_in(updt_cordic_rot_quad_in),
        .Z_in_en(Z_in_en), //////////////////////////////ADD
        .Z_address1(addr1), //////////////////////////ADD
        .Z_address2(addr2), /////////////////////////ADD
        .W_out(updt_w_out), 
        .output_valid(updt_done)
    );

    //Bram
    zmem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .LATENCY(LATENCY),
        .M(SAMPLES),
        .N(DIM)
    ) memory1(
        .clk(clk),
        .rst_n(nreset),
        .readEn(Z_in_en),
        .writeEn(zmem_writeEn),
        .addr1(addr1),
        .addr2(addr2),
        .din1(serial_z_in),
        .dout1(Z_in1),
        .dout2(Z_in2),
        .dout_valid(Z_in_valid)
    );
    
    //Convergence Block
    w_diff_norm #(
        .N(DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES)
    ) dnorm_inst(
        .clk(clk),
        .rst_n(nreset),
        .en(conv_en),
        .w_in(w_curr),

        .cordic_vec_opvld(cordic_vec_opvld),
        .cordic_vec_xout(cordic_vec_xout),

        .ica_cordic_vec_en(conv_cordic_vec_en),
        .ica_cordic_vec_xin(conv_cordic_vec_xin),
        .ica_cordic_vec_yin(conv_cordic_vec_yin),
        .ica_cordic_vec_angle_calc_en(conv_cordic_vec_angle_calc_en),

        .norm_out(conv_out), /////CHECK
        .output_valid(conv_done) /////CHECK
    );

    //THETA BLOCK
    sequential_cordic_processor#(
        .DATA_WIDTH(DATA_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .N_DIM(DIM),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES)
    ) theta_inst(
        .clk(clk),
        .nreset(theta_nrst),
        .start(theta_en),
        .w_in_flat(w_curr),
        .cordic_xout(xf), //CHECK
        .cordic_angle_out(vec_angle_out),
        .cordic_op_vld(cordic_vec_opvld),
        .cordic_nrst(cordic_nrst),
        .cordic_en(theta_cordic_vec_en),
        .cordic_xin(theta_cordic_vec_xin),
        .cordic_yin(theta_cordic_vec_yin),
        .theta_out(theta_out),
        .done(theta_done)
    );

    always @(posedge clk) begin
        if (!nreset) begin
            state <= S_IDLE;
            k_idx <= 0;
            iter_count <= 0;
            w_curr <= {(DATA_WIDTH*DIM){1'b0}};
            load_count <= {(SAMPLES*DIM){1'b0}};
            done_load <= 0;
            thetas_in_flat <= {(ANGLE_WIDTH*(DIM-1)*(DIM-1)){1'b0}};
            w_mat <= {(DATA_WIDTH*DIM*DIM){1'b0}}; // Initial guess

            cordic_input_mux_block <= 0;

            gso_nrst <= 0;
            updt_nrst <= 0;
            norm_nrst <= 0;
            conv_nrst <= 0;
            theta_nrst <= 0;
            est_nrst <= 0;

            sica_complete <= 0;
        end

        else begin
            case (state)
                S_IDLE: if (sica_start) state <= S_LOAD_DATA;
                S_LOAD_DATA: begin
                zmem_writeEn <= 0; 
                
                if (done_load) begin
                    state <= S_INIT_K; 
                    done_load <= 0;    
                end 
                
                else if (serial_z_valid && load_data) begin
                    z_in[(load_count*DATA_WIDTH) +: DATA_WIDTH] <= serial_z_in[31:0];
                    zmem_writeEn <= 1;

                    if (load_count == (SAMPLES * DIM) - 1) begin
                        done_load <= 1;
                    end 
                    else begin
                        load_count <= load_count + 1;
                    end
                    end
                end

                S_INIT_K : begin
                  k_idx <= 0;
                  state <= S_INIT_VECTORS;
                end

                S_INIT_VECTORS : begin
                    iter_count <= 0;
                    for (i = 0 ; i < DIM ; i = i + 1) begin
                      w_curr[(i*DATA_WIDTH) +: DATA_WIDTH] <= w_mat[(i*DIM + k_idx)*DATA_WIDTH +: DATA_WIDTH];
                    end

                    state <= S_GSO;
                end

                S_GSO : begin
                    if (k_idx == 0) state <= S_NORMALIZE;
                    else begin
                        gso_en <= 1;
                        gso_nrst <= 1;
                        cordic_input_mux_block <= 3'b000;
                        if (gso_done) begin
                            w_curr <= gso_w_out;
                            gso_en <= 0;
                            state <= S_CHECK_SIMPLEX;
                        end
                    end
                end

                S_CHECK_SIMPLEX : begin
                    state <= (k_idx == DIM) ? S_ESTIMATION : S_NORMALIZE;
                end

                S_NORMALIZE : begin
                    norm_en <= 1;
                    norm_nrst <= 1;
                    cordic_input_mux_block <= 3'b001;
                    if (norm_done) begin
                        w_curr <= norm_out;
                        norm_en <= 0;
                        state <= S_CONVERGENCE_CHECK;
                    end
                end

                S_CONVERGENCE : begin
                    if (iter_count == 1) state <= S_UPDATE;
                    else begin
                        conv_en <= 1;
                        conv_nrst <= 1;
                        cordic_input_mux_block <= 3'b100;
                        if (conv_done) begin
                            norm_diff <= conv_out;
                            conv_en <= 0;
                            state <= S_CONVERGENCE_CHECK;
                        end
                    end
                end

                S_CONVERGENCE_CHECK : begin
                    if (norm_diff <= THRESHOLD) state <= S_THETA_BLOCK;
                    else state <= S_UPDATE;
                end

                S_UPDATE : begin
                    updt_en <= 1;
                    updt_nrst <= 1;
                    cordic_input_mux_block <= 3'b010;
                    if (updt_done) begin
                        w_curr <= updt_w_out;
                        updt_en <= 0;
                        state <= S_ITER_DONE;
                    end
                end

                S_ITER_DONE : begin
                    iter_count <= iter_count + 1;
                    cordic_input_mux_block <= 3'b011;

                    gso_nrst <= 0;
                    norm_nrst <= 0;
                    updt_nrst <= 0;

                    state <= S_GSO;
                end

                S_THETA_BLOCK : begin
                    theta_en <= 1;
                    theta_nrst <= 1;
                    cordic_input_mux_block <= 3'b101;
                    if (theta_done) begin
                        xf <= theta_xout;
                        thetas <= theta_out;
                        theta_en <= 0;
                        state <= S_FINISH_K;
                    end

                end

                S_FINISH_K : begin
                    for (i = 0 ; i < DIM ; i = i + 1) begin
                        w_mat[(i*DIM + k_idx)*DATA_WIDTH +: DATA_WIDTH] <= w_curr[(i*DATA_WIDTH) +: DATA_WIDTH];
                    end
                    thetas_in_flat[ANGLE_WIDTH*(DIM-1)*(k_idx) +: ANGLE_WIDTH*(DIM-1)] <= thetas;
                    k_idx <= k_idx + 1;
                    conv_nrst <= 0;
                    theta_nrst <= 0;
                    state <= S_INIT_VECTORS;
                end

                S_ESTIMATION : begin
                    est_en <= 1;
                    est_nrst <= 1;
                    cordic_input_mux_block <= 3'b011;
                    if (est_done) begin
                        est_en <= 0;
                        state <= S_COMPLETE;
                    end
                end

                S_COMPLETE : begin
                    sica_complete <= 1;
                end
            endcase
        end
    end
    
endmodule
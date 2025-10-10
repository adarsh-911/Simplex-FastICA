`timescale 1ps/1ps

module ESTIMATION_TB #(
  parameter DATA_WIDTH = 32,
  parameter DIM = 5,
  parameter SAMPLES = 10,

  parameter ANGLE_WIDTH = 16,
  parameter CORDIC_WIDTH = 38,
  parameter CORDIC_STAGES = 16
) ();

reg en;
reg rstn;
reg clk;
reg signed [0:DATA_WIDTH*DIM*SAMPLES-1] Z_in;
reg signed [0:DATA_WIDTH*DIM*DIM-1] W_mat;
wire done;
wire signed [0:DATA_WIDTH*DIM*SAMPLES-1] S_est;

wire cordic_vec_en;
wire cordic_rot_en;

wire signed [DATA_WIDTH-1:0] cordic_vec_xin;
wire signed [DATA_WIDTH-1:0] cordic_vec_yin;
wire cordic_vec_angle_calc_en;

wire [1:0] cordic_rot_quad_in;
wire signed [DATA_WIDTH-1:0] cordic_rot_xin;
wire signed [DATA_WIDTH-1:0] cordic_rot_yin;
wire signed [ANGLE_WIDTH-1:0] cordic_rot_angle_in;
wire [CORDIC_STAGES-1:0] cordic_rot_microRot_ext_in;
wire cordic_rot_angle_microRot_n;
wire cordic_rot_microRot_ext_vld;

wire [1:0] vec_quad;
wire cordic_vec_opvld;
wire signed [DATA_WIDTH-1:0] cordic_vec_xout;
wire signed [ANGLE_WIDTH-1:0] vec_angle_out;

wire cordic_rot_opvld;
wire signed [DATA_WIDTH-1:0] cordic_rot_xout;
wire signed [DATA_WIDTH-1:0] cordic_rot_yout;
wire [CORDIC_STAGES-1:0] vec_microRot_dir;
wire vec_microRot_out_start;

wire cordic_nrst;

reg [DATA_WIDTH-1:0] S_element;
reg [DATA_WIDTH*DIM*SAMPLES-1:0] S_est_reversed;

reg signed [0:DATA_WIDTH*DIM*SAMPLES-1] temp_z [0:0];
reg signed [0:DATA_WIDTH*DIM*DIM-1] temp_w [0:0];

integer fd;

ESTIMATION_TOP #(
  .DATA_WIDTH(DATA_WIDTH),
  .DIM(DIM),
  .SAMPLES(SAMPLES),
  .ANGLE_WIDTH(ANGLE_WIDTH),
  .CORDIC_WIDTH(CORDIC_WIDTH),
  .CORDIC_STAGES(CORDIC_STAGES)
) _dut (
  .clk(clk),
  .en(en),
  .rstn(rstn),
  .Z_IN(Z_in),
  .W_MAT(W_mat),
  .S_EST(S_est),
  .est_opvld(done),

  .cordic_nrst(cordic_nrst),

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

parameter CLK_CYCLES = 1000000;

initial begin
  clk = 0;
  forever #10 clk = ~clk;
end

integer i, j;

initial begin
  rstn = 0;
  en = 0;
  S_element = 0;

  for (i = 0 ; i < DIM ; i = i + 1) begin
    for (j = 0 ; j < DIM ; j = j + 1) begin
      W_mat[(i*DIM + j)*DATA_WIDTH +: DATA_WIDTH] = i + j;
    end
  end

  for (i = 0 ; i < DIM ; i = i + 1) begin
    for (j = 0 ; j < SAMPLES ; j = j + 1) begin
      Z_in[(i*SAMPLES + j)*DATA_WIDTH +: DATA_WIDTH] = i + j;
    end
  end

  //W_mat[0 +: DATA_WIDTH] = 16'h7FFF;
  //W_mat[(DATA_WIDTH*DIM) +: DATA_WIDTH] = 0;
  /*
  W_mat[(0*DATA_WIDTH*DIM) +: DATA_WIDTH] = 16'h0078; // 120
  W_mat[(1*DATA_WIDTH*DIM) +: DATA_WIDTH] = 16'h0032; // 50
  W_mat[(2*DATA_WIDTH*DIM) +: DATA_WIDTH] = 16'h0050; // 80

  Z_in[(0*DATA_WIDTH*SAMPLES) +: DATA_WIDTH] = 16'h0064; // 100
  Z_in[(1*DATA_WIDTH*SAMPLES) +: DATA_WIDTH] = 16'h0096; // 150
  Z_in[(2*DATA_WIDTH*SAMPLES) +: DATA_WIDTH] = 16'h00C8; // 200
  */

  // Dot product = 35500

  /*

  W_mat[(0*DIM)*DATA_WIDTH +: DATA_WIDTH] = 16'h000A;
  W_mat[(1*DIM)*DATA_WIDTH +: DATA_WIDTH] = 16'h0028;
  W_mat[(2*DIM)*DATA_WIDTH +: DATA_WIDTH] = 16'h0046;

  W_mat[(0*DIM + 1)*DATA_WIDTH +: DATA_WIDTH] = 16'h0014;
  W_mat[(1*DIM + 1)*DATA_WIDTH +: DATA_WIDTH] = 16'h0032;
  W_mat[(2*DIM + 1)*DATA_WIDTH +: DATA_WIDTH] = 16'h0050;

  W_mat[(0*DIM + 2)*DATA_WIDTH +: DATA_WIDTH] = 16'h001E;
  W_mat[(1*DIM + 2)*DATA_WIDTH +: DATA_WIDTH] = 16'h003C;
  W_mat[(2*DIM + 2)*DATA_WIDTH +: DATA_WIDTH] = 16'h005A;

  Z_in[(0*SAMPLES)*DATA_WIDTH +: DATA_WIDTH] = 16'h0005;
  Z_in[(1*SAMPLES)*DATA_WIDTH +: DATA_WIDTH] = 16'h0019;
  Z_in[(2*SAMPLES)*DATA_WIDTH +: DATA_WIDTH] = 16'h002D;
  
  Z_in[(0*SAMPLES + 1)*DATA_WIDTH +: DATA_WIDTH] = 16'h000A;
  Z_in[(1*SAMPLES + 1)*DATA_WIDTH +: DATA_WIDTH] = 16'h001E;
  Z_in[(2*SAMPLES + 1)*DATA_WIDTH +: DATA_WIDTH] = 16'h0032;

  Z_in[(0*SAMPLES + 2)*DATA_WIDTH +: DATA_WIDTH] = 16'h000F;
  Z_in[(1*SAMPLES + 2)*DATA_WIDTH +: DATA_WIDTH] = 16'h0023;
  Z_in[(2*SAMPLES + 2)*DATA_WIDTH +: DATA_WIDTH] = 16'h0037;

  Z_in[(0*SAMPLES + 3)*DATA_WIDTH +: DATA_WIDTH] = 16'h0014;
  Z_in[(1*SAMPLES + 3)*DATA_WIDTH +: DATA_WIDTH] = 16'h0028;
  Z_in[(2*SAMPLES + 3)*DATA_WIDTH +: DATA_WIDTH] = 16'h003C;
  */

  $readmemh("sw-test/unit/est/_wTest.mem", temp_w);
  $readmemh("sw-test/unit/est/_zTest.mem", temp_z);
  
  W_mat = temp_w[0];
  Z_in = temp_z[0];

  #20 rstn = 1;
  #20 en = 1;
  #(CLK_CYCLES)
  S_est_reversed = S_est;

  fd = $fopen("sw-test/unit/est/out/sim.raw", "w");
  $fwrite(fd, "%h", S_est_reversed);

  $display("S_est = %h", S_est_reversed);
  $finish;
end

initial begin
  $dumpfile("build/sim/icarus/dump.vcd");
  $dumpvars(0, ESTIMATION_TB);
end

endmodule

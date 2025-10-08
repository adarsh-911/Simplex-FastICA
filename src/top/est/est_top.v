module ESTIMATION_TOP #(
  parameter DATA_WIDTH = 16,
  parameter DIM = 3,
  parameter SAMPLES = 4,
  parameter FRAC_WIDTH = 20,

  parameter ANGLE_WIDTH = 16,
  parameter CORDIC_WIDTH = 22,
  parameter CORDIC_STAGES = 16
) (
  // ESTIMATION BLOCK IO
  input en,
  input rstn,
  input clk,
  input signed [0:DATA_WIDTH*DIM*SAMPLES-1] Z_IN,
  input signed [0:DATA_WIDTH*DIM*DIM-1] W_MAT,
  output est_opvld,
  output signed [0:DATA_WIDTH*DIM*SAMPLES-1] S_EST,

  // CORDIC IO
  input wire [1:0] vec_quad,
  input wire cordic_vec_opvld,
  input wire signed [DATA_WIDTH-1:0] cordic_vec_xout,
  input wire signed [ANGLE_WIDTH-1:0] vec_angle_out,

  input wire cordic_rot_opvld,
  input wire signed [DATA_WIDTH-1:0] cordic_rot_xout,
  input wire signed [DATA_WIDTH-1:0] cordic_rot_yout,
  input [CORDIC_STAGES-1:0] vec_microRot_dir, 
  input vec_microRot_out_start,

  output cordic_vec_en,
  output cordic_rot_en,

  output signed [DATA_WIDTH-1:0] cordic_vec_xin,
  output signed [DATA_WIDTH-1:0] cordic_vec_yin,
  output cordic_vec_angle_calc_en,

  output [1:0] cordic_rot_quad_in,
  output signed [DATA_WIDTH-1:0] cordic_rot_xin,
  output signed [DATA_WIDTH-1:0] cordic_rot_yin,
  output signed [ANGLE_WIDTH-1:0] cordic_rot_angle_in,
  output [CORDIC_STAGES-1:0] cordic_rot_microRot_ext_in,
  output cordic_rot_angle_microRot_n,
  output cordic_rot_microRot_ext_vld,

  output cordic_nrst
);

// Internal signals
wire start_dot_product;
wire rstn_dot;
wire dot_product_done;
wire signed [0:DATA_WIDTH*EXT_DIM-1] vector_a;
wire signed [0:DATA_WIDTH*EXT_DIM-1] vector_b;
wire signed [DATA_WIDTH-1:0] dot_product_result;

// Extended Dimension (Even)
parameter EXT_DIM = DIM + DIM[0];

ESTIMATION #(
  .DATA_WIDTH(DATA_WIDTH),
  .DIM(DIM),
  .EXT_DIM(EXT_DIM),
  .SAMPLES(SAMPLES)
) u_estimation (
  .en(en),
  .clk(clk),
  .rstn(rstn),
  .Z_in(Z_IN),
  .W_mat(W_MAT),
  .est_opvld(est_opvld),
  .S_est(S_EST),
  .start_dot_product(start_dot_product),
  .rstn_dot(rstn_dot),
  .dot_product_done(dot_product_done),
  .vector_a(vector_a),
  .vector_b(vector_b),
  .dot_product_result(dot_product_result)
);

COMPUTE_DOT_PRODUCT2D #(
  .DATA_WIDTH(DATA_WIDTH),
  .EXT_DIM(EXT_DIM),
  .ANGLE_WIDTH(ANGLE_WIDTH),
  .FRAC_WIDTH(FRAC_WIDTH),
  .CORDIC_STAGES(CORDIC_STAGES)
) u_dot_prod_dim (
  .clk(clk),
  .rstn(rstn_dot),
  .start(start_dot_product),
  .vector_a(vector_a),
  .vector_b(vector_b),
  .done(dot_product_done),
  .result(dot_product_result),

  .cordic_nrst(cordic_nrst),

  .cordic_vec_en(cordic_vec_en),
  .cordic_vec_xin(cordic_vec_xin),
  .cordic_vec_yin(cordic_vec_yin),

  .cordic_rot_en(cordic_rot_en),
  .cordic_rot_xin(cordic_rot_xin),
  .cordic_rot_yin(cordic_rot_yin),
  .cordic_rot_angle_microRot_n(cordic_rot_angle_microRot_n),
  .cordic_rot_quad_in(cordic_rot_quad_in),

  .cordic_vec_opvld(cordic_vec_opvld),
  .cordic_vec_xout(cordic_vec_xout),
  .vec_quad(vec_quad),
  .vec_angle_out(vec_angle_out),

  .cordic_rot_opvld(cordic_rot_opvld),
  .cordic_rot_xout(cordic_rot_xout),
  .cordic_rot_yout(cordic_rot_yout)
);

assign cordic_vec_angle_calc_en = 1'b0;
assign cordic_rot_angle_in = {ANGLE_WIDTH{1'b0}};
assign cordic_rot_microRot_ext_in = {CORDIC_STAGES{1'b0}};
assign cordic_rot_microRot_ext_vld = 1'b0;

endmodule
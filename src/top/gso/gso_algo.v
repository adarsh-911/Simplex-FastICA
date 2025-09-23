`timescale 1ns / 1ps
module gso_top #(
    parameter DATA_WIDTH    = 16,
    parameter ANGLE_WIDTH   = 16,
    parameter N_DIM         = 7,
    parameter CORDIC_WIDTH = 22,
    parameter CORDIC_STAGES = 16
) (
    input                                               clk,
    input                                               rst_n,
    input                                               en,
    input [2:0]                                         k_in,
    input signed [DATA_WIDTH*N_DIM-1:0]                 w_in_flat,
    input signed [ANGLE_WIDTH*(N_DIM-1)*(N_DIM-1)-1:0]  thetas_in_flat,
    
    input signed [DATA_WIDTH-1:0] cordic_rot_xout,
    input signed [DATA_WIDTH-1:0] cordic_rot_yout,
    input                         cordic_rot_opvld, 
    
    output signed [DATA_WIDTH*N_DIM-1:0] w_out_flat,
    output                               done,
    
    output reg                          cordic_rot_en,
    output reg signed [DATA_WIDTH-1:0]  cordic_rot_xin_reg, cordic_rot_yin_reg,
    output reg signed [ANGLE_WIDTH-1:0] cordic_rot_angle_in_reg,
    
    output                              cordic_rot_angle_microRot_n,
    output                              cordic_rot_microRot_ext_vld,
    output [1:0]                        cordic_rot_quad_in
);

    localparam K_VECTORS = N_DIM - 1;

    localparam [3:0] S_IDLE                  = 4'd0,
                     S_INIT                  = 4'd1,
                     S_CHECK_J_LOOP          = 4'd2,
                     S_SCALAR_PROD_EN        = 4'd3,
                     S_SCALAR_PROD_WAIT      = 4'd4,
                     S_PREP_PC               = 4'd5,
                     S_PROJ_CALC_EN          = 4'd6,
                     S_PROJ_CALC_WAIT        = 4'd7,
                     S_SUBTRACT_PROJECTION   = 4'd8,
                     S_UPDATE_J_LOOP         = 4'd9,
                     S_DONE                  = 4'd10;

    reg [3:0] current_state, next_state;
    reg signed [DATA_WIDTH-1:0]  w_current [0:N_DIM-1];
    reg signed [ANGLE_WIDTH-1:0] thetas [0:K_VECTORS-1][0:K_VECTORS-1];
    reg [2:0] k_reg;
    reg [2:0] j_loop_idx;
    reg [2:0] level_idx;
    reg signed [DATA_WIDTH-1:0] rot_x_sp [0:K_VECTORS-1];
    reg signed [DATA_WIDTH-1:0] rot_y_sp_final;
    reg signed [DATA_WIDTH-1:0] R_x_pc [0:K_VECTORS-2];
    reg signed [DATA_WIDTH-1:0] R_y_pc [0:K_VECTORS-2];
    reg signed [DATA_WIDTH-1:0] temp_sub;
    // inputs
    //wire signed [DATA_WIDTH-1:0] cordic_rot_xout, cordic_rot_yout;
    //output
    //reg cordic_rot_en;
    //reg signed [DATA_WIDTH-1:0] cordic_rot_xin_reg, cordic_rot_yin_reg;
    //reg signed [ANGLE_WIDTH-1:0] cordic_rot_angle_in_reg;
    // input
    //wire cordic_rot_opvld;
    integer i, j;
    
    assign cordic_rot_angle_microRot_n = 1'b1;
    assign cordic_rot_microRot_ext_vld = 1'b1;
    assign cordic_rot_quad_in = 2'b00;

 
   /* CORDIC_doubly_pipe_top #(
        .DATA_WIDTH(DATA_WIDTH), .CORDIC_WIDTH(CORDIC_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH), .CORDIC_STAGES(CORDIC_STAGES)
    ) CORDIC_inst (
        .clk(clk), .nreset(rst_n),
        .cordic_vec_en(1'b0), .cordic_vec_xin(0), .cordic_vec_yin(0), .cordic_vec_angle_calc_en(1'b0),
        
        .cordic_rot_en(cordic_rot_en), .cordic_rot_xin(cordic_rot_xin_reg), .cordic_rot_yin(cordic_rot_yin_reg),
        .cordic_rot_angle_microRot_n(1'b1), .cordic_rot_angle_in(cordic_rot_angle_in_reg),
        .cordic_rot_microRot_ext_in(0),
        .cordic_rot_microRot_ext_vld(1'b1), 
        .cordic_rot_quad_in(2'b00),      
         
        .cordic_vec_opvld(), .cordic_vec_xout(), .vec_quad(), .vec_angle_out(), .vec_microRot_dir(), .vec_microRot_out_start(),
        .cordic_rot_opvld(cordic_rot_opvld), .cordic_rot_xout(cordic_rot_xout), .cordic_rot_yout(cordic_rot_yout)
    ); */

    // FSM State Transition Logic
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) current_state <= S_IDLE;
        else current_state <= next_state;
    end

    // FSM Next State Logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            S_IDLE:                  if (en) next_state = S_INIT;
            S_INIT:                  next_state = S_CHECK_J_LOOP;
            S_CHECK_J_LOOP:          if ( (k_reg < 2) || (j_loop_idx >= k_reg - 1) ) next_state = S_DONE;
                                     else next_state = S_SCALAR_PROD_EN;
            S_SCALAR_PROD_EN:        next_state = S_SCALAR_PROD_WAIT;
            S_SCALAR_PROD_WAIT:      if (cordic_rot_opvld) begin
                                         if (level_idx >= N_DIM - 2) next_state = S_PREP_PC;
                                         else next_state = S_SCALAR_PROD_EN;
                                     end
            S_PREP_PC:               next_state = S_PROJ_CALC_EN;
            S_PROJ_CALC_EN:          next_state = S_PROJ_CALC_WAIT;
            S_PROJ_CALC_WAIT:        if (cordic_rot_opvld) begin
                                         if (level_idx >= N_DIM - 3) next_state = S_SUBTRACT_PROJECTION;
                                         else next_state = S_PROJ_CALC_EN;
                                     end
            S_SUBTRACT_PROJECTION:   next_state = S_UPDATE_J_LOOP;
            S_UPDATE_J_LOOP:         next_state = S_CHECK_J_LOOP;
            S_DONE:                  next_state = S_IDLE;
            default:                 next_state = S_IDLE;
        endcase
    end

    // FSM Datapath Logic
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cordic_rot_en <= 1'b0; k_reg <= 0; j_loop_idx <= 0; level_idx <= 0;
            rot_y_sp_final <= 0; temp_sub <= 0;
            for (i = 0; i < N_DIM; i = i + 1) w_current[i] <= 0;
            for (i = 0; i < K_VECTORS; i = i + 1) rot_x_sp[i] <= 0;
            for (i = 0; i < K_VECTORS-1; i = i + 1) begin R_x_pc[i] <= 0; R_y_pc[i] <= 0; end
            for (i = 0; i < K_VECTORS; i = i + 1) for (j = 0; j < K_VECTORS; j = j + 1) thetas[i][j] <= 0;
        end else begin
            cordic_rot_en <= 1'b0;

            case (current_state)
                S_INIT: begin
                    k_reg <= k_in; 
                    j_loop_idx <= 0; 
                    level_idx <= 0;
                    for (i = 0; i < N_DIM; i = i + 1) 
                            w_current[i] <= w_in_flat[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
                    for (i = 0; i < K_VECTORS; i = i + 1) 
                       for (j = 0; j < K_VECTORS; j = j + 1) 
                            thetas[i][j] <= thetas_in_flat[(i*K_VECTORS + j + 1)*ANGLE_WIDTH-1 -: ANGLE_WIDTH];
                end
                S_CHECK_J_LOOP: level_idx <= 0;
                S_SCALAR_PROD_EN: begin
                    cordic_rot_en <= 1'b1;
                    if (level_idx == 0) begin
                        cordic_rot_xin_reg <= w_current[0];
                        cordic_rot_yin_reg <= w_current[1];
                    end else begin
                        cordic_rot_xin_reg <= w_current[level_idx + 1];
                        cordic_rot_yin_reg <= rot_x_sp[level_idx - 1];
                    end
                    cordic_rot_angle_in_reg <= (level_idx == N_DIM - 2) ? (thetas[j_loop_idx][level_idx] << 1) : thetas[j_loop_idx][level_idx];
                end
                S_SCALAR_PROD_WAIT: begin
                    if (cordic_rot_opvld) begin
                        rot_x_sp[level_idx] <= cordic_rot_xout;
                        if (level_idx == N_DIM - 2) rot_y_sp_final <= cordic_rot_yout;
                        if (level_idx < N_DIM - 2) level_idx <= level_idx + 1;
                        else level_idx <= 0;
                    end
                end
                S_PREP_PC: begin
                    temp_sub <= rot_x_sp[N_DIM - 3] - rot_y_sp_final;
                end
                S_PROJ_CALC_EN: begin
                    cordic_rot_en <= 1'b1;
                    cordic_rot_xin_reg <= 0;
                    if (level_idx == 0) begin
                        cordic_rot_yin_reg <= temp_sub;
                    end else begin
                        cordic_rot_yin_reg <= R_x_pc[level_idx - 1];
                    end
                    cordic_rot_angle_in_reg <= thetas[j_loop_idx][N_DIM - 3 - level_idx];
                end
                S_PROJ_CALC_WAIT: begin
                    if (cordic_rot_opvld) begin
                        R_x_pc[level_idx] <= cordic_rot_xout;
                        R_y_pc[level_idx] <= cordic_rot_yout;
                        if (level_idx < N_DIM - 3) level_idx <= level_idx + 1;
                    end
                end
                S_SUBTRACT_PROJECTION: begin
                    for (i = 0; i < N_DIM; i = i + 1) begin
                        if (i == 0)      w_current[i] <= w_current[i] - (R_y_pc[N_DIM - 3] >>> 1);
                        else if (i == 1) w_current[i] <= w_current[i] - (R_x_pc[N_DIM - 3] >>> 1);
                        else if (i < N_DIM - 1) w_current[i] <= w_current[i] - (R_y_pc[N_DIM - i - 2] >>> 1);
                        else             w_current[i] <= (w_current[i] - rot_x_sp[N_DIM - 2]) >>> 1;
                    end
                end
                S_UPDATE_J_LOOP: j_loop_idx <= j_loop_idx + 1;
            endcase
        end
    end

    // Output Logic
    assign done = (current_state == S_DONE);
    genvar k;
    generate
        for (k = 0; k < N_DIM; k = k + 1) begin : pack_output
            assign w_out_flat[(k+1)*DATA_WIDTH-1 -: DATA_WIDTH] = w_current[k];
        end
    endgenerate

endmodule

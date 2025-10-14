`timescale 1ns / 1ps

module norm_5d #(
    parameter DIMENSIONS = 5,
    parameter DATA_WIDTH = 32,
    parameter CORDIC_WIDTH = 38,
    parameter CORDIC_STAGES = 32,
    parameter ANGLE_WIDTH = 32,
    parameter FRAC_WIDTH = 20
)(
    input clk,
    input nreset,
    input [DIMENSIONS*DATA_WIDTH-1:0] w_in,
    input start,
    output reg [DIMENSIONS*DATA_WIDTH-1:0] W_out,
    output done,
    
    output reg ica_cordic_vec_en,
    output reg signed [DATA_WIDTH-1:0] ica_cordic_vec_xin,
    output reg signed [DATA_WIDTH-1:0] ica_cordic_vec_yin,
    output reg ica_cordic_vec_angle_calc_en,                      // Enable total angle calculation from the micro-angles
    
    output reg ica_cordic_rot1_en,
    output reg signed [DATA_WIDTH-1:0] ica_cordic_rot1_xin,
    output reg signed [DATA_WIDTH-1:0] ica_cordic_rot1_yin,       // low = micro rotations are given , high = rotation angle given directly
    output reg [CORDIC_STAGES-1:0] ica_cordic_rot1_microRot_in,   // External micro rotation input for CORDIC-1 Rotation
    output reg ica_cordic_rot1_microRot_ext_vld,                  // If HIGH => Micro-rotations are given from outside; LOW => Directly from Vectoring (Need to be assigned properly in testbench)
    output reg [1:0] ica_cordic_rot1_quad_in,                  
    output reg ica_cordic_rot1_angle_microRot_n,

    output reg cordic_nrst,

    input cordic_vec_opvld,
    input signed [DATA_WIDTH-1:0] cordic_vec_xout,
    input [CORDIC_STAGES-1:0] cordic_vec_microRot_out,
    input [1:0] cordic_vec_quad_out,
    input cordic_vec_microRot_out_start,
    input signed [ANGLE_WIDTH-1:0] cordic_vec_angle_out,
    
    input cordic_rot1_opvld,                                         
    input signed [DATA_WIDTH-1:0] cordic_rot1_xout,                 
    input signed [DATA_WIDTH-1:0] cordic_rot1_yout                  
);

    reg signed [DATA_WIDTH-1:0] temp_ica_cordic_vec_xin;
    reg signed [DATA_WIDTH-1:0] temp_ica_cordic_vec_yin;
    reg                     temp_ica_cordic_vec_angle_calc_en;

    reg signed [DATA_WIDTH-1:0] temp_ica_cordic_rot1_xin;
    reg signed [DATA_WIDTH-1:0] temp_ica_cordic_rot1_yin;
    reg signed [ANGLE_WIDTH-1:0] temp_ica_cordic_rot1_angle_in;
    reg                     temp_ica_cordic_rot1_angle_microRot_n;
    reg [CORDIC_STAGES-1:0] temp_ica_cordic_rot1_microRot_in;
    reg [1:0]               temp_ica_cordic_rot1_quad_in;
    reg                     temp_ica_cordic_vec_en; 
    reg                     temp_ica_cordic_rot1_en;
    reg temp_ica_cordic_rot1_microRot_ext_vld;
    

    wire signed [DATA_WIDTH-1:0] w1, w2, w3, w4, w5;
    assign w1 = w_in[DATA_WIDTH-1:0];
    assign w2 = w_in[2*DATA_WIDTH-1:DATA_WIDTH];
    assign w3 = w_in[3*DATA_WIDTH-1:2*DATA_WIDTH];
    assign w4 = w_in[4*DATA_WIDTH-1:3*DATA_WIDTH];
    assign w5 = w_in[5*DATA_WIDTH-1:4*DATA_WIDTH];

    // Storage registers
    reg [CORDIC_STAGES-1:0] theta_1, theta_2, theta_3, theta_4;
    reg [1:0] quad_1, quad_2, quad_3, quad_4;
    reg [DATA_WIDTH-1:0] vec_x1_to_y2_ff;
    reg [DATA_WIDTH-1:0] vec_x2_to_y3_ff;
    reg [DATA_WIDTH-1:0] vec_x3_to_y4_ff;
    reg [DATA_WIDTH-1:0] rot_x1_to_y2_fb;
    reg [DATA_WIDTH-1:0] rot_x2_to_y3_fb;
    reg [DATA_WIDTH-1:0] rot_x3_to_y4_fb;

    wire [DATA_WIDTH-1:0] x_zero = {DATA_WIDTH{1'b0}};          
    wire [DATA_WIDTH-1:0] y_one = 32'h00100000;                 // 1.0 in Q11.20 format

    reg [3:0] current_state, next_state;
    localparam IDLE = 4'd0, 
               VEC_1 = 4'd1,
               VEC_2 = 4'd2,
               VEC_3 = 4'd3,
               VEC_4 = 4'd4,
               ROT_1 = 4'd5,
               ROT_2 = 4'd6,
               ROT_3 = 4'd7,
               ROT_4 = 4'd8,
               DONE = 4'd9;

    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            theta_1 <= {CORDIC_STAGES{1'b0}};
            theta_2 <= {CORDIC_STAGES{1'b0}};
            theta_3 <= {CORDIC_STAGES{1'b0}};
            theta_4 <= {CORDIC_STAGES{1'b0}};
            quad_1 <= 2'b00;
            quad_2 <= 2'b00;
            quad_3 <= 2'b00;
            quad_4 <= 2'b00;
            vec_x1_to_y2_ff <= {DATA_WIDTH{1'b0}};
            vec_x2_to_y3_ff <= {DATA_WIDTH{1'b0}};
            vec_x3_to_y4_ff <= {DATA_WIDTH{1'b0}};
            rot_x1_to_y2_fb <= {DATA_WIDTH{1'b0}};
            rot_x2_to_y3_fb <= {DATA_WIDTH{1'b0}};
            rot_x3_to_y4_fb <= {DATA_WIDTH{1'b0}};
        end else if (cordic_vec_opvld) begin
            case(current_state)
                VEC_1: begin
                    theta_1 <= cordic_vec_microRot_out;
                    quad_1 <= cordic_vec_quad_out;
                    vec_x1_to_y2_ff <= cordic_vec_xout;
                    cordic_nrst <= 0;
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b0;  
                end
                VEC_2: begin
                    theta_2 <= cordic_vec_microRot_out;
                    quad_2 <= cordic_vec_quad_out;
                    vec_x2_to_y3_ff <= cordic_vec_xout;
                    cordic_nrst <= 0;
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b0;
                end
                VEC_3: begin
                    theta_3 <= cordic_vec_microRot_out;
                    quad_3 <= cordic_vec_quad_out;
                    vec_x3_to_y4_ff <= cordic_vec_xout;
                    cordic_nrst <= 0;
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b0;
                end
                VEC_4: begin
                    theta_4 <= cordic_vec_microRot_out;
                    quad_4 <= cordic_vec_quad_out;
                    cordic_nrst <= 0;
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b0;
                end
            endcase
        end else if (cordic_rot1_opvld) begin
            case(current_state)
                ROT_1: begin
                    rot_x1_to_y2_fb <= cordic_rot1_xout;
                    cordic_nrst <= 0;
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b0;
                end
                ROT_2: begin
                    rot_x2_to_y3_fb <= cordic_rot1_xout;
                    cordic_nrst <= 0;
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b0;
                end
                ROT_3: begin
                    rot_x3_to_y4_fb <= cordic_rot1_xout;                     
                    cordic_nrst <= 0;
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b0;          
                end
            endcase
        end
    end

    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            W_out <= {(DIMENSIONS*DATA_WIDTH){1'b0}};
        // CHANGE 2: Added a specific condition to handle the zero-input bypass.
        // This sets the output to zero when we are in IDLE, receive a start signal,
        // and the input vector is all zeros.
        end else if (current_state == IDLE && start && ~|w_in) begin
            W_out <= { (DIMENSIONS*DATA_WIDTH){1'b0} };
        end else if (cordic_rot1_opvld) begin
            case(current_state)
                ROT_1: begin
                    W_out[5*DATA_WIDTH-1:4*DATA_WIDTH] <= cordic_rot1_yout;
                end
                ROT_2: begin
                    W_out[4*DATA_WIDTH-1:3*DATA_WIDTH] <= cordic_rot1_yout;
                end
                ROT_3: begin
                    W_out[3*DATA_WIDTH-1:2*DATA_WIDTH] <= cordic_rot1_yout;
                end
                ROT_4: begin
                    W_out[DATA_WIDTH-1:0] <= cordic_rot1_yout;                     
                    W_out[2*DATA_WIDTH-1:DATA_WIDTH] <= cordic_rot1_xout;          
                end
            endcase
        end
    end

    always @(*) begin
        case (current_state)
            // CHANGE 1: Modified the IDLE state logic. Removed the CHECK state.
            // On a 'start' signal, it now checks the input vector 'w_in'.
            // If any bit in 'w_in' is 1 (|w_in is true), it proceeds to VEC_1.
            // If 'w_in' is all zeros, it jumps directly to the DONE state.
            IDLE: begin
                if (start) begin
                    if (|w_in) // Check if any bit is non-zero
                        next_state = VEC_1;
                    else
                        next_state = DONE; // All zeros, so bypass CORDIC
                end else begin
                    next_state = IDLE;
                end
            end
            VEC_1: next_state = (cordic_vec_opvld) ? VEC_2 : VEC_1;
            VEC_2: next_state = (cordic_vec_opvld) ? VEC_3 : VEC_2;
            VEC_3: next_state = (cordic_vec_opvld) ? VEC_4 : VEC_3;
            VEC_4: next_state = (cordic_vec_opvld) ? ROT_1 : VEC_4; // Corrected brace from {} to ()
            ROT_1: next_state = (cordic_rot1_opvld) ? ROT_2 : ROT_1;
            ROT_2: next_state = (cordic_rot1_opvld) ? ROT_3 : ROT_2;
            ROT_3: next_state = (cordic_rot1_opvld) ? ROT_4 : ROT_3;
            ROT_4: next_state = (cordic_rot1_opvld) ? DONE : ROT_4; // Corrected brace from {} to ()
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            current_state <= IDLE;
            temp_ica_cordic_rot1_angle_microRot_n <= 1'b0;
            temp_ica_cordic_rot1_microRot_ext_vld <= 1'b1;             // Should be HIGH for external micro-rotations
            temp_ica_cordic_vec_en <= 1'b0;
            temp_ica_cordic_rot1_en <= 1'b0;                                   
            temp_ica_cordic_vec_xin <= {DATA_WIDTH{1'b0}};
            temp_ica_cordic_vec_yin <= {DATA_WIDTH{1'b0}};
            temp_ica_cordic_vec_angle_calc_en <= 1'b0;                 // high to enable total angle calculation from the micro-angles
            temp_ica_cordic_rot1_xin <= {DATA_WIDTH{1'b0}};                     
            temp_ica_cordic_rot1_yin <= {DATA_WIDTH{1'b0}};                     
            temp_ica_cordic_rot1_microRot_in <= {CORDIC_STAGES{1'b0}};          
            temp_ica_cordic_rot1_quad_in <= 2'b00;
            cordic_nrst <= 0;                         
        end else begin
            current_state <= next_state;
            
            case (next_state)
                IDLE: begin
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b0;
                    cordic_nrst <= 0;                        
                end
                VEC_1: begin
                    temp_ica_cordic_vec_en <= 1'b1;
                    temp_ica_cordic_rot1_en <= 1'b0;                           
                    temp_ica_cordic_vec_xin <= w1;
                    temp_ica_cordic_vec_yin <= w2;
                    temp_ica_cordic_vec_angle_calc_en <= 1'b0;                 // We only need microrotations
                    cordic_nrst <= 1;
                end
                VEC_2: begin
                    temp_ica_cordic_vec_en <= 1'b1;
                    temp_ica_cordic_rot1_en <= 1'b0;                           
                    temp_ica_cordic_vec_xin <= w3;
                    temp_ica_cordic_vec_yin <= vec_x1_to_y2_ff;                 // Feed forward from previous vectoring
                    temp_ica_cordic_vec_angle_calc_en <= 1'b0;                  // We only need microrotations
                    cordic_nrst <= 1;
                end
                VEC_3: begin
                    temp_ica_cordic_vec_en <= 1'b1;
                    temp_ica_cordic_rot1_en <= 1'b0;                           
                    temp_ica_cordic_vec_xin <= w4;
                    temp_ica_cordic_vec_yin <= vec_x2_to_y3_ff;                 // Feed forward from previous vectoring
                    temp_ica_cordic_vec_angle_calc_en <= 1'b0;                  // We only need microrotations
                    cordic_nrst <= 1;
                end
                VEC_4: begin
                    temp_ica_cordic_vec_en <= 1'b1;
                    temp_ica_cordic_rot1_en <= 1'b0;
                    temp_ica_cordic_vec_xin <= w5;
                    temp_ica_cordic_vec_yin <= vec_x3_to_y4_ff;
                    temp_ica_cordic_vec_angle_calc_en <= 1'b0;
                    cordic_nrst <= 1;
                end
                ROT_1: begin
                    cordic_nrst <= 1;
                    temp_ica_cordic_rot1_angle_microRot_n <= 1'b0;     // Use micro-rotations
                    temp_ica_cordic_rot1_microRot_ext_vld <= 1'b1;     // External micro-rotations   
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b1;                           
                    temp_ica_cordic_rot1_xin <= x_zero;                         
                    temp_ica_cordic_rot1_yin <= y_one;                          
                    temp_ica_cordic_rot1_microRot_in <= theta_4;                
                    temp_ica_cordic_rot1_quad_in  <= quad_4;                   
                end
                ROT_2: begin
                    cordic_nrst <= 1;
                    temp_ica_cordic_rot1_angle_microRot_n <= 1'b0;     // Use micro-rotations
                    temp_ica_cordic_rot1_microRot_ext_vld <= 1'b1;     // External micro-rotations   
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b1;                           
                    temp_ica_cordic_rot1_xin <= x_zero;                         
                    temp_ica_cordic_rot1_yin <= rot_x1_to_y2_fb;  // Feedback from previous rotation
                    temp_ica_cordic_rot1_microRot_in <= theta_3;                
                    temp_ica_cordic_rot1_quad_in  <= quad_3;                   
                end
                ROT_3: begin
                    cordic_nrst <= 1;
                    temp_ica_cordic_rot1_angle_microRot_n <= 1'b0;     // Use micro-rotations
                    temp_ica_cordic_rot1_microRot_ext_vld <= 1'b1;     // External micro-rotations   
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b1;                           
                    temp_ica_cordic_rot1_xin <= x_zero;                         
                    temp_ica_cordic_rot1_yin <= rot_x2_to_y3_fb;  // Feedback from previous rotation
                    temp_ica_cordic_rot1_microRot_in <= theta_2;                
                    temp_ica_cordic_rot1_quad_in  <= quad_2;                   
                end
                ROT_4: begin
                    cordic_nrst <= 1;
                    temp_ica_cordic_rot1_angle_microRot_n <= 1'b0;
                    temp_ica_cordic_rot1_microRot_ext_vld <= 1'b1;     // External micro-rotations   
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b1;                           
                    temp_ica_cordic_rot1_xin <= x_zero;                         
                    temp_ica_cordic_rot1_yin <= rot_x3_to_y4_fb;  // Feedback from previous rotation
                    temp_ica_cordic_rot1_microRot_in <= theta_1;                
                    temp_ica_cordic_rot1_quad_in  <= quad_1;                   
                end
                DONE: begin
                    temp_ica_cordic_vec_en <= 1'b0;
                    temp_ica_cordic_rot1_en <= 1'b0;                      
                end
            endcase
        end

        ica_cordic_vec_xin <= temp_ica_cordic_vec_xin;
        ica_cordic_vec_yin <= temp_ica_cordic_vec_yin;
        ica_cordic_vec_angle_calc_en <= temp_ica_cordic_vec_angle_calc_en;
        ica_cordic_rot1_xin <= temp_ica_cordic_rot1_xin;
        ica_cordic_rot1_yin <= temp_ica_cordic_rot1_yin;
        //ica_cordic_rot1_angle_in <= temp_ica_cordic_rot1_angle_in;
        ica_cordic_rot1_angle_microRot_n <= temp_ica_cordic_rot1_angle_microRot_n;
        ica_cordic_rot1_microRot_in <= temp_ica_cordic_rot1_microRot_in;
        ica_cordic_rot1_quad_in <= temp_ica_cordic_rot1_quad_in;
        ica_cordic_vec_en <= temp_ica_cordic_vec_en;
        ica_cordic_rot1_en <= temp_ica_cordic_rot1_en;
        ica_cordic_rot1_microRot_ext_vld <= temp_ica_cordic_rot1_microRot_ext_vld;
    end

    assign done = (current_state == DONE);
    

endmodule
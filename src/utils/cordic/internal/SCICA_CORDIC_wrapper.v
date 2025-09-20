`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.02.2017 21:22:29
// Design Name: 
// Module Name: SCICA_CORDIC_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module SCICA_CORDIC_wrapper #(
        parameter DATA_WIDTH = 16,
        parameter CORDIC_WIDTH = 22,
        parameter ANGLE_WIDTH = 16,
        parameter CORDIC_STAGES = 16
    ) (
        input clk,
        input nreset,
        input [1:0] scica_stage_in,                                                 // 00 - EVD, 01 - ICA, 10 - FFT, 11 - k-Means
        // EVD Vectoring Inputs
        input evd_cordic_vec_en,                                                    // CVM Enable
        input signed [DATA_WIDTH-1:0] evd_cordic_vec_xin,           // CVM X-input
        input signed [DATA_WIDTH-1:0] evd_cordic_vec_yin,           // CVM Y-input
        input evd_cordic_vec_angle_calc_en,                                 // Set this HIGH to Enable angle calculation
        // EVD Rotation Inputs
        input evd_cordic_rot1_en,                                                  // CRM1 Enable  
        input signed [DATA_WIDTH-1:0] evd_cordic_rot1_xin,          // CRM1 X-input
        input signed [DATA_WIDTH-1:0] evd_cordic_rot1_yin,          // CRM1 Y-input
        input evd_cordic_rot1_angle_microRot_n,                           // Set this HIGH when angle is directly given; LOW when it is in the form of microRotations      
        input signed [ANGLE_WIDTH-1:0] evd_cordic_rot1_angle_in, // CRM1 angle input (direct angle)
        input evd_cordic_rot2_en,                                                   // CRM2 Enable
        input signed [DATA_WIDTH-1:0] evd_cordic_rot2_xin,          // CRM2 X-input
        input signed [DATA_WIDTH-1:0] evd_cordic_rot2_yin,          // CRM2 Y-input
        input evd_cordic_rot2_angle_microRot_n,                           // Set this HIGH when angle is directly given; LOW when it is in the form of microRotations  

        // ICA Vectoring Inputs
        input ica_cordic_vec_en,
        input signed [DATA_WIDTH-1:0] ica_cordic_vec_xin,
        input signed [DATA_WIDTH-1:0] ica_cordic_vec_yin,
        input ica_cordic_vec_angle_calc_en,                
        // ICA Rotation Inputs
        input ica_cordic_rot1_en,
        input signed [DATA_WIDTH-1:0] ica_cordic_rot1_xin,
        input signed [DATA_WIDTH-1:0] ica_cordic_rot1_yin,
        input signed [ANGLE_WIDTH-1:0] ica_cordic_rot1_angle_in,
        input ica_cordic_rot1_angle_microRot_n,
        input [CORDIC_STAGES-1:0] ica_cordic_rot1_microRot_ext_in,              // External micro rotation input for CORDIC-1 Rotation
        input ica_cordic_rot1_microRot_ext_vld,
        input [1:0] ica_cordic_rot1_quad_in,
        input ica_cordic_rot2_en,
        input signed [DATA_WIDTH-1:0] ica_cordic_rot2_xin,
        input signed [DATA_WIDTH-1:0] ica_cordic_rot2_yin,
        input [1:0] ica_cordic_rot2_quad_in,
        input [CORDIC_STAGES-1:0] ica_cordic_rot2_microRot_in,
        
        // FFT Rotation Inputs
        input fft_cordic_rot_en,
        input signed [DATA_WIDTH-1:0] fft_cordic_rot_xin,
        input signed [DATA_WIDTH-1:0] fft_cordic_rot_yin,
        input signed [ANGLE_WIDTH-1:0] fft_cordic_rot_angle_in,
        
        // K-Means Vectoring Inputs
        input kmeans_cordic_vec_en,
        input signed [DATA_WIDTH-1:0] kmeans_cordic_vec_xin,
        input signed [DATA_WIDTH-1:0] kmeans_cordic_vec_yin,
        
        // CORDIC Vectoring outputs
        output cordic_vec_opvld,                                                // CVM Output valid
        output signed [DATA_WIDTH-1:0] cordic_vec_xout,         // CVM X-output    
        output [CORDIC_STAGES-1:0] cordic_vec_microRot_out, // CVM microRotations output
        output [1:0] cordic_vec_quad_out,                                // CVM quadrant output    
        output cordic_vec_microRot_out_start,                           // HIGH when the first microRotation for a particular input is ready
        output signed [ANGLE_WIDTH-1:0] cordic_vec_angle_out,   // CVM angle output (total angle after summing the microRotations
        //CORDIC Rotation Outputs           
        output cordic_rot1_opvld,                                               // CRM 1 output valid
        output signed [DATA_WIDTH-1:0] cordic_rot1_xout,        // CRM1 x-output
        output signed [DATA_WIDTH-1:0] cordic_rot1_yout,        // CRM1 y-output
        output cordic_rot2_opvld,                                               // CRM 2 output valid
        output signed [DATA_WIDTH-1:0] cordic_rot2_xout,        // CRM2 x-output    
        output signed [DATA_WIDTH-1:0] cordic_rot2_yout         // CRM2 y-output       
    );
       
    reg cordic_vec_en;
    reg signed [DATA_WIDTH-1:0] cordic_vec_xin;
    reg signed [DATA_WIDTH-1:0] cordic_vec_yin;
    reg cordic_vec_angle_calc_en;
    
    reg cordic_rot1_en;
    reg signed [DATA_WIDTH-1:0] cordic_rot1_xin;
    reg signed [DATA_WIDTH-1:0] cordic_rot1_yin;
    reg cordic_rot1_angle_microRot_n;
    reg signed [ANGLE_WIDTH-1:0] cordic_rot1_angle_in;
    reg cordic_rot1_microRot_ext_vld;    
    reg [CORDIC_STAGES-1:0] cordic_rot1_microRot_ext_in;
    reg [1:0] cordic_rot1_quad_in;
    
    reg cordic_rot2_en;                
    reg signed [DATA_WIDTH-1:0] cordic_rot2_xin;
    reg signed [DATA_WIDTH-1:0] cordic_rot2_yin;
    reg cordic_rot2_angle_microRot_n;
    reg signed [ANGLE_WIDTH-1:0] cordic_rot2_angle_in;
    reg [CORDIC_STAGES-1:0] cordic_rot2_microRot_in;
    reg [1:0] cordic_rot2_quad_in;
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            cordic_rot1_en <= 1'b0;
            cordic_rot2_en <= 1'b0;
            cordic_vec_en <= 1'b0;
        end                
        
        else begin
            cordic_rot1_en <= evd_cordic_rot1_en || ica_cordic_rot1_en || fft_cordic_rot_en;
            cordic_vec_en <= evd_cordic_vec_en || ica_cordic_vec_en || kmeans_cordic_vec_en;
            cordic_rot2_en <= evd_cordic_rot2_en || ica_cordic_rot2_en;
        end
    end                                            
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            cordic_vec_xin <= {DATA_WIDTH{1'b0}};
            cordic_vec_yin <= {DATA_WIDTH{1'b0}};
            cordic_vec_angle_calc_en <= 1'b0;
        end
        
        else if (evd_cordic_vec_en || 
                    ica_cordic_vec_en || 
                    kmeans_cordic_vec_en) begin
            case (scica_stage_in)
                2'b00:                          // EVD
                    begin
                        cordic_vec_xin <= evd_cordic_vec_xin;                       
                        cordic_vec_yin <= evd_cordic_vec_yin;                       
                        cordic_vec_angle_calc_en <= evd_cordic_vec_angle_calc_en;
                    end

                2'b01:                          // ICA
                    begin
                        cordic_vec_xin <= ica_cordic_vec_xin;                       
                        cordic_vec_yin <= ica_cordic_vec_yin;                       
                        cordic_vec_angle_calc_en <= ica_cordic_vec_angle_calc_en;
                    end

                2'b11:                          // K-Means
                    begin
                        cordic_vec_xin <= kmeans_cordic_vec_xin;                       
                        cordic_vec_yin <= kmeans_cordic_vec_yin;                       
                        cordic_vec_angle_calc_en <= 1'b0;
                    end
                
                default:
                    begin
                        cordic_vec_xin <= cordic_vec_xin;                       
                        cordic_vec_yin <= cordic_vec_yin;                       
                        cordic_vec_angle_calc_en <= 1'b0;
                    end                
            endcase
        end
    end    

    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            cordic_rot1_xin <= {DATA_WIDTH{1'b0}};
            cordic_rot1_yin <= {DATA_WIDTH{1'b0}};
            cordic_rot1_angle_microRot_n <= 1'b0;
            cordic_rot1_angle_in <= {ANGLE_WIDTH{1'b0}};
            cordic_rot1_microRot_ext_vld <= 1'b0;
            cordic_rot1_microRot_ext_in <= {CORDIC_STAGES{1'b0}};
            cordic_rot1_quad_in <= 2'b00;
        end
        
        else begin
            case (scica_stage_in)
                2'b00: 
                    begin
                        if (evd_cordic_rot1_en) begin
                            cordic_rot1_xin <= evd_cordic_rot1_xin;                       
                            cordic_rot1_yin <= evd_cordic_rot1_yin;                       
                            cordic_rot1_angle_microRot_n <= evd_cordic_rot1_angle_microRot_n;
                            cordic_rot1_angle_in <= evd_cordic_rot1_angle_in;
                        end
                    end
                    
                2'b01: 
                    begin
                        cordic_rot1_microRot_ext_vld <= ica_cordic_rot1_microRot_ext_vld;

                        if (ica_cordic_rot1_en) begin 
                            cordic_rot1_xin <= ica_cordic_rot1_xin;                       
                            cordic_rot1_yin <= ica_cordic_rot1_yin;                       
                            cordic_rot1_angle_microRot_n <= ica_cordic_rot1_angle_microRot_n;
                            cordic_rot1_angle_in <= ica_cordic_rot1_angle_in;
                            cordic_rot1_microRot_ext_in = ica_cordic_rot1_microRot_ext_in;
                            cordic_rot1_quad_in <= ica_cordic_rot1_quad_in;
                        end
                    end
                    
                2'b10: 
                    begin
                        if (fft_cordic_rot_en) begin
                            cordic_rot1_xin <= fft_cordic_rot_xin;                       
                            cordic_rot1_yin <= fft_cordic_rot_yin;                       
                            cordic_rot1_angle_microRot_n <= 1'b0;
                            cordic_rot1_angle_in <= fft_cordic_rot_angle_in;
                            cordic_rot1_microRot_ext_vld <= 1'b0;
                        end
                    end
                    
                default:
                    begin
                        cordic_rot1_xin <= cordic_rot1_xin;                       
                        cordic_rot1_yin <= cordic_rot1_yin;                       
                        cordic_rot1_angle_microRot_n <= 1'b0;
                        cordic_rot1_angle_in <= cordic_rot1_angle_in;
                        cordic_rot1_microRot_ext_vld <= 1'b0;
                        cordic_rot1_microRot_ext_in = cordic_rot1_microRot_ext_in;  
                    end                    
            endcase
        end
    end                     
                                    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            cordic_rot2_xin <= {DATA_WIDTH{1'b0}};
            cordic_rot2_yin <= {DATA_WIDTH{1'b0}};
            cordic_rot2_angle_microRot_n <= 1'b0;
            cordic_rot2_angle_in <= {ANGLE_WIDTH{1'b0}};
            cordic_rot2_quad_in <= 2'b00;
            cordic_rot2_microRot_in <= {CORDIC_STAGES{1'b0}};
        end
        
        else if (evd_cordic_rot2_en || ica_cordic_rot2_en) begin
            case (scica_stage_in)
                2'b00: 
                    begin
                        cordic_rot2_xin <= evd_cordic_rot2_xin;                       
                        cordic_rot2_yin <= evd_cordic_rot2_yin;                       
                        cordic_rot2_angle_microRot_n <= evd_cordic_rot2_angle_microRot_n;
                        cordic_rot2_angle_in <= evd_cordic_rot1_angle_in;
                    end

                2'b01: 
                    begin
                        cordic_rot2_xin <= ica_cordic_rot2_xin;                       
                        cordic_rot2_yin <= ica_cordic_rot2_yin;                       
                        cordic_rot2_angle_microRot_n <= 1'b0;
                        cordic_rot2_microRot_in <= ica_cordic_rot2_microRot_in;
                        cordic_rot2_quad_in <= ica_cordic_rot2_quad_in;
                    end

                default:
                    begin
                        cordic_rot2_xin <= cordic_rot2_xin;                       
                        cordic_rot2_yin <= cordic_rot2_yin;                       
                        cordic_rot2_angle_microRot_n <= 1'b0;
                        cordic_rot2_angle_in <= cordic_rot2_angle_in;
                        cordic_rot2_microRot_in <= cordic_rot2_microRot_in;
                        cordic_rot2_quad_in <= cordic_rot2_quad_in;
                    end                    
            endcase
        end
    end                     

    CORDIC_doubly_pipe_top #(
        .DATA_WIDTH (DATA_WIDTH),
        .CORDIC_WIDTH (CORDIC_WIDTH),
        .ANGLE_WIDTH (ANGLE_WIDTH),
        .CORDIC_STAGES (CORDIC_STAGES)
    ) CORDIC1 (
        .clk (clk),
        .nreset (nreset),
        // Vectoring Inputs
        .cordic_vec_en (cordic_vec_en),
        .cordic_vec_xin (cordic_vec_xin),
        .cordic_vec_yin (cordic_vec_yin),
        .cordic_vec_angle_calc_en (cordic_vec_angle_calc_en),            // Enable total angle calculation from the micro-angles
        // Rotation Inputs
        .cordic_rot_en (cordic_rot1_en),
        .cordic_rot_xin (cordic_rot1_xin),
        .cordic_rot_yin (cordic_rot1_yin),
        .cordic_rot_angle_microRot_n (cordic_rot1_angle_microRot_n),   // HIGH => Rotation Angle is given directly; LOW => Angle given as micro-rotations
        .cordic_rot_angle_in (cordic_rot1_angle_in),     
        .cordic_rot_microRot_ext_in (cordic_rot1_microRot_ext_in),
        .cordic_rot_microRot_ext_vld (cordic_rot1_microRot_ext_vld),
        .cordic_rot_quad_in (cordic_rot1_quad_in),
         // Vectoring Outputs
        .cordic_vec_opvld (cordic_vec_opvld),
        .cordic_vec_xout (cordic_vec_xout),
        .vec_quad (cordic_vec_quad_out),
        .vec_angle_out (cordic_vec_angle_out),
        .vec_microRot_dir (cordic_vec_microRot_out), 
        .vec_microRot_out_start (cordic_vec_microRot_out_start),
        // Rotation Outputs
        .cordic_rot_opvld (cordic_rot1_opvld),
        .cordic_rot_xout (cordic_rot1_xout),
        .cordic_rot_yout (cordic_rot1_yout)
    ); 

    CORDIC_Rotation_top #(
        .DATA_WIDTH (DATA_WIDTH),
        .CORDIC_WIDTH (CORDIC_WIDTH),
        .ANGLE_WIDTH (ANGLE_WIDTH),
        .CORDIC_STAGES (CORDIC_STAGES)
    ) CORDIC2_Rotation_Mode(
        .clk (clk),
        .nreset (nreset),
        .enable_in (cordic_rot2_en),
        .angle_microRot_n (cordic_rot2_angle_microRot_n),                     // HIGH when angle is directly given; LOW when Micro-rotation is given from Vectoring
        .x_in (cordic_rot2_xin),
        .y_in (cordic_rot2_yin),
        .angle_in (cordic_rot2_angle_in),
        .microRot_dir_in (cordic_rot2_microRot_in),
        .quad_in (cordic_rot2_quad_in),
        .x_out (cordic_rot2_xout),
        .y_out (cordic_rot2_yout),
        .output_valid_o (cordic_rot2_opvld)
    );
    
endmodule

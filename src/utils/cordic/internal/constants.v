`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/25/2016 03:29:58 PM
// Design Name: 
// Module Name: constants
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

`define DATA_WIDTH 32           // width of input and output data

`define CORDIC_WIDTH 38         // width of data after upscaling inside the CORDIC module 
`define CORDIC_STAGES 16        // Number of CORDIC Micro-Rotation Stages    
`define ANGLE_WIDTH 16          // Angle Width of CORDIC; used when Angle is directly given to Rotation Mode.

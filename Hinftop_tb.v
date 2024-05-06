`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2024 11:45:33 AM
// Design Name: 
// Module Name: Hinftop_tb
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


module Hinftop_tb();

  // Parameters
  parameter CLK_PERIOD = 12; // Clock period in ns
  parameter DATA_PERIOD = 10000; // Data period for sending 8 elements in 8 clock cycles

  // Inputs
  reg clk = 0;
  reg rst_n = 0;
  reg Start = 0;
  reg Tx_Full = 0;
  reg Rx_Empty = 0;
  reg game = 1;
  // Read and send data
  integer input_file;
  integer output_file;
  integer col_index;
  reg [63:0] D[7:0];
  integer counter = 0;
  integer i;
  // Outputs
  wire D_Wr, D_Rd;
  wire signed [63:0] D_out;
  reg signed [63:0] Xin;
  wire Done;
  
  integer row_index;
  // Instantiate the Hinftop module
  Hinftop uut (
    .clk(clk),
    .rst_n(rst_n),
    .Start(Start),
    .Xin(Xin),
    .Tx_Full(Tx_Full),
    .Rx_Empty(Rx_Empty),
    .D_Rd(D_Rd),
    .D_Wr(D_Wr),
    .D_out(D_out),
    .Done(Done)
  );

  // Clock generation
  always #((CLK_PERIOD / 2)) clk = ~clk;

  // Testbench logic
  initial begin
    // Open input CSV file
    input_file = $fopen("C:\\04_30_2024\\Hinf_Filter_Module_1p0_1_28_35_final\\EEG_data_HPF_input_64_bit_fixed.csv", "r");

    // Reset sequence
    rst_n = 0;
    Start = 0;
    Rx_Empty = 0;
    Xin = 0;
    #20;
    rst_n = 1;
    #100;

    // Send data serially at specified rate
        for (col_index = 0; col_index < 17187; col_index = col_index + 1) begin
            // Send each column's elements serially
            Start = 1;
            #CLK_PERIOD;
            for (row_index = 0; row_index < 8; row_index = row_index + 1) begin
                // Read data from CSV file
                Rx_Empty = 0;
                $fscanf(input_file, "%d,", Xin); // Assuming data in CSV is integer and comma separated
                #CLK_PERIOD; // Wait for the next sample
                 // Wait for Done signal
            end
            Start = 0;
            #13000;               
            end
         game = 0;
         #CLK_PERIOD;
        // Close input CSV files
        $fclose(input_file);
        // Finish simulation
        $finish;
  end
    initial begin
     output_file = $fopen("C:\\04_30_2024\\Hinf_Filter_Module_1p0_1_28_35_final\\EEG_data_Hinf_Output_64_1_28_35_fixed.csv", "w");
     while(game)
     begin
    // Open output CSV file

    if(D_Wr)
    begin
     for ( i = 0; i < 8; i = i + 1) begin
         D[i] = D_out;
            #CLK_PERIOD;
    end
    if (i == 8) begin
        $fopen(output_file, "w");
        $fdisplay(output_file, "%d,%d,%d,%d,%d,%d,%d,%d", D[0][63:0], D[1][63:0], D[2][63:0], D[3][63:0], D[4][63:0], D[5][63:0], D[6][63:0], D[7][63:0]);
       // $fdisplay(output_file, "%d,%d,%d,%d,%d,%d,%d,%d", D[0][31:0], D[1][31:0], D[2][31:0], D[3][31:0], D[4][31:0], D[5][31:0], D[6][31:0], D[7][31:0]);

    end
    //$fdisplay(output_file, "\n");
    end
    #CLK_PERIOD;

     end
             $fclose(output_file);
    end
endmodule

//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/01/2024 06:26:58 PM
// Design Name: 
// Module Name: invert3x3
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

module divide(
  input wire signed [63:0] X,
  input wire signed [63:0] Y,
  input wire Start,
  output wire signed [63:0] Q_F,
  input clk,
  input rst_n
);
  parameter INIT1=0, INIT2=1, CAL=2, RND=3, RESULT=4;
  reg[2:0] State;
  reg Xs, Ys, Qs;
  reg[62:0] Xu, Yu;
  reg[63:0] acc, acc_next; //unsigned
  reg[62:0] quo, quo_next; //unsigned
  reg[63:0] Q;
  assign Q_F = Q;
  reg [6:0] i;
  always@(*) //To get sign from inputs
    begin
      Xs = X[63]; // X[WIDTH-1+:1]?
      Ys = Y[63]; //Y[WIDTH-1+:1]?
    end
  always@(*)
    begin
      if(acc >= {1'b0, Yu})
         begin
           acc_next = acc - Yu;
           {acc_next, quo_next} = {acc_next[62:0], quo, 1'b1};
         end
      else begin
        {acc_next, quo_next} = {acc, quo} << 1;
      end
    end
  always@(posedge clk)
    begin
      if(!rst_n)
        begin
          i <= 0;
          State <= INIT1;
        end
      //else begin
      case(State)
        INIT1:
        begin
          if(Start)
          begin
            if(X==0) Q <= 0;
            else begin
            Xu <= Xs ? -X[62:0] : X[62:0];
            Yu <= Ys ? -Y[62:0] : Y[62:0];
          	Qs <= Xs + Ys; // XOR operation equivalent 
          	State <= INIT2;
            end
          end
        end
        INIT2:
        begin
          {acc,quo} <= {{63{1'b0}}, Xu, 1'b0}; // INitializing acc and quo
          State <= CAL;
        end
        CAL:
        begin
          if(i==97) State <= RND;//108 iterations
          else i <= i+1;
          acc <= acc_next;
          quo <= quo_next;
        end
        RND:
        begin
          i <= 0;
          if(quo_next[0]==1'b1) begin
            if(quo[0]==1'b1||acc_next[62:1]!=0) quo <= quo + 1;
          end
          State <= RESULT;
        end
        RESULT:
        begin
          if(quo!=0) Q <= Qs ? {1'b1, -quo} : {1'b0, quo};
          else Q <= 0;
          State <= INIT1;
        end
        default:
        begin
          i <= 0;
          State <= INIT1;
        end
      endcase
      end
    //end
endmodule
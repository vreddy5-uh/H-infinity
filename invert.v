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


module invert(
    input wire clk,
    input wire rst_n,
    input wire En,
    input wire signed [63:0] Xin00, Xin01, Xin02, Xin10, Xin11, Xin12, Xin20, Xin21, Xin22,
    output wire signed [63:0] Xout00, Xout01, Xout02, Xout10, Xout11, Xout12, Xout20, Xout21, Xout22
    );

    parameter INIT=0, Det=1, Inv=2;
    reg[1:0] State;
  	reg start;
    //reg signed [63:0] Temp[2:0][2:0];
    reg signed [127:0] T[2:0][2:0];
    reg signed [191:0] D_191;
    reg signed [127:0] In1_N, In2_N, In3_N, In4_N, In5_N, In6_N, In7_N, In8_N, In9_N;
    reg signed [127:0] In_D;
    wire signed [127:0] X00, X01, X02, X10, X11, X12, X20, X21, X22;
    //Instatiating Division module
  	divide_128 div1(In1_N, In_D, start, X00, clk, rst_n); //Denominator is always Dererminant of the matrix
    divide_128 div2(In2_N, In_D, start, X01, clk, rst_n);
    divide_128 div3(In3_N, In_D, start, X02, clk, rst_n);
    divide_128 div4(In4_N, In_D, start, X10, clk, rst_n);
    divide_128 div5(In5_N, In_D, start, X11, clk, rst_n);
    divide_128 div6(In6_N, In_D, start, X12, clk, rst_n);
    divide_128 div7(In7_N, In_D, start, X20, clk, rst_n);
    divide_128 div8(In8_N, In_D, start, X21, clk, rst_n);
    divide_128 div9(In9_N, In_D, start, X22, clk, rst_n);
    assign Xout00 = {X00[127],X00[98:35]};
    assign Xout01 = {X01[127],X01[98:35]};
    assign Xout02 = {X02[127],X02[98:35]};
    assign Xout10 = {X10[127],X10[98:35]};
    assign Xout11 = {X11[127],X11[98:35]};
    assign Xout12 = {X12[127],X12[98:35]};
    assign Xout20 = {X20[127],X20[98:35]};
    assign Xout21 = {X21[127],X21[98:35]};
    assign Xout22 = {X22[127],X22[98:35]};
    
//Inversion function sequential block
    always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
           State <= INIT;
           start <= 0;
        end
        else begin
           case(State)
           INIT: begin //Start computing inverse function when Enable = 1
                    start <= 0;
             		if(En)
             		begin //Finding Transpose of Adjoint matrix
                        T[0][0] <= Xin11*Xin22-Xin12*Xin21;
                        T[0][1] <= Xin10*Xin22-Xin12*Xin20;
                        T[0][2] <= Xin10*Xin21-Xin11*Xin20;
                        T[1][0] <= Xin01*Xin22-Xin02*Xin21;
                        T[1][1] <= Xin00*Xin22-Xin02*Xin20;
                        T[1][2] <= Xin00*Xin21-Xin01*Xin20;
                        T[2][0] <= Xin01*Xin12-Xin02*Xin11;
                        T[2][1] <= Xin00*Xin12-Xin02*Xin10;
                        T[2][2] <= Xin00*Xin11-Xin01*Xin10;
                        State <= Det;
                    end
                    else State <= INIT;
                end
           Det: begin //Finding Determinant of the input Matrix
             		D_191 <= Xin00*T[0][0]-Xin01*T[0][1]+Xin02*T[0][2];
             		State = Inv;
                end
           Inv: begin
             		if(In_D!=0)
               		begin
                      	   start <= 1;
                      	   State <= INIT;
                    end
                    else State <= INIT;
             		// else, Can introduce some error signal to mention divide by zero condition
                end
           default: begin
                        State = INIT;
                    end
            endcase
        end
    end
    always@(*)
    begin
        if(!rst_n)
        begin
            In_D <= 0;
//            Temp[0][0] <= 0;
//            Temp[0][1] <= 0;
//            Temp[0][2] <= 0;
//            Temp[1][0] <= 0;
//            Temp[1][1] <= 0;
//            Temp[1][2] <= 0;
//            Temp[2][0] <= 0;
//            Temp[2][1] <= 0;
//            Temp[2][2] <= 0;
            In1_N <= 0; In2_N <= 0; In3_N <= 0;
            In4_N <= 0; In5_N <= 0; In6_N <= 0;
            In7_N <= 0; In8_N <= 0; In9_N <= 0;
        end
        else begin
            In_D <= {D_191[191],D_191[162:35]};
//            Temp[0][0] <= {T[0][0][127],T[0][0][98:35]};
//            Temp[0][1] <= {T[0][1][127],T[0][1][98:35]};
//            Temp[0][2] <= {T[0][2][127],T[0][2][98:35]};
//            Temp[1][0] <= {T[1][0][127],T[1][0][98:35]};
//            Temp[1][1] <= {T[1][1][127],T[1][1][98:35]};
//            Temp[1][2] <= {T[1][2][127],T[1][2][98:35]};
//            Temp[2][0] <= {T[2][0][127],T[2][0][98:35]};
//            Temp[2][1] <= {T[2][1][127],T[2][1][98:35]};
//            Temp[2][2] <= {T[2][2][127],T[2][2][98:35]};
            In1_N <= T[0][0]; In2_N <= -T[1][0]; In3_N <= T[2][0];
            In4_N <= -T[0][1]; In5_N <= T[1][1]; In6_N <= -T[2][1];
            In7_N <= T[0][2]; In8_N <= -T[1][2]; In9_N <= T[2][2];
            
        end
    end
    
endmodule
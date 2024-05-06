//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2024 03:49:25 PM
// Design Name: 
// Module Name: Hinf_top
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


module Hinftop(
  input wire clk,
  input wire rst_n,
  input wire Start,
  input wire signed [63:0] Xin,
  input wire Tx_Full,
  input wire Rx_Empty,
  output wire D_Rd,
  output wire D_Wr,
  output wire signed [63:0] D_out,
  output wire Done
    );
    
 //initializing parameters
  parameter signed [63:0] gt1=64'h60C950D10, gt2=64'h1F36AF2EF; 
 //state parameters for FSM
  parameter INIT=0, Step1=1, Step2=2, Step3=3, Step4=4, Step5=5, Step6=6, Step7=7, Step8=8, Step9=9, Step10=10, Step11=11, Step12=12, Step13=13, Step14=14, Step15=15, Step16=16, Step17=17, Step18=18;
  reg[5:0] State;
 //Internal registers
  reg signed [63:0] Yo;
  reg W_En, R_En, D;
  reg signed [63:0] Pt[2:0][2:0]; //Noise Covariance Matrix
  reg signed [63:0] Wi[2:0][4:0]; //Estimated weight per channel
  reg signed [63:0] EOG1, EOG2, EOG3; //EOG reference channels
  reg signed [63:0] EEG1, EEG2, EEG3, EEG4, EEG5; //Raw EEG signals
  reg signed [63:0] Yo1, Yo2, Yo3, Yo4, Yo5;
  reg signed [127:0] Yt1, Yt2, Yt3, Yt4, Yt5;
  reg signed [63:0] Ri[2:0]; //EOG matrix, Equivalent to 3X1 matrix
  reg En;
  //reg[63:0] Pin00, Pin01, Pin02, Pin10, Pin11, Pin12, Pin20, Pin21, Pin22;
  reg signed [63:0] Xin00, Xin01, Xin02, Xin10, Xin11, Xin12, Xin20, Xin21, Xin22;
  reg signed [63:0] Pout00, Pout01, Pout02, Pout10, Pout11, Pout12, Pout20, Pout21, Pout22;
  wire signed [63:0] Xout00, Xout01, Xout02, Xout10, Xout11, Xout12, Xout20, Xout21, Xout22;
  reg[8:0] Cnt;
  reg signed [127:0] Rit[2:0][2:0];
  reg signed [63:0] Ritt[2:0][2:0];
  reg signed [127:0] Ritg00, Ritg01, Ritg02, Ritg10, Ritg11, Ritg12, Ritg20, Ritg21, Ritg22;
  reg signed [127:0] PR[2:0];//Equivalent to 3X1 matrix
  reg signed [63:0] PRt;
  reg signed [127:0] RPRt[2:0];
  reg signed [63:0] RPR[2:0];
  reg signed [127:0] PRY11, PRY12, PRY13, PRY21, PRY22, PRY23, PRY31, PRY32, PRY33, PRY41, PRY42, PRY43, PRY51, PRY52, PRY53;
  reg signed [63:0] PRYt11, PRYt12, PRYt13, PRYt21, PRYt22, PRYt23, PRYt31, PRYt32, PRYt33, PRYt41, PRYt42, PRYt43, PRYt51, PRYt52, PRYt53;
  reg signed [63:0] In, Den, Q1, Q2, Q3;
  wire signed [63:0] Q;
  reg start;
  reg[3:0] Ctrl;
  
 //Inverse module instantiation
 invert Invert_DUT_Gen( clk, rst_n, En, Xin00, Xin01, Xin02, Xin10, Xin11, Xin12, Xin20, Xin21, Xin22,
            Xout00, Xout01, Xout02, Xout10, Xout11, Xout12, Xout20, Xout21, Xout22);
 //Division module instantiation
  divide div_DUT_h1(In, Den, start, Q, clk, rst_n);
  
 //Sequential circuit
 assign D_out = Yo; //64 to 32 bit (1,10,21 fixed point)

 assign D_Wr = W_En;
 assign D_Rd = R_En;
 assign Done = D;
  always@(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
    begin
        //initialize Noise Covariance Matrix and weight matrix
        Pt[0][0] <= 64'h2800000000; Pt[0][1] <= 64'b0; Pt[0][2] <= 64'b0; 
        Pt[1][0] <= 64'b0; Pt[1][1] <= 64'h2800000000; Pt[1][2] <= 64'b0; //5 in 64-bit fixed point is 64'h1400000000000
        Pt[2][0] <= 64'b0; Pt[2][1] <= 64'b0; Pt[2][2] <= 64'h2800000000; //0.1 in 64 bit fixed point is 64'h66666666666
        Wi[0][0] <= 64'b0; Wi[0][1] <= 64'b0; Wi[0][2] <= 64'b0; Wi[0][3] <= 64'b0; Wi[0][4] <= 64'b0;
        Wi[1][0] <= 64'b0; Wi[1][1] <= 64'b0; Wi[1][2] <= 64'b0; Wi[1][3] <= 64'b0; Wi[1][4] <= 64'b0; 
        Wi[2][0] <= 64'b0; Wi[2][1] <= 64'b0; Wi[2][2] <= 64'b0; Wi[2][3] <= 64'b0; Wi[2][4] <= 64'b0; 
        Cnt <= 9'b0;
        D <= 1'b0;
        Ctrl <= 4'b000;
        En <= 1'b0;
      	start <= 1'b0;
      	W_En <= 1'b0;
        State <= INIT;
    end
    else
    begin
        case(State)
        INIT: begin 
                  D <= 0;
                  W_En <= 1'b0;
                  if(!Rx_Empty & Start)
                  begin
          		    if(Ctrl==4'b0000) begin R_En <= 1'b1; Ctrl <= Ctrl+1; end 
                    else if(Ctrl==4'b0001) begin EEG1 <= Xin; Ctrl <= Ctrl+1; end
                    else if(Ctrl==4'b0010) begin EEG2 <= Xin; Ctrl <= Ctrl+1; end
                    else if(Ctrl==4'b0011) begin EEG3 <= Xin; Ctrl <= Ctrl+1; end
                    else if(Ctrl==4'b0100) begin EEG4 <= Xin; Ctrl <= Ctrl+1; end
                    else if(Ctrl==4'b0101) begin EEG5 <= Xin; Ctrl <= Ctrl+1; end
                    else if(Ctrl==4'b0110) begin EOG1 <= Xin; Ctrl <= Ctrl+1; end
                    else if(Ctrl==4'b0111) begin EOG2 <= Xin; Ctrl <= Ctrl+1; end
          		    else if(Ctrl==4'b1000)
                    begin
                        EOG3 <= Xin;
                        Ctrl <= 4'b0000;
                        State<=Step1;
                    end
                  end
                  else R_En <= 1'b0;
                  end
        Step1: begin //Calculate EOG matrix
                 R_En <= 1'b0;
                 Ri[0]<=EOG1-EOG3; //64 bit
                 Ri[1]<=EOG3-EOG2;
                 Ri[2]<=64'h800000000; //1 in 64 bit Fixed point
                 State<=Step2;
               end 
        Step2: begin //Calculate Output Yt, Pt inverse and R * R transpose
                 Yt1<= Ri[0]*Wi[0][0]+Ri[1]*Wi[1][0]+Ri[2]*Wi[2][0]; //128 bit
                 Yt2<= Ri[0]*Wi[0][1]+Ri[1]*Wi[1][1]+Ri[2]*Wi[2][1];
                 Yt3<= Ri[0]*Wi[0][2]+Ri[1]*Wi[1][2]+Ri[2]*Wi[2][2];
                 Yt4<= Ri[0]*Wi[0][3]+Ri[1]*Wi[1][3]+Ri[2]*Wi[2][3];
                 Yt5<= Ri[0]*Wi[0][4]+Ri[1]*Wi[1][4]+Ri[2]*Wi[2][4];
                 Xin00 <= Pt[0][0]; //64 bit
                 Xin01 <= Pt[0][1];
                 Xin02 <= Pt[0][2];
                 Xin10 <= Pt[1][0];
                 Xin11 <= Pt[1][1];
                 Xin12 <= Pt[1][2];
                 Xin20 <= Pt[2][0];
                 Xin21 <= Pt[2][1];
                 Xin22 <= Pt[2][2];
                 En <= 1'b1;
          		 Rit[0][0] <= Ri[0]*Ri[0]; //128 bit
          		 Rit[0][1] <= Ri[0]*Ri[1];
          		 Rit[0][2] <= Ri[0]*Ri[2];
          		 Rit[1][0] <= Ri[1]*Ri[0];
          		 Rit[1][1] <= Ri[1]*Ri[1];
          		 Rit[1][2] <= Ri[1]*Ri[2];
          		 Rit[2][0] <= Ri[2]*Ri[0];
          		 Rit[2][1] <= Ri[2]*Ri[1];
          		 Rit[2][2] <= Ri[2]*Ri[2];
                 State <= Step18;
               end
        Step18: begin //Calculate Output Yt, Pt inverse and R * R transpose
          		 Ritt[0][0] <= {Rit[0][0][127],Rit[0][0][98:35]}; //128 to 64 bit
          		 Ritt[0][1] <= {Rit[0][1][127],Rit[0][1][98:35]};
          		 Ritt[0][2] <= {Rit[0][2][127],Rit[0][2][98:35]};
          		 Ritt[1][0] <= {Rit[1][0][127],Rit[1][0][98:35]};
          		 Ritt[1][1] <= {Rit[1][1][127],Rit[1][1][98:35]};
          		 Ritt[1][2] <= {Rit[1][2][127],Rit[1][2][98:35]};
          		 Ritt[2][0] <= {Rit[2][0][127],Rit[2][0][98:35]};
          		 Ritt[2][1] <= {Rit[2][1][127],Rit[2][1][98:35]};
          		 Ritt[2][2] <= {Rit[2][2][127],Rit[2][2][98:35]};
                 State <= Step3;
               end
        Step3: begin // Calculating Pt inverse - (1/gamma*gamma)(R * R transpose)
          		 En <= 1'b0;
                 if(Cnt==210) // Can be fine tuned to if required to 118
                 begin
                   Yo1<= EEG1 - {Yt1[127],Yt1[98:35]}; //128 to 64 bit {x[127],x[109:46]};
                   Yo2<= EEG2 - {Yt2[127],Yt2[98:35]};
                   Yo3<= EEG3 - {Yt3[127],Yt3[98:35]};
                   Yo4<= EEG4 - {Yt4[127],Yt4[98:35]};
                   Yo5<= EEG5 - {Yt5[127],Yt5[98:35]};
          		   Ritg00 <= gt1*Ritt[0][0]; //128 bit
          		   Ritg01 <= gt1*Ritt[0][1];
          		   Ritg02 <= gt1*Ritt[0][2];
          		   Ritg10 <= gt1*Ritt[1][0];
          		   Ritg11 <= gt1*Ritt[1][1];
          		   Ritg12 <= gt1*Ritt[1][2];
          		   Ritg20 <= gt1*Ritt[2][0];
          		   Ritg21 <= gt1*Ritt[2][1];
          		   Ritg22 <= gt1*Ritt[2][2];
          		   Pout00 <= Xout00;
                   Pout01 <= Xout01;
                   Pout02 <= Xout02;
                   Pout10 <= Xout10;
                   Pout11 <= Xout11;
                   Pout12 <= Xout12;
                   Pout20 <= Xout20;
                   Pout21 <= Xout21;
                   Pout22 <= Xout22;
                   Cnt <= 9'b0;
                   State <= Step4;
                 end
                 else Cnt <= Cnt+1;
               end
        Step4: begin //Calculating Pt inverse - (1/gamma*gamma)(R * R transpose) and then its inverse
          		 Xin00 <= Pout00 - {Ritg00[127],Ritg00[98:35]}; //128 to 64 bit
          		 Xin01 <= Pout01 - {Ritg01[127],Ritg01[98:35]};
          		 Xin02 <= Pout02 - {Ritg02[127],Ritg02[98:35]};
          		 Xin10 <= Pout10 - {Ritg10[127],Ritg10[98:35]};
           		 Xin11 <= Pout11 - {Ritg11[127],Ritg11[98:35]};
          		 Xin12 <= Pout12 - {Ritg12[127],Ritg12[98:35]};
          		 Xin20 <= Pout20 - {Ritg20[127],Ritg20[98:35]};
          		 Xin21 <= Pout21 - {Ritg21[127],Ritg21[98:35]};
         		 Xin22 <= Pout22 - {Ritg22[127],Ritg22[98:35]};
                 En <= 1'b1;
          		 State <= Step5;
               end
        Step5: begin
                 En <= 1'b0;
                 if(Cnt==210) // Can be fine tuned to if required to 118
                 begin
                   PR[0] <= Xout00*Ri[0]+Xout01*Ri[1]+Xout02*Ri[2]; //128 bit
                   PR[1] <= Xout10*Ri[0]+Xout11*Ri[1]+Xout12*Ri[2];
                   PR[2] <= Xout20*Ri[0]+Xout21*Ri[1]+Xout22*Ri[2];
                   Cnt <= 9'b0;
                   State <= Step6;
                 end
                 else Cnt <= Cnt+1;
               end
        Step6: begin
          		 RPR[0] <= {PR[0][127], PR[0][98:35]}; //128 to 64 bit
          		 RPR[1] <= {PR[1][127], PR[1][98:35]}; //128 to 64 bit
          		 RPR[2] <= {PR[2][127], PR[2][98:35]}; //128 to 64 bit
          		 State <= Step16;
               end
        Step16: begin
          		 RPRt[0] <= Ri[0]*RPR[0]; //128 bit
          		 RPRt[1] <= Ri[1]*RPR[1]; //128 bit
          		 RPRt[2] <= Ri[2]*RPR[2]; //128 bit
          		 State <= Step17;
               end
        Step17: begin
          		 PRt <= 64'h800000000 + {RPRt[0][127], RPRt[0][98:35]} + {RPRt[1][127], RPRt[1][98:35]} + {RPRt[2][127], RPRt[2][98:35]}; //128 bit
          		 State <= Step7;
               end
        Step7: begin
          		 In <= {PR[0][127], PR[0][98:35]}; //128 to 64 bit {x[95],x[86:23]};
          		 Den <= PRt; 
          		 start <= 1'b1;
          		 State <= Step8;
               end
        Step8: begin
          		 start <= 1'b0;
                 if(Cnt==115)
                 begin
                   Q1 <= Q;
                   In <= {PR[1][127], PR[1][98:35]}; //128 to 64 bit {x[95],x[86:23]};
                   start <= 1'b1;
                   Cnt <= 9'b0;
                   State <= Step9;
                 end
                 else Cnt <= Cnt+1;
               end
        Step9: begin
          		 start <= 1'b0;
                 if(Cnt==115)
                 begin
                   Q2 <= Q;
                   In <= {PR[2][127], PR[2][98:35]}; //128 to 64 bit {x[95],x[86:23]};
                   start <= 1'b1;
                   Cnt <= 9'b0;
                   State <= Step10;
                 end
                 else Cnt <= Cnt+1;
               end
        Step10: begin
          		 start <= 1'b0;
                 if(Cnt==115)
                 begin
                   Q3 <= Q;
                   Cnt <= 9'b0;
                   State <= Step11;
                 end
                 else Cnt <= Cnt+1;
               end
        Step11: begin
                   PRY11 <= Q1*Yo1; //128 bit
                   PRY12 <= Q2*Yo1;
                   PRY13 <= Q3*Yo1;
                   PRY21 <= Q1*Yo2;
                   PRY22 <= Q2*Yo2;
                   PRY23 <= Q3*Yo2;
                   PRY31 <= Q1*Yo3;
                   PRY32 <= Q2*Yo3;
                   PRY33 <= Q3*Yo3;
                   PRY41 <= Q1*Yo4;
                   PRY42 <= Q2*Yo4;
                   PRY43 <= Q3*Yo4;
                   PRY51 <= Q1*Yo5;
                   PRY52 <= Q2*Yo5;
                   PRY53 <= Q3*Yo5;
                   State <= Step12;
               end
        Step12: begin 
                   PRYt11 <= {PRY11[127],PRY11[98:35]}; PRYt21 <= {PRY21[127],PRY21[98:35]}; PRYt31 <= {PRY31[127],PRY31[98:35]}; //128 to 64 bit
                   PRYt41 <= {PRY41[127],PRY41[98:35]}; PRYt51 <= {PRY51[127],PRY51[98:35]};
                   PRYt12 <= {PRY12[127],PRY12[98:35]}; PRYt22 <= {PRY22[127],PRY22[98:35]}; PRYt32 <= {PRY32[127],PRY32[98:35]};
                   PRYt42 <= {PRY42[127],PRY42[98:35]}; PRYt52 <= {PRY52[127],PRY52[98:35]}; 
                   PRYt13 <= {PRY13[127],PRY13[98:35]}; PRYt23 <= {PRY23[127],PRY23[98:35]}; PRYt33 <= {PRY33[127],PRY33[98:35]};
                   PRYt43 <= {PRY43[127],PRY43[98:35]}; PRYt53 <= {PRY53[127],PRY53[98:35]};
          		   Ritg00 <= gt2*Ritt[0][0]; //128 bit
          		   Ritg01 <= gt2*Ritt[0][1];
          		   Ritg02 <= gt2*Ritt[0][2];
          		   Ritg10 <= gt2*Ritt[1][0];
          		   Ritg11 <= gt2*Ritt[1][1];
          		   Ritg12 <= gt2*Ritt[1][2];
          		   Ritg20 <= gt2*Ritt[2][0];
          		   Ritg21 <= gt2*Ritt[2][1];
          		   Ritg22 <= gt2*Ritt[2][2];
                   State <= Step13;
                end
        Step13: begin //Updating Weight matrix
                  Wi[0][0] <= Wi[0][0] + PRYt11; Wi[0][1] <= Wi[0][1] + PRYt21; Wi[0][2] <= Wi[0][2] + PRYt31;
                  Wi[0][3] <= Wi[0][3] + PRYt41; Wi[0][4] <= Wi[0][4] + PRYt51;                        
                  Wi[1][0] <= Wi[1][0] + PRYt12; Wi[1][1] <= Wi[1][1] + PRYt22; Wi[1][2] <= Wi[1][2] + PRYt32;
                  Wi[1][3] <= Wi[1][3] + PRYt42; Wi[1][4] <= Wi[1][4] + PRYt52;                        
                  Wi[2][0] <= Wi[2][0] + PRYt13; Wi[2][1] <= Wi[2][1] + PRYt23; Wi[2][2] <= Wi[2][2] + PRYt33;
                  Wi[2][3] <= Wi[2][3] + PRYt43; Wi[2][4] <= Wi[2][4] + PRYt53;
                  Xin00 <= Pout00 + {Ritg00[127],Ritg00[98:35]}; //128 to 64 bit
          		  Xin01 <= Pout01 + {Ritg01[127],Ritg01[98:35]};
          		  Xin02 <= Pout02 + {Ritg02[127],Ritg02[98:35]};
          		  Xin10 <= Pout10 + {Ritg10[127],Ritg10[98:35]};
           		  Xin11 <= Pout11 + {Ritg11[127],Ritg11[98:35]};
          		  Xin12 <= Pout12 + {Ritg12[127],Ritg12[98:35]};
          		  Xin20 <= Pout20 + {Ritg20[127],Ritg20[98:35]};
          		  Xin21 <= Pout21 + {Ritg21[127],Ritg21[98:35]};
         		  Xin22 <= Pout22 + {Ritg22[127],Ritg22[98:35]};
                  En <= 1'b1;
          		  State <= Step14;
                end
        Step14: begin
                  En <= 1'b0;
                  if(Cnt==210)
                  begin
                    Pt[0][0] <= Xout00 + 64'h157; Pt[0][1] <= Xout01; Pt[0][2] <= Xout02; // 64 bit custom 1, 28, 35 value of 1e-10 is 64'h3
                    Pt[1][0] <= Xout10; Pt[1][1] <= Xout11 + 64'h157; Pt[1][2] <= Xout12; // 64'h1B7C is 1e-10
                    Pt[2][0] <= Xout20; Pt[2][1] <= Xout21; Pt[2][2] <= Xout22 + 64'h157; // 64 bit custom 1, 24, 39 value of 1e-10 is 64'h36
                    Cnt <= 9'b0;
                    State <= Step15;
                  end
                  else Cnt <= Cnt+1;
                end
        Step15: begin // Feeding Outputs to Tx FIFO
                   if(!Tx_Full)
                   begin
          		    if(Ctrl==4'b0000) begin Yo <= Yo1; W_En <= 1'b1; Ctrl <= Ctrl+1; end
                    else if(Ctrl==4'b0001) begin Yo <= Yo2; Ctrl <= Ctrl+1; end
                    else if(Ctrl==4'b0010) begin Yo <= Yo3; Ctrl <= Ctrl+1; end
                    else if(Ctrl==4'b0011) begin Yo <= Yo4; Ctrl <= Ctrl+1; end 
                    else if(Ctrl==4'b0100) begin Yo <= Yo5; Ctrl <= Ctrl+1; end 
                    else if(Ctrl==4'b0101) begin Yo <= EOG1; Ctrl <= Ctrl+1; end 
                    else if(Ctrl==4'b0110) begin Yo <= EOG2; Ctrl <= Ctrl+1; end 
          		    else if(Ctrl==4'b0111)
                    begin
                        Yo <= EOG3; //64 bit to 32 bit Y[63],Y[54:23]
                        Ctrl <= 4'b0000;
                        D <= 1'b1;
                        State <= INIT;
                    end
                   end
                   else W_En <= 1'b0; // check when FIFO is full while loading outputs
               end
        default: begin
                    State <= INIT;
                 end
        endcase
    end
  end
endmodule
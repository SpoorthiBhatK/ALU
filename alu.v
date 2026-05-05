`timescale 1ns / 1ps
`default_nettype none

module ALU_Project #(parameter n=8, c=4)(
    input wire clk, rst, ce, mode, cin,
    input wire [1:0] inp_valid,
    input wire [n-1:0] opa, opb,
    input wire [c-1:0] cmd,

    output reg [2*n:0] res,
    output reg cout, oflow,
    output reg g, l, e,
    output reg err
);

// counters - multi-cycle operations 
reg [1:0] count1, count2, count3, count4;

// store intermediate multiplication results
reg [2*n:0] temp1, temp2;

always @(posedge clk or posedge rst) begin

if(rst) begin
    res <= 0;
    err <= 0;
    oflow <= 0;
    cout <= 0;
    g <= 0; 
    l <= 0; 
    e <= 0;
    count1 <= 0; 
    count2 <= 0;
    count3 <= 0; 
    count4 <= 0;
end

else if(ce) begin //CE check
    res <= 0;
    err <= 0;
    oflow <= 0;
    cout <= 0;
    g <= 0; 
    l <= 0; 
    e <= 0;

    // ARITHMETIC MODE 
    if(mode) begin
        case(cmd)
        // ADD
        0: begin
            if(inp_valid == 2'b11) begin
                res <= opa + opb;
                cout <= res[n];   
            end else err <= 1;
        end

        // SUB
        1: begin
            if(inp_valid == 2'b11) begin
                res <= opa - opb;
                if(opb > opa) oflow <= 1;
            end else err <= 1;
        end

        // ADD_CIN 
        2: begin
            if(inp_valid == 2'b11) begin
                res <= opa + opb + cin;
                cout <= res[n];
            end else err <= 1;
        end

        // SUB_CIN
        3: begin
            if(inp_valid == 2'b11) begin
                res <= opa - opb - cin;
                if(opb > opa) oflow <= 1;
            end else err <= 1;
        end
        // INC_A
        4: if(inp_valid==2'b01) res <= opa + 1; else err <= 1;
        //DEC_A
        5: if(inp_valid==2'b01) res <= opa - 1; else err <= 1;
          //INC_B
        6: if(inp_valid==2'b10) res <= opb + 1; else err <= 1;
            //DEC_B
        7: if(inp_valid==2'b10) res <= opb - 1; else err <= 1;
        // CMP
        8: begin
            if(inp_valid == 2'b11) begin
                if(opa > opb) g <= 1;
                else if(opa < opb) l <= 1;
                else e <= 1;
            end else err <= 1;
        end
        // INC and Mul
        9: begin
            if(inp_valid == 2'b11) begin
                if(count1 == 0) begin
                    temp1 <= (opa+1)*(opb+1); // compute first
                    count1 <= count1 + 1;
                end
                else if(count1 == 2) begin
                    res <= temp1;             // output after delay
                    count1 <= 0;
                end
                else count1 <= count1 + 1;
            end
            else begin
                if(count2 == 1) err <= 1;
                else count2 <= count2 + 1;
            end
        end

        // SHIFT and Mul
        10: begin
            if(inp_valid == 2'b11) begin
                if(count3 == 0) begin
                    temp2 <= (opa << 1) * opb;
                    count3 <= count3 + 1;
                end
                else if(count3 == 2) begin
                    res <= temp2;
                    count3 <= 0;
                end
                else count3 <= count3 + 1;
            end
            else begin
                if(count4 == 1) err <= 1;
                else count4 <= count4 + 1;
            end
        end

        // Signed add
        11: begin
            if(inp_valid == 2'b11) begin
                res <= $signed(opa) + $signed(opb);
                oflow <= (opa[n-1] == opb[n-1]) && (res[n-1] != opa[n-1]);

                if($signed(opa) > $signed(opb)) g <= 1;
                else if($signed(opa) < $signed(opb)) l <= 1;
                else e <= 1;
            end else err <= 1;
        end

        // Signed Sub
        12: begin
            if(inp_valid == 2'b11) begin
                res <= $signed(opa) - $signed(opb);
                oflow <= (opa[n-1] != opb[n-1]) && (res[n-1] != opa[n-1]);

                if($signed(opa) > $signed(opb)) g <= 1;
                else if($signed(opa) < $signed(opb)) l <= 1;
                else e <= 1;
            end else err <= 1;
        end

        default: err <= 1;
        endcase
    end

    // LOGICAL MODE 
    else begin
        case(cmd)
        
        0: if(inp_valid==2'b11) res <= opa & opb; else err <= 1;    //AND
        1: if(inp_valid==2'b11) res <= ~(opa & opb); else err <= 1; //NAND
        2: if(inp_valid==2'b11) res <= opa | opb; else err <= 1;    //OR
        3: if(inp_valid==2'b11) res <= ~(opa | opb); else err <= 1; //NOR
        4: if(inp_valid==2'b11) res <= opa ^ opb; else err <= 1;    //XOR
        5: if(inp_valid==2'b11) res <= ~(opa ^ opb); else err <= 1; //XNOR
        6: if(inp_valid==2'b11) res <= ~opa; else err <= 1;         //NOT_A
        7: if(inp_valid==2'b11) res <= ~opb; else err <= 1;         //NOT_B
        8: if(inp_valid==2'b01) res <= opa >> 1; else err <= 1;     //Right Shift A by 1
        9: if(inp_valid==2'b01) res <= opa << 1; else err <= 1;     //Leftt Shift A by 1
        10: if(inp_valid==2'b10) res <= opb >> 1; else err <= 1;    //Right Shift B by 1
        11: if(inp_valid==2'b10) res <= opb << 1; else err <= 1;    //Left Shift B by 1
        12: begin                                                   //Rotate left
            if(inp_valid == 2'b11) begin
                if(opb > 4'b1111) err <= 1;   
                else res <= (opa << opb[2:0]) | (opa >> (n - opb[2:0]));
            end else err <= 1;
        end
        13: begin                                                   //Rotate right
            if(inp_valid == 2'b11) begin
                if(opb > 4'b1111) err <= 1;
                else res <= (opa >> opb[2:0]) | (opa << (n - opb[2:0]));
            end else err <= 1;
        end
        default: err <= 1;
        endcase
    end
end
end
endmodule

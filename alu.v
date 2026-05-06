`timescale 1ns / 1ps
`default_nettype none

module ALU_Project #(parameter N = 8, C = 4)(

    input  wire               CLK,
    input  wire               RST,
    input  wire               CE,
    input  wire               MODE,
    input  wire               CIN,

    input  wire [1:0]         INP_VALID,
    input  wire [N-1:0]       OPA,
    input  wire [N-1:0]       OPB,
    input  wire [C-1:0]       CMD,

    output reg  [2*N-1:0]     RES,
    output reg                COUT,
    output reg                OFLOW,
    output reg                G,
    output reg                L,
    output reg                E,
    output reg                ERR
);

reg [1:0] COUNT1, COUNT2, COUNT3, COUNT4;

reg [2*N-1:0] MUL1_TEMP, MUL2_TEMP;

reg [2*N-1:0] RES_TEMP;

reg COUT_TEMP;
reg OFLOW_TEMP;
reg G_TEMP;
reg L_TEMP;
reg E_TEMP;
reg ERR_TEMP;

always @(posedge CLK or posedge RST) begin

    if(RST) begin

        RES         <= 0;

        RES_TEMP    <= 0;

        COUT        <= 0;
        OFLOW       <= 0;
        G           <= 0;
        L           <= 0;
        E           <= 0;
        ERR         <= 0;

        COUT_TEMP   <= 0;
        OFLOW_TEMP  <= 0;
        G_TEMP      <= 0;
        L_TEMP      <= 0;
        E_TEMP      <= 0;
        ERR_TEMP    <= 0;

        COUNT1      <= 0;
        COUNT2      <= 0;
        COUNT3      <= 0;
        COUNT4      <= 0;

        MUL1_TEMP   <= 0;
        MUL2_TEMP   <= 0;

    end

    else if(CE) begin

        RES_TEMP    <= 0;

        COUT_TEMP   <= 0;
        OFLOW_TEMP  <= 0;
        G_TEMP      <= 0;
        L_TEMP      <= 0;
        E_TEMP      <= 0;
        ERR_TEMP    <= 0;

        if(MODE) begin

            case(CMD)

            // ADD
            0: begin

                if(INP_VALID == 2'b11) begin

                    RES_TEMP   <= OPA + OPB;

                    COUT_TEMP  <=
                        ({1'b0, OPA} + {1'b0, OPB}) > {N{1'b1}};

                end

                else begin
                    ERR_TEMP <= 1'b1;
                end
            end

            // SUB
            1: begin

                if(INP_VALID == 2'b11) begin

                    RES_TEMP   <= OPA - OPB;

                    OFLOW_TEMP <= (OPB > OPA);

                end

                else begin
                    ERR_TEMP <= 1'b1;
                end
            end

            // ADDC
            2: begin

                if(INP_VALID == 2'b11) begin

                    RES_TEMP <= OPA + OPB + CIN;

                    COUT_TEMP <=
                        ({1'b0, OPA} + {1'b0, OPB} + CIN)
                        > {N{1'b1}};

                end

                else begin
                    ERR_TEMP <= 1'b1;
                end
            end

            // SUBC
            3: begin

                if(INP_VALID == 2'b11) begin

                    RES_TEMP   <= OPA - OPB - CIN;

                    OFLOW_TEMP <=
                        ({1'b0, OPB} + CIN) > OPA;

                end

                else begin
                    ERR_TEMP <= 1'b1;
                end
            end

            // INC A
            4: begin
                if(INP_VALID == 2'b01)
                    RES_TEMP <= OPA + 1;
                else
                    ERR_TEMP <= 1'b1;
            end

            // DEC A
            5: begin
                if(INP_VALID == 2'b01)
                    RES_TEMP <= OPA - 1;
                else
                    ERR_TEMP <= 1'b1;
            end

            // INC B
            6: begin
                if(INP_VALID == 2'b10)
                    RES_TEMP <= OPB + 1;
                else
                    ERR_TEMP <= 1'b1;
            end

            // DEC B
            7: begin
                if(INP_VALID == 2'b10)
                    RES_TEMP <= OPB - 1;
                else
                    ERR_TEMP <= 1'b1;
            end

            // CMP
            8: begin

                if(INP_VALID == 2'b11) begin

                    G_TEMP <= (OPA > OPB);
                    L_TEMP <= (OPA < OPB);
                    E_TEMP <= (OPA == OPB);

                end

                else begin
                    ERR_TEMP <= 1'b1;
                end
            end

            // MUL1
            9: begin

                if(INP_VALID == 2'b11) begin

                    if(COUNT1 == 0) begin

                        MUL1_TEMP <= (OPA + 1) * (OPB + 1);

                        COUNT1 <= COUNT1 + 1;

                    end

                    else if(COUNT1 == 2'd2) begin

                        RES <= MUL1_TEMP;

                        MUL1_TEMP <= (OPA + 1) * (OPB + 1);

                        COUNT1 <= 1;

                    end

                    else begin
                        COUNT1 <= COUNT1 + 1;
                    end
                end

                else begin

                    if(COUNT2 == 2'd2) begin

                        ERR_TEMP <= 1'b1;
                        COUNT2 <= 1;

                    end

                    else begin
                        COUNT2 <= COUNT2 + 1;
                    end
                end
            end

            // MUL2
            10: begin

                if(INP_VALID == 2'b11) begin

                    if(COUNT3 == 0) begin

                        MUL2_TEMP <= (OPA << 1) * OPB;

                        COUNT3 <= COUNT3 + 1;

                    end

                    else if(COUNT3 == 2'd2) begin

                        RES <= MUL2_TEMP;

                        MUL2_TEMP <= (OPA << 1) * OPB;

                        COUNT3 <= 1;

                    end

                    else begin
                        COUNT3 <= COUNT3 + 1;
                    end
                end

                else begin

                    if(COUNT4 == 2'd2) begin

                        ERR_TEMP <= 1'b1;
                        COUNT4 <= 1;

                    end

                    else begin
                        COUNT4 <= COUNT4 + 1;
                    end
                end
            end

            // SADD
            11: begin

                if(INP_VALID == 2'b11) begin

                    RES_TEMP <= $signed(OPA) + $signed(OPB);

                    OFLOW_TEMP <=
                        (OPA[N-1] == OPB[N-1]) &&
                        (($signed(OPA) + $signed(OPB))
                        >> (N-1) != OPA[N-1]);

                    G_TEMP <= ($signed(OPA) > $signed(OPB));
                    L_TEMP <= ($signed(OPA) < $signed(OPB));
                    E_TEMP <= ($signed(OPA) == $signed(OPB));

                end

                else begin
                    ERR_TEMP <= 1'b1;
                end
            end

            // SSUB
            12: begin

                if(INP_VALID == 2'b11) begin

                    RES_TEMP <= $signed(OPA) - $signed(OPB);

                    OFLOW_TEMP <=
                        (OPA[N-1] != OPB[N-1]) &&
                        (($signed(OPA) - $signed(OPB))
                        >> (N-1) != OPA[N-1]);

                    G_TEMP <= ($signed(OPA) > $signed(OPB));
                    L_TEMP <= ($signed(OPA) < $signed(OPB));
                    E_TEMP <= ($signed(OPA) == $signed(OPB));

                end

                else begin
                    ERR_TEMP <= 1'b1;
                end
            end

            default: begin
                ERR_TEMP <= 1'b1;
            end

            endcase
        end

        else begin

            case(CMD)

            // AND
            0: begin
                if(INP_VALID == 2'b11)
                    RES_TEMP <= OPA & OPB;
                else
                    ERR_TEMP <= 1'b1;
            end

            // NAND
            1: begin
                if(INP_VALID == 2'b11)
                    RES_TEMP <= ~(OPA & OPB);
                else
                    ERR_TEMP <= 1'b1;
            end

            // OR
            2: begin
                if(INP_VALID == 2'b11)
                    RES_TEMP <= OPA | OPB;
                else
                    ERR_TEMP <= 1'b1;
            end

            // NOR
            3: begin
                if(INP_VALID == 2'b11)
                    RES_TEMP <= ~(OPA | OPB);
                else
                    ERR_TEMP <= 1'b1;
            end

            // XOR
            4: begin
                if(INP_VALID == 2'b11)
                    RES_TEMP <= OPA ^ OPB;
                else
                    ERR_TEMP <= 1'b1;
            end

            // XNOR
            5: begin
                if(INP_VALID == 2'b11)
                    RES_TEMP <= ~(OPA ^ OPB);
                else
                    ERR_TEMP <= 1'b1;
            end

            // NOT A
            6: begin
                if(INP_VALID == 2'b11)
                    RES_TEMP <= ~OPA;
                else
                    ERR_TEMP <= 1'b1;
            end

            // NOT B
            7: begin
                if(INP_VALID == 2'b11)
                    RES_TEMP <= ~OPB;
                else
                    ERR_TEMP <= 1'b1;
            end

            // SHR A
            8: begin
                if(INP_VALID == 2'b01)
                    RES_TEMP <= OPA >> 1;
                else
                    ERR_TEMP <= 1'b1;
            end

            // SHL A
            9: begin
                if(INP_VALID == 2'b01)
                    RES_TEMP <= OPA << 1;
                else
                    ERR_TEMP <= 1'b1;
            end

            // SHR B
            10: begin
                if(INP_VALID == 2'b10)
                    RES_TEMP <= OPB >> 1;
                else
                    ERR_TEMP <= 1'b1;
            end

            // SHL B
            11: begin
                if(INP_VALID == 2'b10)
                    RES_TEMP <= OPB << 1;
                else
                    ERR_TEMP <= 1'b1;
            end

            // ROL
            12: begin

                if(INP_VALID == 2'b11) begin

                    if(OPB > 4'b1111)
                        ERR_TEMP <= 1'b1;

                    else
                        RES_TEMP <=
                            (OPA << OPB[2:0]) |
                            (OPA >> (N - OPB[2:0]));
                end

                else begin
                    ERR_TEMP <= 1'b1;
                end
            end

            // ROR
            13: begin

                if(INP_VALID == 2'b11) begin

                    if(OPB > 4'b1111)
                        ERR_TEMP <= 1'b1;

                    else
                        RES_TEMP <=
                            (OPA >> OPB[2:0]) |
                            (OPA << (N - OPB[2:0]));
                end

                else begin
                    ERR_TEMP <= 1'b1;
                end
            end

            default: begin
                ERR_TEMP <= 1'b1;
            end

            endcase
        end

        if(MODE && (CMD == 4'd9 || CMD == 4'd10)) begin

            ERR    <= ERR_TEMP;
            OFLOW <= OFLOW_TEMP;
            COUT  <= COUT_TEMP;
            G     <= G_TEMP;
            L     <= L_TEMP;
            E     <= E_TEMP;

        end

        else begin

            RES    <= RES_TEMP;

            ERR    <= ERR_TEMP;
            OFLOW <= OFLOW_TEMP;
            COUT  <= COUT_TEMP;
            G     <= G_TEMP;
            L     <= L_TEMP;
            E     <= E_TEMP;

        end
    end
end

endmodule

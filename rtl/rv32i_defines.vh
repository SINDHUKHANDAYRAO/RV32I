`ifndef RV32I_DEFINES_VH
`define RV32I_DEFINES_VH

// Opcodes
`define OP_R         7'b0110011
`define OP_I         7'b0010011
`define OP_LOAD      7'b0000011
`define OP_STORE     7'b0100011
`define OP_BRANCH    7'b1100011
`define OP_JAL       7'b1101111
`define OP_JALR      7'b1100111
`define OP_LUI       7'b0110111
`define OP_AUIPC     7'b0010111
`define OP_SYSTEM    7'b1110011
`define OP_FENCE     7'b0001111

// ALU control encoding
`define ALU_ADD      4'b0000
`define ALU_SUB      4'b0001
`define ALU_SLL      4'b0010
`define ALU_SLT      4'b0011
`define ALU_SLTU     4'b0100
`define ALU_XOR      4'b0101
`define ALU_SRL      4'b0110
`define ALU_SRA      4'b0111
`define ALU_OR       4'b1000
`define ALU_AND      4'b1001
`define ALU_PASS_B   4'b1010

// Immediate format select
`define IMM_I        3'b000
`define IMM_S        3'b001
`define IMM_B        3'b010
`define IMM_U        3'b011
`define IMM_J        3'b100

// Writeback source select
`define RES_ALU      2'b00
`define RES_MEM      2'b01
`define RES_PC4      2'b10

// ALU op class
`define ALUOP_ADD    2'b00
`define ALUOP_PASSB  2'b01
`define ALUOP_FUNCT  2'b10

`endif
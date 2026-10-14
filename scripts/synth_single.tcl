read_verilog -Irtl rtl/pc_reg.v
read_verilog -Irtl rtl/adder.v
read_verilog -Irtl rtl/imem.v
read_verilog -Irtl rtl/control_unit.v
read_verilog -Irtl rtl/alu_decoder.v
read_verilog -Irtl rtl/imm_gen.v
read_verilog -Irtl rtl/regfile.v
read_verilog -Irtl rtl/branch_unit.v
read_verilog -Irtl rtl/next_pc.v
read_verilog -Irtl rtl/mux2.v
read_verilog -Irtl rtl/mux4.v
read_verilog -Irtl rtl/alu.v
read_verilog -Irtl rtl/lsu.v
read_verilog -Irtl rtl/dmem.v
read_verilog -Irtl rtl/top.v

hierarchy -check -top top
synth -top top

dfflibmap -liberty lib/sky_130.lib
abc -liberty lib/sky_130.lib
clean

write_verilog reports/synth_single_mapped.v
stat -liberty lib/sky_130.lib
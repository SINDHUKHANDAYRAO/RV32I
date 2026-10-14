# Load physical library and mapped netlist
read_liberty lib/sky_130.lib
read_verilog reports/synth_single_mapped.v
link_design top
read_sdc scripts/constraints.sdc

puts "\n===================================================="
puts "       SINGLE-CYCLE TIMING METRICS (SKY130)         "
puts "===================================================="
report_checks -path_delay max -group_count 1 -digits 3
puts "====================================================\n"
create_clock -period 10.000 -name clk [get_ports clk]
set_property PROHIBIT 1 [get_sites -of [get_package_pins W9]]
set_property PROHIBIT 1 [get_sites -of [get_package_pins G4]] 
set_property PROHIBIT 1 [get_sites -of [get_package_pins AD6]] 
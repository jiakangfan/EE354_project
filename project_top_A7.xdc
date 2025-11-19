### Clock 100 MHz
set_property PACKAGE_PIN E3 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -add -name CLK100MHZ -period 10.00 [get_ports CLK100MHZ]

### 7-segment display: segments (active-low)
# a b c d e f g  → seg[6:0]
set_property PACKAGE_PIN T10 [get_ports {seg[6]}] ; # Ca
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

set_property PACKAGE_PIN R10 [get_ports {seg[5]}] ; # Cb
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]

set_property PACKAGE_PIN K16 [get_ports {seg[4]}] ; # Cc
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]

set_property PACKAGE_PIN K13 [get_ports {seg[3]}] ; # Cd
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]

set_property PACKAGE_PIN P15 [get_ports {seg[2]}] ; # Ce
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]

set_property PACKAGE_PIN T11 [get_ports {seg[1]}] ; # Cf
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]

set_property PACKAGE_PIN L18 [get_ports {seg[0]}] ; # Cg
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]

### decimal point
set_property PACKAGE_PIN H15 [get_ports dp]
set_property IOSTANDARD LVCMOS33 [get_ports dp]

### 7-segment display: anodes for 4 digits (rightmost = an[0])
set_property PACKAGE_PIN J17 [get_ports {an[0]}] ; # An0
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]

set_property PACKAGE_PIN J18 [get_ports {an[1]}] ; # An1
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]

set_property PACKAGE_PIN T9  [get_ports {an[2]}] ; # An2
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]

set_property PACKAGE_PIN J14 [get_ports {an[3]}] ; # An3
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]

# We don't have an[4..7] ports in project_top_A7, so remove or comment out:
# set_property PACKAGE_PIN P14 [get_ports {An4}]
# ...
# set_property PACKAGE_PIN U13 [get_ports {An7}]

### Pushbuttons
# Center (btnC) and Up (btnU) already in original file:
set_property PACKAGE_PIN N17 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

set_property PACKAGE_PIN M18 [get_ports btnU]
set_property IOSTANDARD LVCMOS33 [get_ports btnU]

# Add Left / Right / Down buttons (standard Nexys A7 pins)
set_property PACKAGE_PIN P17 [get_ports btnL]
set_property IOSTANDARD LVCMOS33 [get_ports btnL]

set_property PACKAGE_PIN M17 [get_ports btnR]
set_property IOSTANDARD LVCMOS33 [get_ports btnR]

set_property PACKAGE_PIN P18 [get_ports btnD]
set_property IOSTANDARD LVCMOS33 [get_ports btnD]

### VGA outputs
# Red
set_property PACKAGE_PIN A3 [get_ports {vga_r[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[0]}]

set_property PACKAGE_PIN B4 [get_ports {vga_r[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[1]}]

set_property PACKAGE_PIN C5 [get_ports {vga_r[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[2]}]

set_property PACKAGE_PIN A4 [get_ports {vga_r[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[3]}]

# Blue
set_property PACKAGE_PIN B7 [get_ports {vga_b[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[0]}]

set_property PACKAGE_PIN C7 [get_ports {vga_b[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[1]}]

set_property PACKAGE_PIN D7 [get_ports {vga_b[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[2]}]

set_property PACKAGE_PIN D8 [get_ports {vga_b[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[3]}]

# Green
set_property PACKAGE_PIN C6 [get_ports {vga_g[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[0]}]

set_property PACKAGE_PIN A5 [get_ports {vga_g[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[1]}]

set_property PACKAGE_PIN B6 [get_ports {vga_g[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[2]}]

set_property PACKAGE_PIN A6 [get_ports {vga_g[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[3]}]

# Syncs
set_property PACKAGE_PIN B11 [get_ports vga_hs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hs]

set_property PACKAGE_PIN B12 [get_ports vga_vs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vs]

# set_property PACKAGE_PIN L13 [get_ports QuadSpiFlashCS]
# set_property IOSTANDARD LVCMOS33 [get_ports QuadSpiFlashCS]
# set_property PACKAGE_PIN L18 [get_ports RamCS]
# set_property IOSTANDARD LVCMOS33 [get_ports RamCS]
# set_property PACKAGE_PIN H14 [get_ports MemOE]
# set_property IOSTANDARD LVCMOS33 [get_ports MemOE]
# set_property PACKAGE_PIN R11 [get_ports MemWR]
# set_property IOSTANDARD LVCMOS33 [get_ports MemWR]

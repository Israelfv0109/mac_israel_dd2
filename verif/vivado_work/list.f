# --- Includes / Defines
../../rtl/mac_defs.svh

# --- RTL (Subir 2 niveles) ---
../../rtl/adder_40bit.sv
../../rtl/booth_fsm.sv
../../rtl/booth_datapath.sv
../../rtl/accumulator_unit.sv
../../rtl/booth_multiplier.sv
../../rtl/mac_top.sv

# --- Verification (Subir 1 nivel) ---
../mac_if.sv
../mac_tb.sv

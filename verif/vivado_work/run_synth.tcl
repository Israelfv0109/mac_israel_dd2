# 1. Leer los archivos RTL (Subiendo 2 niveles)
read_verilog -sv [glob ../../rtl/*.sv]

# 2. Ejecutar Síntesis
# Nota: mac_top es el nombre correcto ahora
synth_design -top mac_top -part xc7a35ticsg324-1L -flatten_hierarchy none

# 3. Generar Reportes
report_utilization -file utilization_report.txt
report_timing_summary -file timing_report.txt

# 4. Guardar Checkpoint
write_checkpoint -force mac_radix4_synth.dcp
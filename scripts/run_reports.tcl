# === run_reports_basic.tcl ===
# Uso:
#   source run_reports_basic.tcl
#   run_reports_basic D:/ruta/base addmul_32_parallel_3pipe

proc run_reports {base_path fp tag} {

  # === Rutas de carpetas ===
  set base_dir [file normalize "$base_path/$fp"]
  set dir_timing "$base_dir/TIMING"
  set dir_util   "$base_dir/UTILIZATION"
  set dir_power  "$base_dir/POWER"


  file mkdir $dir_timing
  file mkdir $dir_util
  file mkdir $dir_power

  # === 1. COPIA DEL UTILIZATION FLAT (generado automáticamente por Vivado al final de route_design) ===
  # set orig_util_flat "D:/Universidad/Practicas/Vivado/FPNew XCU200/FPNew XCU200.runs/impl_1/fpnew_top_utilization_placed.rpt"
  set orig_util_flat "D:/Universidad/Practicas/Vivado/FPU_final/FPU_final.runs/impl_1/${fp}_utilization_placed.rpt"
  set dest_util_flat "$dir_util/${tag}_utilization_flat.txt"
  file copy -force $orig_util_flat $dest_util_flat

  # === 2. UTILIZATION HIERARCHICAL (generado manualmente) ===
  set dest_util_hier "$dir_util/${tag}_utilization_hierarchical.txt"
  report_utilization -hierarchical -file $dest_util_hier

  # === 3. TIMING SUMMARY ===
  set rpt_timing "$dir_timing/${tag}_timing_summary.txt"
  report_timing_summary -delay_type min_max -report_unconstrained \
      -check_timing_verbose -max_paths 10 -input_pins -routable_nets \
      -name timing_final -file $rpt_timing

  # === 4. POWER REPORT ===
  set rpt_power "$dir_power/${tag}_power.txt"
  report_power -file $rpt_power

  # === LOG ===
  puts "\n>> Reportes generados para '$tag':"
  puts "   - Utilization (flat)  : $dest_util_flat"
  puts "   - Utilization (hier)  : $dest_util_hier"
  puts "   - Timing summary      : $rpt_timing"
  puts "   - Power estimate      : $rpt_power"
}

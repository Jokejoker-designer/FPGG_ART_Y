# Generate mig_7series IP from the unmodified Digilent mig.prj.
set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set prj [file join $root_dir third_party/digilent/arty-a7-100/E.0/1.0/mig.prj]
set ip_dir [file join $root_dir vivado/ip]
file mkdir $ip_dir

if {![file exists $prj]} {
    puts stderr "ERROR: official mig.prj missing: $prj"
    exit 2
}

create_project -force a7lm01_mig [file join $root_dir build vivado_miggen] -part xc7a100tcsg324-1
set_property target_language Verilog [current_project]

create_ip -name mig_7series -vendor xilinx.com -library ip -module_name mig_7series_0 -dir $ip_dir
set_property CONFIG.XML_INPUT_FILE $prj [get_ips mig_7series_0]
generate_target all [get_ips mig_7series_0]
export_ip_user_files -of_objects [get_ips mig_7series_0] -no_script -sync -force
puts "A7_LM01_MIG_IP_PASS dir=$ip_dir/mig_7series_0"
close_project

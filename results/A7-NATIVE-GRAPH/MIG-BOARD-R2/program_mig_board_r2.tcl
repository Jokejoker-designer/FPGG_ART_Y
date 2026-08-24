open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
current_hw_device [get_hw_devices xc7a100t_0]
refresh_hw_device [current_hw_device]
set_property PROGRAM.FILE {D:/Jetking_sem4/SEM_4/arty-a7-online-lm/build/out/arty_a7_ng_mig_board_r2.bit} [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
puts "MIG_BOARD_R2_PROGRAMMED=[current_hw_target]"
close_hw_manager
exit 0

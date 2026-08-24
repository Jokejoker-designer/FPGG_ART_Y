open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
puts "TARGET=[current_hw_target]"
foreach d [get_hw_devices] {
  puts "DEVICE=$d NAME=[get_property NAME $d]"
}
foreach t [get_hw_targets] {
  puts "HW_TARGET=$t"
  catch {puts "  SERIAL=[get_property PARAM.PC.SERIAL $t]"}
  catch {puts "  IDCODE=[get_property IDCODE $t]"}
  catch {puts "  DEVICE_NAME=[get_property DEVICE_NAME $t]"}
}
close_hw_manager
exit 0

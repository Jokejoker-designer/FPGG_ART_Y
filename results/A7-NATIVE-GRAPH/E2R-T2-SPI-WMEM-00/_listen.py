import serial, time, re, sys
ser = serial.Serial('COM12', 115200, timeout=0.2)
print('UART_ARMED', flush=True)
t0 = time.time()
buf = bytearray()
while time.time() - t0 < 180:
    b = ser.read(256)
    if b:
        buf.extend(b)
        sys.stdout.write(b.decode('ascii','replace')); sys.stdout.flush()
    if b'pred=' in buf:
        # wait a bit for newline
        time.sleep(0.3)
        b2 = ser.read(64)
        if b2: buf.extend(b2)
        break
ser.close()
text = buf.decode('ascii','replace')
open(r'D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board\results\A7-NATIVE-GRAPH\E2R-T2-SPI-WMEM-00\uart_capture_r2.txt', 'w', encoding='utf-8').write(text)
m = re.search(r'NATIVE_V1_EXIST_ROW,pred=(\d+)', text)
print('\\nRESULT:', ('pred='+m.group(1)) if m else 'NO_MARKER', 'bytes='+str(len(buf)), flush=True)

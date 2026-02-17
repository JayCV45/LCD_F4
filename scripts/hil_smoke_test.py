import os
import sys
import time
import serial

PASS_TOKEN = "HIL:PASS"
FAIL_TOKEN = "HIL:FAIL"

def main() -> int:
    port = os.environ.get("HIL_COM_PORT", "").strip()
    baud = int(os.environ.get("HIL_BAUD", "115200"))
    timeout_s = int(os.environ.get("HIL_TIMEOUT_S", "20"))
    log_path = os.environ.get("HIL_LOG_PATH", "hil.log")

    if not port:
        print("ERROR: HIL_COM_PORT not set (example: COM5).", file=sys.stderr)
        return 2

    deadline = time.time() + timeout_s

    with serial.Serial(port, baudrate=baud, timeout=0.2) as ser, open(log_path, "w", newline="") as f:
        ser.reset_input_buffer()

        while time.time() < deadline:
            line = ser.readline().decode(errors="replace")
            if not line:
                continue

            f.write(line)
            f.flush()
            print(line, end="")

            if PASS_TOKEN in line:
                print("\nHIL RESULT: PASS")
                return 0
            if FAIL_TOKEN in line:
                print("\nHIL RESULT: FAIL")
                return 1

    print("\nHIL RESULT: TIMEOUT (no PASS/FAIL)")
    return 3

if __name__ == "__main__":
    raise SystemExit(main())

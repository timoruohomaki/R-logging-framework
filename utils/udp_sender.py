import socket
import sys

def send_udp(host, port, message):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.sendto(message.encode('utf-8'), (host, int(port)))
        return True
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return False
    finally:
        sock.close()

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python udp_sender.py HOST PORT MESSAGE")
        sys.exit(1)
    
    host = sys.argv[1]
    port = sys.argv[2]
    message = sys.argv[3]
    
    success = send_udp(host, port, message)
    sys.exit(0 if success else 1)

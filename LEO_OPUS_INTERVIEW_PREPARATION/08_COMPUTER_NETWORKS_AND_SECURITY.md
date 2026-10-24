# 08 — Computer Networks, Transport Protocols & Network Security

---

## 🌐 Tracing a LEO OPUS API Call through the OSI & TCP/IP Stack

When the mobile app calls `POST /api/subscription/create-order`, the request traverses all layers of the networking stack:

```
[ Application Layer ]     HTTPS POST /api/subscription/create-order (JSON Payload + Bearer Token)
         |
[ Presentation Layer ]    TLS 1.3 Encryption / Decryption & JSON Serialization
         |
[ Session Layer ]         TLS Session Management & HTTP Keep-Alive Connection Re-use
         |
[ Transport Layer ]       TCP Segment (Port 443, SYN -> SYN-ACK -> ACK, Flow Control, Sliding Window)
         |
[ Network Layer ]         IP Packet (Source Mobile IP -> Destination Render Gateway IP, Routing, TTL)
         |
[ Data Link Layer ]       Ethernet / Wi-Fi 802.11 Frame (MAC Source -> MAC Router Gateway, CRC Checksum)
         |
[ Physical Layer ]        Radio Frequency (RF) Modulation (4G/5G LTE cellular or Wi-Fi radio waves)
```

---

## ❓ Category 8 Interview Questions: Computer Networks & Security

### Q26: What is the difference between TCP and UDP? Why does LEO OPUS rely on TCP?
- **Interviewer Focus:** Transport layer fundamentals, connection-oriented vs connectionless protocols, reliability mechanisms.
- **Answer A (Concise):**  
  **TCP (Transmission Control Protocol)** is a connection-oriented, reliable protocol that guarantees in-order delivery of data packets via sequence numbers, checksums, acknowledgments (ACKs), and automatic retransmissions. **UDP (User Datagram Protocol)** is a connectionless, lightweight protocol with zero delivery guarantees, used for low-latency streaming and gaming. LEO OPUS relies entirely on TCP (via HTTPS) because job applications, payment transactions, and authentication tokens cannot tolerate dropped packets or corrupted bytes.
- **Answer B (Technical Deep-Dive):**  
  | Feature | TCP (Used in LEO OPUS) | UDP |
  |---|---|---|
  | **Connection Model** | 3-Way Handshake (`SYN` -> `SYN-ACK` -> `ACK`) | Connectionless (sends immediately) |
  | **Reliability** | Guarantees delivery via ACKs & retransmission timeouts | Best-effort; dropped packets are lost |
  | **Ordering** | In-order delivery via 32-bit sequence numbers | Packets may arrive out of order |
  | **Flow & Congestion Control** | Sliding window flow control; Slow Start, Congestion Avoidance algorithms | None; transmits at rate of application |
  | **Header Overhead** | 20–60 bytes | 8 bytes |
  | **Use Case in LEO OPUS** | All REST API calls, Firestore sync, Razorpay checkouts | Not used (hypothetically useful for WebRTC video interviews) |
- **Verified Evidence:** `lib/services/api_service.dart`; `backend/server.js`.
- **Likely Follow-up:** *"Explain the TCP 3-Way Handshake."*
- **Follow-up Answer:** *"1. Client sends `SYN` (Synchronize) with an initial sequence number $ISN_c$. 2. Server responds with `SYN-ACK` with its own $ISN_s$ and acknowledges $ISN_c + 1$. 3. Client responds with `ACK` acknowledging $ISN_s + 1$. Both sides now agree on sequence numbers and connection state is ESTABLISHED."*
- **Common Mistakes to Avoid:** Don't say UDP is "bad." It is designed for speed over reliability where dropped packets are acceptable (e.g., DNS queries, VoIP, live video).

---

### Q27: What is the difference between HTTP and HTTPS? Explain the TLS Handshake.
- **Interviewer Focus:** Cryptography, public key infrastructure (PKI), TLS handshake, and transport layer security.
- **Answer A (Concise):**  
  HTTP transmits data in clear plaintext over TCP port 80, leaving it vulnerable to eavesdropping, packet sniffing, and man-in-the-middle (MITM) attacks. HTTPS encrypts traffic using **TLS (Transport Layer Security)** over port 443, ensuring confidentiality (symmetric encryption), integrity (cryptographic hashing), and server authenticity (X.509 digital certificates signed by trusted Certificate Authorities).
- **Answer B (Technical Deep-Dive):**  
  **The TLS 1.3 Handshake Sequence:**
  1. **Client Hello:** Mobile client connects to `leox-kfsm.onrender.com` over TCP and sends supported cipher suites, TLS version (TLS 1.3), and a client random string + Diffie-Hellman public key share.
  2. **Server Hello & Certificate:** Server selects cipher suite, sends its Diffie-Hellman public key share, server random string, and its X.509 SSL Certificate issued by a Certificate Authority (Let's Encrypt / Google Trust Services).
  3. **Authentication & Key Exchange:** Mobile client verifies the server certificate against the root CA certificates embedded in the mobile operating system (Android/iOS trust store). Both parties independently calculate the shared symmetric Master Secret using Diffie-Hellman math.
  4. **Encrypted Communication:** All subsequent HTTP traffic (Bearer tokens, resume text, Razorpay signatures) is encrypted using symmetric AES-256-GCM or ChaCha20-Poly1305, which is fast and secure.
- **Verified Evidence:** Enforced across all endpoints via HTTPS in `lib/services/api_service.dart` line 21.
- **Likely Follow-up:** *"What is SSL Pinning, and why is it used in banking or enterprise mobile apps?"*
- **Follow-up Answer:** *"SSL/TLS Pinning hardcodes the server's public key or certificate hash directly inside the mobile app. Even if an attacker installs a malicious root certificate on a rooted/jailbroken device to run tools like Burp Suite, the app rejects connections whose certificate does not match the pinned key, defeating Man-in-the-Middle attacks."*
- **Common Mistakes to Avoid:** Don't confuse asymmetric encryption (used during the handshake to exchange keys) with symmetric encryption (used to encrypt the actual payload data).

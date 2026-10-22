# Privacy Policy for ZeroPing

**App Name:** ZeroPing  
**Application ID / Package Name:** `com.piyush.zeroping`  
**Developer:** Piyush Assudani (Founder, Assudani Group)  
**Website:** [https://piyushassudani.in](https://piyushassudani.in)  
**Open Source Repository:** [https://github.com/PiyushASSUDANI123/zeroping-app](https://github.com/PiyushASSUDANI123/zeroping-app)  
**Hosted Privacy URL:** [https://piyushassudani123.github.io/zeroping-app/privacy.html](https://piyushassudani123.github.io/zeroping-app/privacy.html)  
**Contact Email:** [piyushassudani@gmail.com](mailto:piyushassudani@gmail.com)  
**Effective Date:** October 2026  

---

## 1. Zero-Cloud & Zero Data Collection Policy
ZeroPing operates **100% offline** via local peer-to-peer Wi-Fi Hotspot, Wi-Fi Direct, and Bluetooth RFCOMM sockets.
- **No Cloud Servers:** We do not operate any backend servers, databases, or user accounts.
- **No Registration:** You do not need to provide an email address, phone number, name, or password.
- **No Trackers or Analytics:** There are zero ads (No AdMob), zero tracking SDKs (No Firebase Analytics / Facebook SDK), and no telemetry.
- **No Personal Data Stored:** All chat messages, audio recordings, and media reside exclusively in your device's local application sandbox storage.

---

## 2. Permissions & Declarations (Google Play Store Compliant)

| Permission | Technical Requirement | Privacy Protection |
| :--- | :--- | :--- |
| `BLUETOOTH_SCAN`<br>`BLUETOOTH_CONNECT`<br>`BLUETOOTH_ADVERTISE` | Required on Android 12+ to discover nearby peers and maintain local Bluetooth RFCOMM sockets. | Configured with `neverForLocation` flag. Zero device location is determined or transmitted. |
| `NEARBY_WIFI_DEVICES`<br>`ACCESS_FINE_LOCATION` | Required by Android OS to scan for local Wi-Fi Hotspots and Wi-Fi Direct peers. | Android internal Wi-Fi stack only. ZeroPing never records, accesses, or shares GPS coordinates. |
| `RECORD_AUDIO` | Required exclusively for the user-triggered "Walkie-Talkie Push-to-Talk" voice notes. | Audio is recorded strictly while the button is pressed, encrypted with AES-256 on-device, and sent directly to the connected peer over Bluetooth. Never uploaded to the web. |
| `READ_MEDIA_IMAGES`<br>`READ_MEDIA_VIDEO`<br>`READ_MEDIA_AUDIO` | Allows users to select files or memes to transmit offline. | Only user-selected files are read and split into 10KB stream chunks. No background media scanning. |
| `FOREGROUND_SERVICE` | Maintains active high-speed P2P file transfers and audio streaming when screen locks. | Displays an active persistent status notification while running. |

---

## 3. End-to-End Military-Grade Encryption
All communication pipes (text messages, audio notes, and media chunks) are protected by **AES-256 CBC symmetric encryption**. Encryption keys are derived locally on-device from the shared room identifier. No unencrypted text is broadcast over the air.

---

## 4. Ghost Messages & Data Destruction
ZeroPing provides ephemeral "Ghost Messages" with configurable self-destruct timers (5s, 10s, 30s). Once viewed and expired, messages are permanently purged from device RAM and wiped from local storage.

---

## 5. Contact Information
For privacy inquiries or technical questions:
- **Developer:** Piyush Assudani (Founder, Assudani Group)
- **Website:** [https://piyushassudani.in](https://piyushassudani.in)
- **Email:** [piyushassudani@gmail.com](mailto:piyushassudani@gmail.com)

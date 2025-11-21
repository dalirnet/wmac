# WMac

> WiFi MAC Address Controller for Huawei EchoLife GPON Terminal

A native macOS application built with SwiftUI that provides an intuitive interface to manage WiFi access control through MAC address filtering on Huawei EchoLife GPON Terminal routers.

---

## Features

- 📱 Native macOS app with SwiftUI
- 🔐 MAC address filtering management
- 🔧 Direct configuration of GPON Terminal
- ⚡ Lightweight and fast
- ✨ Clean, modern interface

---

## Requirements

- macOS 13.0 (Ventura) or later
- Huawei EchoLife GPON Terminal with SSH access

---

## SSH Access Setup

**1. Access Web Interface**

Navigate to `http://192.168.1.1` and login with:

```
Username: telecomadmin
Password: admintelecom
```

> 💡 Only `telecomadmin` has access to configuration file management.

**2. Download Configuration**

Navigate to: `Advanced → Maintenance Diagnostic → Configuration File Management`

Download the current configuration file.

> ⚠️ Keep a backup before making changes.  
> 💡 If encrypted, decrypt first before editing (not required for all devices).

**3. Configure SSH**

Open the configuration XML file and add this line:

```xml
<X_HW_CLISSHControl Enable="1" port="22" Mode="0" AluSSHAbility="0"/>
```

> ⚠️ Add `X_HW_CLISSHControl` **before** `X_HW_CLITelnetAccess` in the XML file.

Find `SSHLanEnable` and change from `"0"` to `"1"`:

```xml
<AclServices ... SSHLanEnable="1" ... />
```

**4. Upload Configuration**

- Upload the modified configuration file
- Device will reboot automatically

**5. Connect via SSH**

```bash
ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa root@192.168.1.1
```

> 💡 Options required for older `ssh-rsa` algorithm.  
> 🔑 Only `root` user can connect (password on device back). `telecomadmin` is web-only.

---

## Tested On

- Huawei HG8240 series

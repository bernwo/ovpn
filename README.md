# ovpn
Command line interface for OpenVPN-GUI on Windows written in `Powershell`. At the time of writing, OpenVPN on Windows does not have full support for CLI commands, so I wrote a small script which allows me to connect to desired `.ovpn` via CLI instead of right-clicking the task-tray.

## Preliminary
First, download and install [OpenVPN Client for Windows](https://openvpn.net/community-downloads/). Then, you need to add the directory in which the OpenVPN-GUI binaries are located on Windows to path. It is usually located at `C:\Program Files\OpenVPN\bin`.

You also need to download the desired `.ovpn` files and place them in `C:\Users\YOURUSERNAME\OpenVPN\config`. In my ovpn script example usage below, it only works if the filename of the `.ovpn` files follows that of in [Nordvpn's .ovpn files](https://nordvpn.com/ovpn/).

Finally, you need to have the credentials that comes along with your VPN subscription.

## Usage
Once added to path, you can run the following line in Powershell:
```Powershell
ovpn <country code> <udp/tcp>
```
and OpenVPN-GUI will select the `.ovpn` file with the given `country code` and protocol. If there are more than one file for the same country code and protocol, then [`ovpn.ps1`](https://github.com/bernwo/ovpn/blob/main/ovpn.ps1) will choose one at random.
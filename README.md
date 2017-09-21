# Calico WEP Logger
Bash shell to log all wep changes on your kubernetes-calico cluster. Make sure you have calicoctl working properly on your system.

Run this scrip behind systemd.
```
cp calico-wep-logger.service /etc/systemd/system/
systemctl daemon-reload
systemctl start calico-wep-logger
journalctl -fu calico-wep-logger
```

Log output will default on `/var/log/calico-wep.log`.
```
tail -f /var/log/calico-wep.log
```


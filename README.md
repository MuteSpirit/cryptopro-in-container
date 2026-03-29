# CryptoPRO CSP in Docker container

Container allows ...
* ... to use qualified electronic signature on nalog.ru portal
* ... login on nalog.ru or gosuslugi.ru using EDS

Use case has been tested on Ubuntu 22.04.4 LTS using Rutoken EDS 3.0

# HOWTO install

Install on host system:
* pcscd
* libccid
See more details on
* https://support.cryptopro.ru/index.php?/Knowledgebase/Article/View/390/0/rbot-s-kriptopro-csp-v-linux-n-primere-debian-11
* https://dev.rutoken.ru/pages/viewpage.action?pageId=76218369

Run service "pcscd"
```
sudo systemctl enable --now pcscd
```

Download preliminary into current folder:
* CryptoPRO distro from https://www.cryptopro.ru/fns_experiment
* Rutoken Driver from https://www.rutoken.ru/support/download/pkcs/#linux
* Rutoken Plugin from https://www.rutoken.ru/support/download/get/rtPlugin-deb-x64.html
* Rutoken Connect from https://www.rutoken.ru/support/download/get/rtconnect-x64-deb.html
* CryptoPRO browser plugin https://cryptopro.ru/products/cades/plugin
* Rutoken Plugin Adapter Firefox plugin https://addons.mozilla.org/ru/firefox/addon/adapter-rutoken-plugin/
* Gosuslugi Firefox plugin https://ds-plugin.gosuslugi.ru/plugin/upload/Index.spr

Build Docker image
```
make
```

Allow access to EDS tokens for unprivileged user on host OS:
```
cat <<EOF > /tmp/pcsc.rules
polkit.addRule(function(action, subject) {
if (action.id == "org.debian.pcsc-lite.access_card" &&
    subject.user == "$USER") {
        return polkit.Result.YES;
}
});

polkit.addRule(function(action, subject) {
if (action.id == "org.debian.pcsc-lite.access_pcsc" &&
    subject.user == "$USER") {
        return polkit.Result.YES;
}
});
EOF

sudo cp /tmp/pcsc.rules /usr/share/polkit-1/rules.d/pcsc.rules
```
After trial period expiration (in 90 days) you'll have to buy license or rebuild Docker image again.

## Use case

- Plug-in Rutoken EDS.
- Run container:
```
./run.sh
```

## Notes

* pcscd MUST be the same version on host and in container. Otherwise you will see on host errors like:

# Troubleshooting

## User is NOT authorized for action: access_pcsc

### Error

When run `opensc-tool --list-readers` in container
Then on host we see next error message

```
  systemctl status pcscd 
...
Mar 29 16:38:52 pc2 pcscd[227592]: 99999999 auth.c:143:IsClientAuthorized() Process 319219 (user: 1000) is NOT authorized for action: access_pcsc
Mar 29 16:38:52 pc2 pcscd[227592]: 00000133 winscard_svc.c:355:ContextThread() Rejected unauthorized PC/SC client
```

### Fix

Run on host under `root` user
```
    cat <<EOF > /usr/share/polkit-1/rules.d/pcsc.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.debian.pcsc-lite.access_card" &&
        subject.user == "$USER") {
            return polkit.Result.YES;
    }
});

polkit.addRule(function(action, subject) {
    if (action.id == "org.debian.pcsc-lite.access_pcsc" &&
        subject.user == "$USER") {
            return polkit.Result.YES;
    }
});
EOF
```

## No smart card readers found

### Error

When run 'opensc-tool --list-readers' in container
Then `systemctl status pcscd` on host will show next error messages:
```
  systemctl status pcscd 
...
Mar 29 16:10:30 pc2 pcscd[227592]: 69700788 winscard_svc.c:402:ContextThread() Communication protocol mismatch!
Mar 29 16:10:30 pc2 pcscd[227592]: 00000012 winscard_svc.c:404:ContextThread() Client protocol is 4:5
Mar 29 16:10:30 pc2 pcscd[227592]: 00000003 winscard_svc.c:406:ContextThread() Server protocol is 4:4
```

### Reason

PSCSD client in container tried to use newer protocol version and PSCSD server on host rejected it's requests.

### Fix

Use the same PSCSD versions on host and in container

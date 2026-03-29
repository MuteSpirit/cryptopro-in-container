# КриптоПро в Linux контейнере для использования КЭП от ФНС

Описанный подход позволяет пользоваться КЭП от ФНС под любым дистрибутивом Linux.
Тестировалось с Рутокен ЭЦП 3.0

Потребуется:
- Установить всё необходимое для работы токена на хост системе, обычно это pcsc и библиотеки к нему (смотреть на сайте производителя)
- Скачать все необходимые пакеты в папку с Dockerfile
- Собрать образ docker `docker build ./ -t cryptopro-in-container:latest`
- ~~Разрешить открыть окна в wm приложениям со стороны `xhost + local:`~~
- Запустить pcscd
- Запустить контейнер из полученного образа
```
docker run -ti --name cryptopro_doc -v /home/$USER/Documents:/Documents -v /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix"$DISPLAY" cryptopro-in-container:latest /bin/bash -c 'firefox |& cptools ; bash'
# Где /run/pcsсd/pcscd.comm сокет для обращений
# /tmp/.X11-unix доступ к активной сессии
# DISPLAY переменная определяющая где открывать окна
# something папка внутри контейнера с содержимым той папки из которой запускаете
```
- Видим имя своего ruтокена. Добавляем сертификат в контейнер
```
root@d66b9560c771:/# csptest -keyset -enum_cont -fqcn -verifyc
CSP (Type:80) v5.0.10010 KC1 Release Ver:5.0.12455 OS:Linux CPU:AMD64 FastCode:READY:AVX.
AcquireContext: OK. HCRYPTPROV: 17693171
\\.\Aktiv Rutoken ECP 00 00\0c686f35c-328c-0cf8-e404-900dcf68a53
OK.
Total: SYS: 0.010 sec USR: 0.040 sec UTC: 0.820 sec
[ErrorCode: 0x00000000]
```
- Копировать публичный сертификат с токена в файл `certmgr -export -dest mine.crt -container '\\.\Aktiv Rutoken ECP 00 00\0c686f35c-328c-0cf8-e404-900dcf68a53'`
- Установить свой сертификат внутри контейнера `certmgr -install -store uMy -file mine.crt -cont '\\.\Aktiv Rutoken ECP 00 00\0c686f35c-328c-0cf8-e404-900dcf68a53'`
- Создаем образ контейнера `docker commit -m "xx" -a "test" $(docker ps -l -f 'name=cryptopro_doc' --format "{{.ID}}") cryptopro:latest`
- Ненужный контейнер можно удалить `docker rm  $(docker ps -l -f 'name=cryptopro_doc' --format "{{.ID}}")`
- Запускаем браузер `firefox` и CryptoPro `cptools` кликом по ярлыку `FFNCP.desktop`
- Через 90 дней, по окончании триала КриптоПро пересобираем контейнер

## Usecase

Use RuToken EDS to login via EDS on nalog.ru or gosuslugi.ru

## Notes

* Yandex Browser for Corporations is not suitable because only Windows version is available. See https://browser.yandex.ru/b/cryptopro_plugin
* pcscd MUST be the same version on host and in container. Otherwise you will see on host errors like:
```
  systemctl status pcscd 
...
Mar 29 16:10:30 pc2 pcscd[227592]: 69700788 winscard_svc.c:402:ContextThread() Communication protocol mismatch!
Mar 29 16:10:30 pc2 pcscd[227592]: 00000012 winscard_svc.c:404:ContextThread() Client protocol is 4:5
Mar 29 16:10:30 pc2 pcscd[227592]: 00000003 winscard_svc.c:406:ContextThread() Server protocol is 4:4
```

## Troubleshooting

### User is NOT authorized for action: access_pcsc

Run 'opensc-tool --list-readers' in container

```
  systemctl status pcscd 
...
Mar 29 16:38:52 pc2 pcscd[227592]: 99999999 auth.c:143:IsClientAuthorized() Process 319219 (user: 1000) is NOT authorized for action: access_pcsc
Mar 29 16:38:52 pc2 pcscd[227592]: 00000133 winscard_svc.c:355:ContextThread() Rejected unauthorized PC/SC client
```

HOWTO fix

On host
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

### No smart card readers found

Run 'opensc-tool --list-readers' in container
Run 'systemctl status pcscd' on host and read log messages

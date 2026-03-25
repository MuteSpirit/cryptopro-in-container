# 2023 August
FROM debian:stable

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="${PATH}:/opt/cprocsp/bin/amd64/"

# Downloaded from https://www.cryptopro.ru/fns_experiment
ADD linux-amd64_deb.tgz /cryptopro

# Downloaded from https://www.rutoken.ru/support/download/pkcs/#linux
COPY librtpkcs11ecp*amd64.deb /cryptopro

# Downloaded from https://restapi.moedelo.org/eds/crypto/plugin/api/v1/installer/download?os=linux&version=latest and extract the .deb package
COPY moedelo-plugin_*_amd64.deb /cryptopro

# Downloaded from install.kontur.ru
COPY diag.plugin_amd64*.deb /cryptopro

# Downloaded from https://ds-plugin.gosuslugi.ru/plugin/upload/Index.spr
COPY IFCPlugin-x86_64.deb /cryptopro

# Downloaded from https://www.rutoken.ru/support/download/get/rtPlugin-deb-x64.html
COPY libnpRutokenPlugin_*_amd64.deb /cryptopro

RUN apt-get update && \
    apt-get install -y whiptail libccid libpcsclite1 pcscd pcsc-tools opensc libgtk2.0-0 libcanberra-gtk-module libcanberra-gtk3-0 libsm6 firefox-esr nano locales libpci-dev && \
    cd /cryptopro/linux-amd64_deb && \
    dpkg -i /cryptopro/librtpkcs11ecp_*_amd64.deb && \
    ./install.sh cprocsp-rdr-pcsc cprocsp-rdr-rutoken cprocsp-rdr-cryptoki lsb-cprocsp-pkcs11 && \
    dpkg -i /cryptopro/moedelo-plugin_*_amd64.deb && \
    dpkg -i /cryptopro/diag.plugin_amd64*.deb && \
    dpkg -i /cryptopro/IFCPlugin-x86_64.deb && \
    dpkg -i /cryptopro/libnpRutokenPlugin_*_amd64.deb && \
    dpkg -i /cryptopro/linux-amd64_deb/cprocsp-cptools-gtk*amd64.deb && \
    dpkg -i /cryptopro/linux-amd64_deb/cprocsp-rdr-gui-gtk*amd64.deb && \
    dpkg -i /cryptopro/linux-amd64_deb/cprocsp-rdr-pcsc*amd64.deb && \
    dpkg -i /cryptopro/linux-amd64_deb/cprocsp-rdr-rutoken*amd64.deb && \
    dpkg -i /cryptopro/linux-amd64_deb/cprocsp-rdr-cryptoki*amd64.deb && \
    dpkg -i /cryptopro/linux-amd64_deb/lsb-cprocsp-import-ca-certs*all.deb && \
    dpkg -i /cryptopro/linux-amd64_deb/cprocsp-pki-cades*amd64.deb && \
    dpkg -i /cryptopro/linux-amd64_deb/cprocsp-pki-plugin*amd64.deb && \
    dpkg -i /cryptopro/linux-amd64_deb/cprocsp-pki-phpcades*all.deb && \
    sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && update-locale LANG=ru_RU.UTF-8 && \
    ln -snf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
    echo Europe/Moscow > /etc/timezone && \
    echo "export NO_AT_BRIDGE=1" >> /root/.bashrc && \
    echo "alias ll='ls -alFh'" >> /root/.bashrc

ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

# Downloaded from https://www.cryptopro.ru/sites/default/files/products/cades/extensions/firefox_cryptopro_extension_latest.xpi
COPY firefox_cryptopro_extension_latest.xpi /usr/lib/firefox-esr/distribution/extensions/ru.cryptopro.nmcades@cryptopro.ru.xpi

# Downloaded from install.kontur.ru (firefox addon)
COPY kontur.extension@kontur.ru.xpi /usr/lib/firefox-esr/distribution/extensions/kontur.toolbox@gmail.com.xpi

# Downloaded from https://ds-plugin.gosuslugi.ru/plugin/upload/Index.spr
COPY addon*.xpi /usr/lib/firefox-esr/distribution/extensions/pbafkdcnd@ngodfeigfdgiodgnmbgcfha.ru.xpi

# Downloaded from https://addons.mozilla.org/ru/firefox/addon/adapter-rutoken-plugin/
COPY adapter_rutoken_plugin*.xpi /usr/lib/firefox-esr/distribution/extensions/rutokenplugin@rutoken.ru.xpi

CMD ["bash"]

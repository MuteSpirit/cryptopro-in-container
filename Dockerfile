# 2026 March

# From https://support.cryptopro.ru/index.php?/Knowledgebase/Article/View/390/0/rbot-s-kriptopro-csp-v-linux-n-primere-debian-11
#  Debian 11 has been tested by CryptoPRO CSP 5.0 producer at 2022 year
#
# According to page https://cryptopro.ru/products/csp/compare
#   not all Debian versions are supported by different Crypto Pro CSP 5.0 versions 
#
# Next trouble has been met: 
#   CryptoPRO docker based on Debian 13 with pcscd 2.3.3-1 on host OS Ubuntu 22.04 with pcscd 2.0.3-1build1
#   PSCSD client in container tried to use newer protocol version and PSCSD server on host rejected it's requests.
#   So Debian Bookworm has been chosen.
FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="${PATH}:/opt/cprocsp/bin/amd64/"

# Yandex APT mirror is used as more available and fast
COPY files/debian-bookworm-yandex-mirror.sources /etc/apt/sources.list.d/debian.sources

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
      libccid \
      libpcsclite1 \
      pcscd \
      pcsc-tools \
      opensc \
      libgtk2.0-0 \
      libcanberra-gtk3-module \
      libcanberra-gtk3-0 \
      libsm6 \
      firefox-esr \
      locales \
      libpci-dev \
      whiptail \
      # For Firefox plugins XPI files downloading
      wget \
      # Some modern CA certs are unknown by Debian Bookworm base docker image. So install latest ones
      ca-certificates \
      # Firefox plugins install script dependencies:
      unzip \
      jq && \
    apt-get --yes clean

# CryptoPRO distro
# Download it manually
# Jump to download page from this one https://www.cryptopro.ru/fns_experiment
ADD linux-amd64_deb.tgz /cryptopro

# Rutoken distro
# Download it manually from https://www.rutoken.ru/support/download/pkcs/#linux
#   Reason: direct download link is depend on product version, e.g.
#     https://download.rutoken.ru/Rutoken/PKCS11Lib/2.18.4.0/Linux/x64/librtpkcs11ecp_2.18.4.0-1_amd64.deb
COPY librtpkcs11ecp*amd64.deb /cryptopro

# Rutoken Plugin
# Download it manually from https://www.rutoken.ru/support/download/get/rtPlugin-deb-x64.html
#   Reason: download link changes after new version release
COPY libnpRutokenPlugin_*_amd64.deb /cryptopro

# Rutoken Connect
# Download it manually from https://www.rutoken.ru/support/download/get/rtconnect-x64-deb.html
#   Reason: direct download link is depend on product version, e.g.
#     https://download.rutoken.ru/Rutoken_Connect/6.2.2/Linux/x64/rtconnect-6.2.2-1_amd64.deb
COPY rtconnect*_amd64.deb /cryptopro

# CryptoPRO browser plugin
# Download it manually from https://cryptopro.ru/products/cades/plugin
#   Reason: web site allows to get file only after fill authentication form
COPY cades-linux-amd64.tar.gz /cryptopro

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
      ca-certificates && \
    apt-get --yes clean

# Plugin to work with Gosuslugi govenment web portal
# Download page: https://ds-plugin.gosuslugi.ru/plugin/upload/Index.spr
RUN wget -O /cryptopro/IFCPlugin-x86_64.deb https://ds-plugin.gosuslugi.ru/plugin/upload/assets/distrib/IFCPlugin-x86_64.deb

RUN \
    cd /cryptopro/linux-amd64_deb && \
    ./install.sh cprocsp-rdr-pcsc cprocsp-rdr-rutoken cprocsp-rdr-cryptoki lsb-cprocsp-pkcs11 && \
    dpkg -i /cryptopro/librtpkcs11ecp_*_amd64.deb && \
    dpkg -i /cryptopro/IFCPlugin-x86_64.deb && \
    dpkg -i /cryptopro/rtconnect*_amd64.deb && \
    dpkg -i /cryptopro/libnpRutokenPlugin_*_amd64.deb && \
    dpkg -i /cryptopro/linux-amd64_deb/cprocsp-rdr-gui-gtk*amd64.deb && \
    dpkg -i /cryptopro/linux-amd64_deb/cprocsp-cptools-gtk*amd64.deb && \
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

# Firefox browser has been chosen because:
# * ChromiumGost had no updates for a long time
# * Yandex Browser for Corporates has version for Windows only
# * Firefox is in list of supported browsers by nalog.ru and gosuslugi.ru

RUN apt-get update && \
    apt-get install -y \
      jq

COPY files/install_firefox_addon.sh /cryptopro/

ENV FIREFOX_EXTENSIONS_DIR="/usr/lib/firefox-esr/distribution/extensions"
RUN mkdir -p "$FIREFOX_EXTENSIONS_DIR"

# CryptoPRO Firefox browser plugin
# Download page: https://www.cryptopro.ru/sites/default/files/products/cades/extensions/firefox_cryptopro_extension_latest.xpi
RUN wget -O /cryptopro/firefox_cryptopro_extension_latest.xpi \
      https://www.cryptopro.ru/sites/default/files/products/cades/extensions/firefox_cryptopro_extension_latest.xpi && \
    /cryptopro/install_firefox_addon.sh /cryptopro/firefox_cryptopro_extension_latest.xpi "$FIREFOX_EXTENSIONS_DIR"

# Rutoken Connect Firefox browser plugin
RUN wget -O /cryptopro/RutokenConnect.xpi \
      http://download.rutoken.ru/Rutoken_Connect/extension/Current/RutokenConnect.xpi && \
    /cryptopro/install_firefox_addon.sh /cryptopro/RutokenConnect.xpi "$FIREFOX_EXTENSIONS_DIR"

# Rutoken Plugin Firefox browser plugin 
# Download it manually from https://addons.mozilla.org/ru/firefox/addon/adapter-rutoken-plugin/
#   Reason: direct download link is depend on product version, e.g.
#     https://addons.mozilla.org/firefox/downloads/file/3450175/adapter_rutoken_plugin-1.0.5.0.xpi
COPY adapter_rutoken_plugin*.xpi /cryptopro/
RUN /cryptopro/install_firefox_addon.sh /cryptopro/adapter_rutoken_plugin*.xpi "$FIREFOX_EXTENSIONS_DIR"

# Gosuslugi Firefox browser plugin
# Download it manually from https://ds-plugin.gosuslugi.ru/plugin/upload/Index.spr
#   Reason: direct download link is depend on product version, e.g.
#     https://ds-plugin.gosuslugi.ru/plugin/upload/assets/distrib/addon-1.2.8-fx.xpi
COPY addon*.xpi /cryptopro/
RUN /cryptopro/install_firefox_addon.sh /cryptopro/addon*.xpi "$FIREFOX_EXTENSIONS_DIR"

COPY files/entrypoint.sh /cryptopro/entrypoint.sh
ENTRYPOINT ["/cryptopro/entrypoint.sh"]

CMD ["/usr/bin/firefox --browser --new-tab https://lkip2.nalog.ru/lk#/rutoken-gost --new-tab https://www.cryptopro.ru/sites/default/files/products/cades/demopage/cades_bes_sample.html --new-tab https://gosuslugi.ru"]

# 2026 Oct

# TODO: delete all downloaded and already installed DEB packages

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
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="${PATH}:/opt/cprocsp/bin/amd64/"

# Yandex APT mirror is used as more available and fast
COPY files/debian-bookworm-yandex-mirror.sources /etc/apt/sources.list.d/debian.sources

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
      # Some modern CA certs are unknown by Debian Bookworm base docker image. So install latest ones
      ca-certificates \
      libccid \
      libpcsclite1 \
      pcscd \
      pcsc-tools \
      opensc \
      libgtk2.0-0 \
      libcanberra-gtk3-module \
      libcanberra-gtk3-0 \
      libsm6 \
      locales \
      libpci-dev \
      whiptail \
      # For Chromium-Gost DEB downloading
      wget \
      curl \
      # For parsing GitHub releases API response
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

# Plugin to work with Gosuslugi govenment web portal
# Download page: https://ds-plugin.gosuslugi.ru/plugin/upload/Index.spr
RUN wget -O /cryptopro/IFCPlugin-x86_64.deb https://ds-plugin.gosuslugi.ru/plugin/upload/assets/distrib/IFCPlugin-x86_64.deb

RUN \
    cd /cryptopro && \
    tar xf cades-linux-amd64.tar.gz && \
    \
    cd /cryptopro/linux-amd64_deb && \
    ./install.sh cprocsp-rdr-pcsc cprocsp-rdr-rutoken cprocsp-rdr-cryptoki lsb-cprocsp-pkcs11 && \
    \
    dpkg -i /cryptopro/linux-amd64_deb/cprocsp-rdr-gui-gtk*amd64.deb \
            /cryptopro/linux-amd64_deb/cprocsp-cptools-gtk*amd64.deb \
            /cryptopro/linux-amd64_deb/cprocsp-rdr-pcsc*amd64.deb \
            /cryptopro/linux-amd64_deb/cprocsp-rdr-rutoken*amd64.deb \
            /cryptopro/linux-amd64_deb/cprocsp-rdr-cryptoki*amd64.deb \
            /cryptopro/linux-amd64_deb/lsb-cprocsp-import-ca-certs*all.deb \
            /cryptopro/linux-amd64_deb/cprocsp-pki-phpcades*all.deb \
            /cryptopro/librtpkcs11ecp_*_amd64.deb \
            /cryptopro/IFCPlugin-x86_64.deb \
            /cryptopro/rtconnect*_amd64.deb \
            /cryptopro/libnpRutokenPlugin_*_amd64.deb \
            /cryptopro/cades-linux-amd64/cprocsp-pki*.deb && \
    \
    rm -rf /cryptopro/linux-amd64_deb \
           /cryptopro/cades-linux-amd64 \
           /cryptopro/*.deb \
           /cryptopro/*.tar.gz

RUN sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && update-locale LANG=ru_RU.UTF-8 && \
    ln -snf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
    echo Europe/Moscow > /etc/timezone && \
    echo "export NO_AT_BRIDGE=1" >> /root/.bashrc && \
    echo "alias ll='ls -alFh'" >> /root/.bashrc

ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

#
# Russian governmental root certificates has been revoked by international certificate centers.
# Then has been generated as isolated certificate chain.
# Therefore they must be added manually.
# Following Mincifry manual:
#   https://www.gosuslugi.ru/landing/crt_linux
#
RUN wget -O /usr/local/share/ca-certificates/Russian_Trusted_Root_CA.crt \
        https://gu-st.ru/content/downloads/Russian_Trusted_Root_CA.cer && \
    wget -O /usr/local/share/ca-certificates/Russian_Trusted_Sub_CA.crt \
        https://gu-st.ru/content/downloads/Russian_Trusted_Sub_CA.cer && \
    wget -O /usr/local/share/ca-certificates/Russian_Trusted_Sub_CA_2024.cer \
        https://gu-st.ru/content/downloads/Russian_Trusted_Sub_CA_2024.cer && \
    update-ca-certificates

COPY files/entrypoint.sh /cryptopro/entrypoint.sh
ENTRYPOINT ["/cryptopro/entrypoint.sh"]

# Chromium-Gost has been chosen because:
# * Installation new RU Mincifry certificates is non trivial for Firefox in batch mode. Without that
#   certificates the most RU governmental web-sites treated as non-trusted by Firefox
# * Chromium-Gost contains that certificates by default
# * Chromium-Gost has built-in CryptoPro CAdES and Gosuslugi extensions.
# * Yandex Browser for Corporates has version for Windows only
#
# Rutoken extensions are installed from Chrome Web Store by force-install policy.
# Native messaging hosts are registered by the vendor DEB packages in
# /etc/chromium/native-messaging-hosts.
RUN cd /cryptopro && \
    wget -O chromium-gost.deb $(wget -O- https://api.github.com/repos/deemru/Chromium-Gost/releases/latest | jq '.assets[].browser_download_url' | tr -d '"' | grep '.*amd64.*.deb' | head -n 1) && \
    dpkg -i ./chromium-gost.deb; \
    apt -y -f install && \
    rm ./chromium-gost.deb

# Force-installed extensions from Chrome Web Store.
# ExtensionInstallForcelist elements correspond to the Rutoken native packages:
#   acbchkahfmndkenefkcklofjmipghjjp - Rutoken Connect adapter (rtconnect*_amd64.deb)
#   ohedcglhbbfdgaogjhcclacoccbagkjg - Rutoken Plugin adapter (libnpRutokenPlugin_*_amd64.deb)
# CryptoPro CAdES and Gosuslugi (Gosplugin) extensions are not listed here:
# they are provided by Chromium-Gost built-ins and the Gosplugin DEB installer.
RUN mkdir -p /etc/chromium/policies/managed && \
    echo '{"ExtensionInstallForcelist":["acbchkahfmndkenefkcklofjmipghjjp","ohedcglhbbfdgaogjhcclacoccbagkjg"]}' \
      > /etc/chromium/policies/managed/cryptopro.json

RUN apt-get install --yes --no-install-recommends \
        unzip && \
    apt-get --yes clean && \
    cd /cryptopro && \
    wget https://gu-st.ru/content/Gosplugin/Gosplugin_Linux-Debian_Installer.deb.zip && \
    unzip Gosplugin_Linux-Debian_Installer.deb.zip && \
    rm Gosplugin_Linux-Debian_Installer.deb.zip && \
    bash ./Gosplugin_Linux-Debian_Installer.deb.sh && \
    rm ./Gosplugin_Linux-Debian_Installer.deb.sh

CMD ["/usr/bin/chromium-gost-stable", "--new-window", "https://lkip2.nalog.ru/lk#/rutoken-gost", "https://www.cryptopro.ru/sites/default/files/products/cades/demopage/cades_bes_sample.html", "https://gosuslugi.ru"]

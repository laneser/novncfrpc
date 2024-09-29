FROM theasp/novnc

RUN set -ex; \
    apt-get update; \
    apt-get install -y \
    vim \
    expect \
    sudo \
    openssh-server \
    fonts-arphic-ukai \
    fonts-arphic-uming \
    python3-pip \
    python3-tk; \
    mkdir /run/sshd; \
    chmod 0755 /run/sshd; \
    wget https://github.com/fatedier/frp/releases/download/v0.60.0/frp_0.60.0_linux_amd64.tar.gz; \
    tar -zxvf frp_0.60.0_linux_amd64.tar.gz; \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; \
    dpkg -i google-chrome-stable_current_amd64.deb || apt-get install -y -f; \
    rm /frp_0.60.0_linux_amd64.tar.gz; \
    rm /google-chrome-stable_current_amd64.deb;

ADD ./requirements.txt /app/requirements.txt
RUN pip3 install -r /app/requirements.txt

EXPOSE 8080
EXPOSE 22

ENV VNCPASSWORD=rootpassword
ENV FRPC_PSWD="token"
ENV FRPC_SERVER="frpcserver"
ENV FRPC_SERVERPORT="60000"
ENV FRPC_SSHPORT="60009"
ENV FRPC_NOVNCPORT="60019"
ENV FRPC_SSHNAME="SSH"
ENV FRPC_NOVNCNAME="NOVNC"
ENV TAR_PSWD="password"

RUN rm /etc/localtime; \
    ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime; \
    dpkg-reconfigure -f nointeractive tzdata; \
    mv /frp_0.60.0_linux_amd64 /app/frp; \
    useradd -m -d /home/novnc novnc; \
    chsh -s /bin/bash novnc; \
    usermod -aG sudo novnc; \
    echo 'export PATH=$PATH:/opt/google/chrome' >> /etc/profile; \
    echo "export DISPLAY=':0.0'" >> /etc/profile; \
    echo "novnc ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config; \
    sed -i 's/command=x11vnc -forever -shared/command=x11vnc -forever -shared -usepw/' /app/conf.d/x11vnc.conf; \
    sed -i 's/command=xterm/command=xterm -e su - novnc/' /app/conf.d/xterm.conf; \
    sed -i 's/exec supervisord -c \/app\/supervisord.conf//' /app/entrypoint.sh; \
    echo "[program:sshd]" > /app/conf.d/sshd.conf; \
    echo "command=/usr/sbin/sshd -D" >> /app/conf.d/sshd.conf; \
    echo "autorestart=true" >> /app/conf.d/sshd.conf; \
    echo "[program:frpc]" > /app/conf.d/frpc.conf; \
    echo "command=/app/frp/frpc -c /app/frp/frpc.toml" >> /app/conf.d/frpc.conf; \
    echo "autorestart=true" >> /app/conf.d/frpc.conf; \
    echo "echo \"novnc:\$VNCPASSWORD\" | sudo chpasswd "  >> /app/entrypoint.sh; \
    echo "expect -c \""  >> /app/entrypoint.sh; \
    echo "spawn sudo x11vnc -storepasswd" >> /app/entrypoint.sh; \
    echo "expect \\\"Enter VNC password:\\\"" >> /app/entrypoint.sh; \
    echo "send \\\"\$VNCPASSWORD\\\\r\\\"" >> /app/entrypoint.sh; \
    echo "expect \\\"Verify password:\\\"" >> /app/entrypoint.sh; \
    echo "send \\\"\$VNCPASSWORD\\\r\\\"" >> /app/entrypoint.sh; \
    echo "expect \\\"Write password to \\\"" >> /app/entrypoint.sh; \
    echo "send \\\"y\\\\r\\\"" >> /app/entrypoint.sh; \
    echo "expect eof" >> /app/entrypoint.sh; \
    echo "\"" >> /app/entrypoint.sh; \
    echo "if [ \"\$FRPC_SSHNAME\" == \"SSH\" ]; then " >> /app/entrypoint.sh; \
    echo "  export FRPC_SSHNAME=\${HOSTNAME}_SSH;" >> /app/entrypoint.sh; \
    echo "fi" >> /app/entrypoint.sh; \
    echo "if [ \"\$FRPC_NOVNCNAME\" == \"NOVNC\" ]; then " >> /app/entrypoint.sh; \
    echo "  export FRPC_NOVNCNAME=\${HOSTNAME}_NOVNC;" >> /app/entrypoint.sh; \
    echo "fi" >> /app/entrypoint.sh; \
    echo "echo \"serverAddr = \\\"\$FRPC_SERVER\\\"\" > /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"serverPort = \$FRPC_SERVERPORT\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"auth.method = \\\"token\\\"\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"auth.token = \\\"\$FRPC_PSWD\\\"\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"log.to = \\\"/frpc.log\\\"\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"[[proxies]]\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"name = \\\"\$FRPC_SSHNAME\\\"\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"type = \\\"tcp\\\"\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"localIP = \\\"127.0.0.1\\\"\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"localPort = 22\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"remotePort = \$FRPC_SSHPORT\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"[[proxies]]\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"name = \\\"\$FRPC_NOVNCNAME\\\"\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"type = \\\"tcp\\\"\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"localIP = \\\"127.0.0.1\\\"\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"localPort = 8080\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "echo \"remotePort = \$FRPC_NOVNCPORT\" >> /app/frp/frpc.toml" >> /app/entrypoint.sh; \
    echo "" >> /app/entrypoint.sh; \
	echo "gpg --batch --yes --passphrase \$TAR_PSWD --output /job.tgz -d /job.tgz.gpg || true" >> /app/entrypoint.sh; \
	echo "tar -zxvf /job.tgz -C /home/novnc || true" >> /app/entrypoint.sh; \
	echo "rm /job.tgz || true" >> /app/entrypoint.sh; \
	echo "rm /job.tgz.gpg || true" >> /app/entrypoint.sh; \
	echo "chown -R novnc:novnc /home/novnc" >> /app/entrypoint.sh; \
    echo "exec supervisord -c /app/supervisord.conf" >> /app/entrypoint.sh;

ADD ./job.tgz.gpg /
RUN chown -R novnc:novnc /home/novnc
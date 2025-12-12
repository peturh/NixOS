FROM debian:bullseye-slim
RUN apt-get update && \
apt-get install -y \
openjdk-11-jdk \
icedtea-netx \
x11vnc \
xvfb \
fluxbox \
libxrender1 \
libxtst6 \
libxi6 \
libxext6 \
libx11-6 \
libxrandr2 \
libxcursor1 \
libxinerama1 \
libxfixes3 \
libfreetype6 \
fontconfig \
fonts-dejavu \
&& rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY vaka-Brf_Brita_6.jnlp /app/
RUN mkdir -p /root/.vnc && \
x11vnc -storepasswd porttelefon /root/.vnc/passwd
RUN echo '#!/bin/bash\n\
Xvfb :99 -screen 0 1280x720x24 -ac +extension GLX +render -noreset &\n\
XVFB_PID=$!\n\
export DISPLAY=:99\n\
sleep 2\n\
fluxbox >/dev/null 2>&1 &\n\
sleep 1\n\
x11vnc -display :99 -forever -rfbauth /root/.vnc/passwd -quiet -listen 0.0.0.0 -bg\n\
sleep 2\n\
javaws /app/vaka-Brf_Brita_6.jnlp\n\
wait $XVFB_PID' > /app/start.sh && chmod +x /app/start.sh
EXPOSE 5900
CMD ["/app/start.sh"]


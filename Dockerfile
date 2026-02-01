# Usamos Alpine por ser ligero y seguro
FROM alpine:3.19

# Definimos una versión ESPECÍFICA para evitar roturas inesperadas en el futuro.
# Puedes consultar la última en pkgs.tailscale.com
ENV TAILSCALE_VERSION="1.60.0" 
ENV TAILSCALE_HOSTNAME="railway-custom-node"

WORKDIR /app

# Copiamos el script de inicio
COPY start.sh /app/start.sh

# Instalación optimizada en una sola capa para reducir tamaño de imagen
RUN apk add --no-cache ca-certificates iptables ip6tables && \
    wget "https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_amd64.tgz" && \
    tar xzf "tailscale_${TAILSCALE_VERSION}_amd64.tgz" --strip-components=1 && \
    rm "tailscale_${TAILSCALE_VERSION}_amd64.tgz" && \
    mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale && \
    chmod +x /app/start.sh

# Documentamos que este contenedor necesita estos puertos (opcional, buena práctica)
EXPOSE 1055

CMD ["/app/start.sh"]

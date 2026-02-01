#!/bin/sh

echo "🚀 Iniciando Tailscale en modo Userspace..."

# 1. Iniciar el demonio (tailscaled) en segundo plano
# --tun=userspace-networking: CRÍTICO para Railway (sin acceso al kernel)
# --state=mem: Usamos memoria para el estado si no tenemos persistencia, 
# o usamos el archivo si Railway te da un volumen.
./tailscaled \
  --state=/var/lib/tailscale/tailscaled.state \
  --socket=/var/run/tailscale/tailscaled.sock \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  &

# Guardamos el PID del demonio para matarlo si el contenedor se detiene
PID=$!

# 2. Esperar unos segundos a que el demonio arranque
sleep 5

# 3. Autenticarse y anunciar el nodo de salida
# El 'until' reintenta si falla la primera vez (común en arranques de red lentos)
echo "🔄 Intentando conectar a la red Tailscale..."
echo "📋 Argumentos adicionales: '${TAILSCALE_ADDITIONAL_ARGS}'"

# Verificación preventiva
if echo "${TAILSCALE_ADDITIONAL_ARGS}" | grep -q "\-tun"; then
    echo "⚠️ ERROR DETECTADO: Has incluido '--tun' en TAILSCALE_ADDITIONAL_ARGS."
    echo "   Por favor elimina '--tun' de tus variables de entorno. Este flag solo es para 'tailscaled' (el demonio), no para 'tailscale up'."
fi

until ./tailscale up \
  --authkey=${TAILSCALE_AUTHKEY} \
  --hostname=${TAILSCALE_HOSTNAME} \
  --advertise-exit-node \
  ${TAILSCALE_ADDITIONAL_ARGS}
do
    echo "⚠️ Fallo al conectar, reintentando en 5 segundos..."
    sleep 5
done

echo "✅ Conexión establecida. Nodo de salida activo."

# 4. Esperar al proceso del demonio en lugar de sleep infinity
# Esto permite que si tailscaled crashea, el contenedor se reinicie automáticamente.
wait $PID

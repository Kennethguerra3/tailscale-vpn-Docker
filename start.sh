#!/bin/sh

echo "🚀 Iniciando Tailscale en modo Userspace..."

# 1. Iniciar el demonio (tailscaled) en segundo plano
# --tun=userspace-networking: CRÍTICO para Railway (sin acceso al kernel)
# --outbound-http-proxy-listen: Agregado para paridad con el proyecto original
./tailscaled \
  --state=/var/lib/tailscale/tailscaled.state \
  --socket=/var/run/tailscale/tailscaled.sock \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --outbound-http-proxy-listen=localhost:1055 \
  &

# Guardamos el PID del demonio
PID=$!

# 2. Esperar unos segundos a que el demonio arranque
sleep 5

# 3. Limpieza automática de argumentos inválidos para 'tailscale up'
# Muchos usuarios copian flags de 'tailscaled' equivocadamente a las variables de 'tailscale up'
if echo "${TAILSCALE_ADDITIONAL_ARGS}" | grep -q "\-tun"; then
    echo "⚠️ ADVERTENCIA: Se detectó el flag '--tun' en TAILSCALE_ADDITIONAL_ARGS."
    echo "🔧 Corrigiendo automáticamente eliminando el flag prohibido..."
    TAILSCALE_ADDITIONAL_ARGS=$(echo "$TAILSCALE_ADDITIONAL_ARGS" | sed -E 's/--?tun(=[^ ]+)?//g')
fi

echo "🔄 Intentando conectar a la red Tailscale..."
echo "📋 Argumentos finales: '${TAILSCALE_ADDITIONAL_ARGS}'"

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

# 4. Mantener el contenedor vivo indefinidamente
# Usamos sleep infinity para evitar que el contenedor se detenga si tailscaled se reinicia o comporta raro.
sleep infinity


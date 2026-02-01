# Tailscale VPN en Docker (Userspace Networking)

Este proyecto crea un contenedor Docker ligero basado en Alpine Linux que ejecuta Tailscale. Está optimizado para entornos donde no se tiene acceso completo al Kernel del host (como Railway, Heroku, o contenedores sin privilegios), utilizando el modo `userspace-networking`.

> **Nota:** Este proyecto es una versión mejorada y modernizada de [Andrew-Bekhiet/railway_tailscale_vpn](https://github.com/Andrew-Bekhiet/railway_tailscale_vpn), optimizada con mejores prácticas de Docker y manejo de procesos.

## 🚀 Características

*   **Ultraligero:** Basado en Alpine Linux.
*   **Userspace Networking:** No requiere `/dev/net/tun` ni privilegios elevados de `NET_ADMIN` obligatoriamente (aunque ayudan).
*   **Exit Node:** Configurado automáticamente para funcionar como nodo de salida (`--advertise-exit-node`). Navega por internet a través de este contenedor.
*   **SOCKS5 Proxy:** Expone un proxy SOCKS5 en el puerto `1055` para enrutar tráfico selectivo.
*   **Auto-reconexión:** Script robusto que reintenta la conexión si falla y mantiene el contenedor vivo.

## 📋 Requisitos

1.  Una cuenta en [Tailscale](https://tailscale.com/).
2.  Una **Auth Key** de Tailscale (puede ser efímera o reutilizable). Puedes generarla en [Tailscale Admin Console > Settings > Keys](https://login.tailscale.com/admin/settings/keys).
    *   *Recomendación:* Usa una clave "Reusable" y etiquetada (ej. `tag:server`) para que las ACLs se apliquen automáticamente y el Key Expiry se pueda deshabilitar.

## 🛠️ Instalación y Uso

### Opción 1: Docker Compose (Recomendada)

He añadido un archivo `docker-compose.yml` para facilitar el despliegue.

1.  Crea un archivo `.env` en este directorio con tu clave:
    ```env
    TAILSCALE_AUTHKEY=tskey-auth-tu-clave-secreta-aqui
    ```

2.  Inicia el contenedor:
    ```bash
    docker-compose up -d
    ```

### Opción 2: Docker CLI Manual

1.  **Construir la imagen:**
    ```bash
    docker build -t mi-tailscale-vpn .
    ```

2.  **Ejecutar el contenedor:**
    ```bash
    docker run -d \
      --name tailscale-vpn \
      -e TAILSCALE_AUTHKEY=tskey-auth-xxxxx \
      -e TAILSCALE_HOSTNAME=mi-vpn-docker \
      -p 1055:1055 \
      -v tailscale_state:/var/lib/tailscale \
      mi-tailscale-vpn
    ```

## ⚙️ Configuración (Variables de Entorno)

| Variable | Descripción | Valor por defecto |
| :--- | :--- | :--- |
| `TAILSCALE_AUTHKEY` | **Requerido.** Tu clave de autenticación de Tailscale. | (Vacio) |
| `TAILSCALE_HOSTNAME` | Nombre del dispositivo en la red Tailscale. | `railway-custom-node` |
| `TAILSCALE_VERSION` | Versión de Tailscale a instalar. Usa `latest` para la última estable. | `latest` |
| `TAILSCALE_ADDITIONAL_ARGS` | Argumentos extra para el comando `tailscale up`. **No incluyas `--tun` aquí.** | (Vacio) |

## 🚑 Solución de Problemas Comunes

### 1. "No tengo internet al conectar"

Si Tailscale conecta pero no puedes navegar:

1. Ve al [Admin Panel de Tailscale](https://login.tailscale.com/admin/dns).
2. En **DNS**, agrega un "Global Nameserver" (ej. `8.8.8.8`).
3. Activa la opción **"Override local DNS"**.
4. Asegúrate que en la sección **Machines**, tu dispositivo de Railway tenga el "Exit Node" aprobado (Edit route settings > Use as exit node).

### 2. Reinicios constantes o Fallos de conexión

Revisa los logs. Si ves advertencias sobre `--tun`, limpia tu variable `TAILSCALE_ADDITIONAL_ARGS`. Si el contenedor se detiene solo, asegúrate de estar usando la última versión de este repo que incluye mejoras de estabilidad (`sleep infinity`).

## 💾 Persistencia

El contenedor está configurado para guardar el estado en `/var/lib/tailscale`.
*   **Si usas Docker Volumes:** El contenedor mantendrá su **Tailscale IP** y su identidad (Device ID) entre reinicios.
*   **Sin volúmenes:** Se registrará como un nuevo dispositivo cada vez que se reinicie el contenedor.

## 🔍 Detalles Técnicos y Mejoras Realizadas

Este proyecto ha sido revisado para incluir las siguientes mejores prácticas:

1.  **Manejo de PID:** El script `start.sh` captura el PID de `tailscaled` y usa `wait` en lugar de un bucle infinito, permitiendo que el contenedor se detenga correctamente si el proceso VPN falla.
2.  **Mecanismo de Reintento:** Bucle `until` para manejar fallos de red transitorios al arrancar.
3.  **Docker Compose:** Se incluye configuración estándar para orquestación sencilla.

## ☁️ Despliegue en Railway

Este proyecto está listo para Railway.
1. Haz fork de este repo o súbelo a GitHub.
2. Crea un nuevo proyecto en Railway desde el repo.
3. Añade la variable `TAILSCALE_AUTHKEY` en las variables del servicio en Railway.
4. (Opcional) Añade un volumen montado en `/var/lib/tailscale` si quieres persistencia de identidad.

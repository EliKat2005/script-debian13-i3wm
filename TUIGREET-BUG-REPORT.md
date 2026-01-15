# 🐛 Problema con tuigreet en Debian 13 Trixie

**Fecha**: 14 de enero de 2026  
**Versión Debian**: 13 (Trixie)  
**Paquetes afectados**: greetd 0.10.3-4, tuigreet 0.9.1-5

---

## 📋 Resumen Ejecutivo

**tuigreet NO funciona en Debian 13** debido a un bug en la librería crossterm al interactuar con el TTY a través de greetd.

---

## 🔴 Error Exacto

### 1. Error de Runtime (tuigreet)
```
thread 'tokio-runtime-worker' panicked at /usr/share/cargo/registry/crossterm-0.27.0/src/event/read.rs:39:30:
reader source not set
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

**Ubicación**: `/usr/share/cargo/registry/crossterm-0.27.0/src/event/read.rs:39:30`  
**Causa**: crossterm (librería de terminal Rust) no puede inicializar el reader source desde el TTY

### 2. Error de Configuración (greetd)
```
ene 14 21:03:32 debian13 greetd[682]: error: configured default session user 'greeter' not found
```

**Causa**: El paquete greetd NO crea automáticamente el usuario `greeter` necesario para ejecutar el greeter.

### 3. Error de Systemd
```
ene 14 21:03:44 debian13 systemd[1]: greetd.service: Start request repeated too quickly.
ene 14 21:03:44 debian13 systemd[1]: greetd.service: Failed with result 'start-limit-hit'.
```

**Causa**: greetd reinicia automáticamente tras cada crash de tuigreet, hasta alcanzar el límite de reintentos (5 veces).

---

## 🔍 Análisis Técnico

### Secuencia de Fallos

1. **Systemd inicia greetd**
   ```
   systemd[1]: Started greetd.service - Greeter daemon
   ```

2. **greetd intenta iniciar tuigreet**
   ```
   greetd[699]: spawning tuigreet on VT 1
   ```

3. **tuigreet crashea inmediatamente**
   ```
   tuigreet: panic en crossterm::event::read.rs:39
   ```

4. **greetd detecta el crash**
   ```
   greetd.service: Deactivated successfully
   ```

5. **systemd reintenta (5 veces)**
   ```
   greetd.service: Scheduled restart job, restart counter is at 1
   greetd.service: Scheduled restart job, restart counter is at 2
   ...
   greetd.service: Scheduled restart job, restart counter is at 5
   ```

6. **systemd se rinde**
   ```
   greetd.service: Failed with result 'start-limit-hit'
   ```

7. **Sistema queda en TTY nativo**
   ```
   /sbin/agetty -o -- \u --noreset --noclear - linux
   ```

### Proceso Zombie Detectado

```bash
root  705  0.0  0.0  0  0  ?  Zs  21:11  0:00  [greetd] <defunct>
```

Indica que greetd spawneó un proceso hijo (tuigreet) que crasheó y quedó como zombie.

---

## 🧪 Intentos de Solución

### Intento 1: Crear usuario greeter
```bash
useradd -r -s /usr/sbin/nologin -d /var/lib/greetd -M greeter
```
**Resultado**: ❌ Resolvió el error de "user not found" pero tuigreet seguía crasheando

### Intento 2: Cambiar a agreety (greeter de texto incluido con greetd)
```toml
[default_session]
command = "agreety --cmd i3"
user = "greeter"
```
**Resultado**: ❌ `agreety` no está disponible en el paquete greetd de Debian 13

### Intento 3: Configuración sin VT forzado
```toml
[terminal]
# Sin vt = 1

[default_session]
command = "tuigreet --cmd /usr/bin/i3"
```
**Resultado**: ❌ Misma falla de crossterm

### Intento 4: tuigreet standalone (fuera de greetd)
```bash
$ tuigreet --help
thread 'tokio-runtime-worker' panicked at crossterm-0.27.0/src/event/read.rs:39:30:
reader source not set
```
**Resultado**: ❌ tuigreet ni siquiera muestra la ayuda sin un TTY conectado

---

## 🎯 Causa Raíz

**crossterm 0.27.0** (dependencia de tuigreet) tiene un bug al inicializar el reader desde un TTY cuando es spawneado por otro proceso (greetd).

### Stack de Dependencias Problemático
```
greetd → tuigreet → crossterm 0.27.0 → terminal I/O
                                          ↑
                                    PANIC HERE
```

### Posibles Razones

1. **crossterm 0.27.0 es buggy** en esta configuración específica
2. **greetd no pasa el TTY correctamente** al proceso hijo
3. **Debian 13 usa una versión incompatible** de crossterm

---

## ✅ Solución Adoptada

**REVERTIR A LIGHTDM**

```bash
# Desinstalar greetd/tuigreet
apt purge greetd tuigreet

# Instalar lightdm
apt install lightdm lightdm-gtk-greeter
```

### Ventajas de lightdm
- ✅ Estable y probado en Debian
- ✅ Login gráfico GTK
- ✅ Sin crashes
- ✅ Amplia compatibilidad

### Desventajas de lightdm
- ❌ Más pesado (~80MB RAM vs ~15MB greetd)
- ❌ Login gráfico (no TUI minimalista)
- ❌ Demora 5 segundos vs <2s de tuigreet (cuando funciona)

---

## 📊 Comparación Final

| Aspecto | lightdm | greetd+tuigreet |
|---------|---------|-----------------|
| RAM | 80MB | 15MB |
| Estabilidad | ✅ 100% | ❌ Crashes |
| Velocidad | 5s | <2s (teoría) |
| Login | Gráfico GTK | TUI minimalista |
| Debian 13 | ✅ Funciona | ❌ Bugs |

---

## 🔮 Conclusión

**greetd + tuigreet NO es viable en Debian 13 Trixie** debido a bugs en crossterm 0.27.0 y problemas de gestión de VT.

**Recomendación**: Usar lightdm hasta que:
1. Debian actualice crossterm a una versión estable
2. tuigreet se actualice para resolver el bug
3. greetd mejore la gestión de TTY/VT

---

## 📚 Referencias

- **Bug original**: crossterm-0.27.0/src/event/read.rs:39 (reader source not set)
- **Paquete Debian greetd**: https://packages.debian.org/trixie/greetd
- **Paquete Debian tuigreet**: https://packages.debian.org/trixie/tuigreet
- **Repositorio tuigreet**: https://github.com/apognu/tuigreet
- **Sistema de prueba**: Debian 13 Trixie, kernel 6.12.63, AMD Athlon II X4

---

## ⚠️ Nota Final

Este documento fue creado tras **3 horas de debugging** en un sistema real. Los errores son reproducibles en Debian 13 Trixie con los paquetes de los repositorios oficiales.

**Fecha de resolución**: 14 de enero de 2026, 21:16 -05  
**Solución final**: Commit 17b2867 - Revertir a lightdm

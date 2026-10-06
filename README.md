# Cubanía app

App móvil (Flutter) para los alumnos de Cubanía. Consume la API v1 del backend
[`juanhm93/cubaniasc`](https://github.com/juanhm93/cubaniasc); el contrato está en
`docs/api/v1/openapi.yaml` de ese repo.

## Correr en local

1. Levanta el backend con `php artisan serve` (puerto 8000). El correo con el código
   llega al driver configurado en `MAIL_MAILER` (con `log`, búscalo en `storage/logs/laravel.log`).
2. En este repo:

   ```sh
   flutter pub get
   flutter run
   ```

Sin configuración, la app apunta a `http://10.0.2.2:8000/api/v1` en el emulador de
Android y a `http://localhost:8000/api/v1` en el simulador de iOS. Para otro servidor:

```sh
flutter run --dart-define=API_BASE_URL=https://cubania.purphura.com/api/v1
```

> Si usas Herd (`https://cubaniasc.test`), el emulador no resuelve ese dominio.
> Usa `php artisan serve` o pasa la IP de tu máquina en `API_BASE_URL`.

## Estructura

```
lib/
  core/        config, cliente HTTP (Dio), errores, almacenamiento seguro del token, tema
  features/
    auth/      login por código: datos, estado (Riverpod) y pantallas
    profile/   "Mi perfil"
```

- Estado con `flutter_riverpod` (sin generación de código).
- El token se guarda con `flutter_secure_storage` (Keychain / Keystore).
- Si la API responde 401 a una petición autenticada, la app vuelve al login.

## Calidad

```sh
flutter analyze
flutter test
```

CI (`.github/workflows/flutter.yml`) corre ambos en cada PR.

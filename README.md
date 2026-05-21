<img width="1024" height="1024" alt="undefined" src="https://github.com/user-attachments/assets/f701908d-955b-4218-bf56-7431430279de" />

---

<div align="center">

<h4> Proyecto formativo desarrollado por aprendices SENA </h4>

<h1> 

🏥 WALUD – Plataforma Digital de Servicios de Salud 

[![Estado](https://img.shields.io/badge/Estado-En%20desarrollo-yellow)](https://github.com/WebHealthWalud/WALUD-1.0)
[![Backend](https://img.shields.io/badge/Backend-Laravel%2011-red)](https://laravel.com)
[![Frontend](https://img.shields.io/badge/Frontend-Flutter%203.x-blue)](https://flutter.dev)
[![BD](https://img.shields.io/badge/Base%20de%20datos-MySQL%208-orange)](https://www.mysql.com)
[![Licencia](https://img.shields.io/badge/Licencia-Académica%20SENA-green)](#licencia)

</h1>

> 👩🏻‍💻👨🏻‍💻 **Equipo Walud**

| Integrante | Rol | GitHub |
|---|---|---|
| **Yeisson Romero** | Backend + Base de Datos | [@YeissonR21](https://github.com/YeissonR21) |
| **Sarah González** | Frontend + Documentación | [@Kata45](https://github.com/Kata45) |

</div>

---

## 📋 Descripción

Walud resuelve la dificultad de acceder a servicios de salud de forma presencial y desorganizada. Permite a pacientes agendar citas médicas en línea, consultar su historial clínico y realizar pagos digitales, mientras que los médicos pueden gestionar su agenda y el seguimiento de sus pacientes desde cualquier lugar.

### ¿Qué problema resuelve?
- Elimina las filas presenciales para agendar citas médicas
- Centraliza el historial clínico del paciente en un solo lugar
- Facilita la comunicación entre paciente y médico de forma digital
- Permite gestionar pagos de consultas de manera segura

---

## 🛠️ Tecnologías Utilizadas

| Capa | Tecnología |
|---|---|
| Lenguaje Backend | PHP 8.x |
| Framework Backend | Laravel 11 |
| Autenticación | Laravel Sanctum |
| Permisos | Spatie Laravel Permission |
| Lenguaje Frontend | Dart |
| Framework Frontend | Flutter 3.x (Flutter Web) |
| Base de datos | MySQL 8.x |
| Gestión de estado | Provider |
| HTTP Client | Dart http package |

---

## ✅ Requisitos Previos

Antes de ejecutar el proyecto asegúrate de tener instalado:

- **XAMPP**
- **PHP** >= 8.1
- **Composer** >= 2.x
- **Laravel CLI**
- **MySQL** >= 8.0
- **Flutter SDK** >= 3.x (`flutter --version` para verificar)
- **Dart SDK** (incluido con Flutter)
- **Git**

> ⚠️ **Importante con Flutter:** Si hay conflictos de versión al ejecutar, corre `flutter upgrade` para resolverlos.

---

## 📁 Estructura del Repositorio

```
walud/
├── Backend/
│   └── backendwalud/       # API REST en Laravel
│       ├── app/
│       ├── routes/
│       ├── database/
│       │   └── migrations/ # Migraciones de la BD
│       └── config/
├── Frontend/
│   └── frontendwalud/      # Aplicación Flutter Web
│       ├── lib/
│       │   ├── config/     # api_config.dart — URL del backend
│       │   ├── screens/
│       │   ├── widgets/
│       │   └── services/
├── README.md
├── .gitignore
└── .env.example
```

---

## 🌿 Ramas del Repositorio

| Rama | Propósito |
|---|---|
| `main` | Versión estable para producción |
| `develop` | Desarrollo general activo |
| `document` | Documentación técnica y planes de despliegue |
| `backend/*` | Desarrollo de funcionalidades backend |
| `frontend/*` | Desarrollo de funcionalidades frontend |
| `feature/*` | Nuevas funcionalidades |
| `fix/*` | Corrección de errores |

### Convención de commits
```
feat:     nueva funcionalidad
fix:      corrección de error
docs:     cambios de documentación
refactor: mejoras internas sin cambio de funcionalidad
db:       cambios en base de datos o migraciones
```

---

## ⚙️ Instalación y Configuración Local

### 1. Clonar el repositorio

```bash
git clone https://github.com/WebHealthWalud/WALUD-1.0.git
cd WALUD-1.0
```

### 2. Configurar el Backend (Laravel)

```bash
cd Backend/backendwalud
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed       # opcional: datos de prueba
php artisan storage:link
php artisan serve
```

El servidor backend quedará disponible en: `http://localhost:8000`

### 3. Configurar el Frontend (Flutter)

```bash
cd Frontend/frontendwalud
flutter pub get
flutter run -d chrome     # para ejecutar como Flutter Web
```

> 💡 Antes de ejecutar, verifica que la URL del backend en `lib/config/api_config.dart` apunte a `http://localhost:8000/api/`

---

## 🗄️ Base de Datos

La base de datos se gestiona mediante las **migraciones de Laravel**. No se requiere importar un archivo `.sql` manualmente.

```bash
# Crear todas las tablas
php artisan migrate

# Poblar con datos de prueba (si existen seeders)
php artisan db:seed
```

Asegúrate de configurar las variables `DB_*` en tu archivo `.env` antes de correr estos comandos.

---

## 🔑 Variables de Entorno

Crea un archivo `.env` en `Backend/backendwalud/` copiando `.env.example`:

```bash
cp .env.example .env
```

| Variable | Descripción |
|---|---|
| `APP_NAME` | Nombre de la aplicación |
| `APP_ENV` | Entorno: `local` o `production` |
| `APP_KEY` | Clave de cifrado (generar con `php artisan key:generate`) |
| `APP_DEBUG` | Modo debug: `true` en local, `false` en producción |
| `APP_URL` | URL base del backend |
| `DB_CONNECTION` | Tipo de BD: `mysql` |
| `DB_HOST` | Host de la base de datos |
| `DB_PORT` | Puerto (por defecto `3306`) |
| `DB_DATABASE` | Nombre de la base de datos |
| `DB_USERNAME` | Usuario de la base de datos |
| `DB_PASSWORD` | Contraseña de la base de datos |
| `SANCTUM_STATEFUL_DOMAINS` | Dominio del frontend (importante para CORS en producción) |

> 🔒 **Nunca subas el archivo `.env` con valores reales al repositorio.**

---

## 👤 Usuario de Prueba

> ⚠️ Solo disponible en entorno local con seeders ejecutados.
>
> 📌 Los datos del usuario de prueba se agregarán próximamente en esta sección.

---

## 🚀 Despliegue

WALUD está diseñado para desplegarse en dos plataformas complementarias:

| Componente | Plataforma | Descripción |
|---|---|---|
| **Backend Laravel + MySQL** | [Railway](https://railway.app) | Soporte nativo para Laravel con MySQL integrado como plugin. Conecta directo desde GitHub. |
| **Frontend Flutter Web** | [Firebase Hosting](https://firebase.google.com) | Optimizado para SPAs y archivos estáticos. Flutter Web genera `build/web` listo para desplegar. |
| **Almacenamiento de archivos** | Cloudinary *(recomendado)* | Railway no tiene almacenamiento persistente en plan gratuito. |

**Pasos generales:**
1. Configura las variables de entorno en Railway (ver punto 8 del plan de despliegue).
2. Conecta el repositorio desde GitHub en Railway.
3. Crea el plugin de MySQL en Railway y copia las credenciales.
4. Ejecuta `php artisan migrate --force` en el despliegue.
5. Compila el frontend con `flutter build web --release`.
6. Despliega la carpeta `build/web` en Firebase con `firebase deploy`.

---

## 📄 Plan de Despliegue Completo

El plan de despliegue técnico detallado del proyecto WALUD — incluyendo arquitectura, pasos de despliegue paso a paso, variables de entorno de producción, pruebas post-despliegue, riesgos y plan de reversa — se encuentra documentado en la rama **`document`**:

```
📁 Rama: document
📄 Archivo: PLAN_DESPLIEGUE_WALUD.docx
```

Para acceder al documento:
```bash
git checkout document
```
O consultarlo directamente en GitHub: [Ver rama document →](https://github.com/WebHealthWalud/WALUD-1.0/tree/document)

---

## 🖼️ Evidencias del Sistema

<img width="1600" height="589" alt="Landing Page" src="https://github.com/user-attachments/assets/c8a65285-73e6-4d73-a878-4c8936b0525b" />

---

<img width="1600" height="757" alt="Inicio de Sesión" src="https://github.com/user-attachments/assets/fe90fcc9-82f8-4a82-b6e3-e8419c3683e3" />

---

<img width="1600" height="766" alt="Página Principal" src="https://github.com/user-attachments/assets/57a950f7-8ab7-460f-ad28-0e0068fc45e4" />

---

## 📜 Licencia y Autoría

Proyecto formativo elaborado por aprendices del **Centro de Biotecnología Agropecuaria — CBA Mosquera, SENA**.  
Programa: Análisis y Desarrollo de Software · 2026.

##### © **2026** Creado por *EQUIPO WALUD* — Todos los derechos reservados.

---

<div align="center">

🔗 **Repositorio:** [https://github.com/WebHealthWalud/WALUD-1.0](https://github.com/WebHealthWalud/WALUD-1.0)

</div>


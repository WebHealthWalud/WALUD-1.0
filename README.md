<img width="1024" height="1024" alt="undefined" src="https://github.com/user-attachments/assets/f701908d-955b-4218-bf56-7431430279de" />

---

<div align="center">

<h4> Proyecto formativo desarrollado por aprendices SENA </h4>

<h1> 🏥 WALUD – Plataforma Digital de Servicios de Salud </h1>

> 👩🏻‍💻👨🏻‍💻 **Equipo Walud**
Walud una plataforma digital que permite a pacientes y médicos gestionar consultas médicas en línea, incluyendo agendamiento de citas, historial médico y pagos digitales.

</div>

---

## 📋 Descripción

Walud resuelve la dificultad de acceder a servicios de salud de forma presencial y desorganizada. Permite a pacientes agendar citas médicas en línea, consultar su historial clínico y realizar pagos digitales, mientras que los médicos pueden gestionar su agenda y el seguimiento de sus pacientes desde cualquier lugar.

---

# 🚀 Creación del Proyecto Base

## 📁 Estructura Inicial

```
walud/
├── frontend/      # Aplicación Flutter
├── backend/       # API Laravel
├── README.md
├── .gitignore
└── .env.example
```

---

## ⚙️ Configuración del Proyecto

### 🔽 Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/walud.git
cd walud
```

---

## 🖥️ Configuración Backend (Laravel)

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

### 🖥️ Funcionalidades Especiales 
```bash
php artisan storage:link
```

---

## 📱 Configuración Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

---

## 🔑 Archivo de Entorno

Ejemplo `.env.example`:

```
APP_NAME=Walud
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=walud
DB_USERNAME=root
DB_PASSWORD=
```

---

## 📦 Dependencias Principales

### Backend (Laravel)

* Laravel
* Laravel Sanctum
* Spatie Laravel Permission
* MySQL

### Frontend (Flutter)

* Flutter SDK
* HTTP package
* Provider / Gestión de estado

---

## 🛠️ Tecnologías Utilizadas

| Capa | Tecnología |
|------|------------|
| Lenguaje Backend | PHP |
| Framework Backend | Laravel |
| Lenguaje Frontend | Dart |
| Framework Frontend | Flutter |
| Base de datos | MySQL |
| Autenticación | Laravel Sanctum |
| Permisos | Spatie Laravel Permission |
| Gestión de estado | Provider |

---

## ✅ Requisitos Previos

Antes de ejecutar el proyecto asegúrate de tener instalado:

- **PHP** >= 8.1
- **Composer**
- **Laravel CLI**
- **MySQL** >= 8.0
- **Flutter SDK** >= 3.x
- **Dart SDK** (incluido con Flutter)
- **Git**

---

# 🌿 Estructura del Repositorio

## 📛 Nombre del repositorio

**Walud - 1.0**

---

## 🌱 Ramas principales

* `main` → versión estable
* `develop` → desarrollo general
* `document` → cambios de forma aislada
* `feature/*` → nuevas funcionalidades
* `fix/*` → corrección de errores
* `backend/*` → desarrollo por rol
* `frontend/*` → desarrollo por rol

---

## 🧾 Convención de nombres

* Ramas:
  `feature/nombre-funcionalidad`
  `fix/nombre-error`

* Commits:

  * `feat:` nueva funcionalidad
  * `fix:` corrección
  * `docs:` documentación
  * `refactor:` mejoras internas

---

## 📂 Organización de carpetas

```
walud/
├── backend/
│   ├── app/
│   ├── routes/
│   ├── database/
│   └── config/
│
├── frontend/
│   ├── lib/
│   ├── screens/
│   ├── widgets/
│   └── services/
```

---

## 🗄️ Base de Datos

Para crear la base de datos ejecuta las migraciones de Laravel:

```bash
cd backend
php artisan migrate
```

Si el proyecto incluye datos de prueba (seeders):

```bash
php artisan db:seed
```

Asegúrate de haber configurado correctamente las variables `DB_*` en tu archivo `.env` antes de correr estos comandos.

---

## 🔐 Variables de Entorno

| Variable | Descripción |
|----------|-------------|
| `APP_NAME` | Nombre de la aplicación |
| `APP_ENV` | Entorno (`local`, `production`) |
| `APP_KEY` | Clave de cifrado de Laravel (generada con `artisan key:generate`) |
| `APP_DEBUG` | Modo debug (`true` / `false`) |
| `APP_URL` | URL base del backend |
| `DB_CONNECTION` | Tipo de base de datos (`mysql`) |
| `DB_HOST` | Host de la base de datos |
| `DB_PORT` | Puerto de conexión (por defecto `3306`) |
| `DB_DATABASE` | Nombre de la base de datos |
| `DB_USERNAME` | Usuario de la base de datos |
| `DB_PASSWORD` | Contraseña de la base de datos |

---

## 🧪 Usuario de Prueba

> ⚠️ Solo disponible en entorno local con seeders ejecutados.

> 📌 Próximamente se agragará los datos correspondientes

---

## 🚀 Despliegue

El despliegue del proyecto está planificado en las siguientes plataformas:

- **Backend (Laravel):** [Railway](https://railway.app) / [Render](https://render.com)
- **Base de datos:** PlanetScale o MySQL en el mismo servicio
- **Frontend (Flutter Web):** Firebase Hosting / Netlify

**Pasos generales:**
1. Configura las variables de entorno en la plataforma elegida.
2. Conecta el repositorio de GitHub.
3. Ejecuta `php artisan migrate` en el entorno de producción.
4. Compila el frontend con `flutter build web` y despliega la carpeta `build/web`.

---

## 🖼️ Evidencias

---

<img width="1600" height="589" alt="Landing" src="https://github.com/user-attachments/assets/c8a65285-73e6-4d73-a878-4c8936b0525b" />

---

<img width="1600" height="757" alt="Inicio de Sesión" src="https://github.com/user-attachments/assets/fe90fcc9-82f8-4a82-b6e3-e8419c3683e3" />

---

<img width="1600" height="766" alt="Pagina Principal" src="https://github.com/user-attachments/assets/57a950f7-8ab7-460f-ad28-0e0068fc45e4" />

---

## 👥 Equipo de Desarrollo

* **👴 Yeisson Romero [YeissonR21](https://github.com/YeissonR21)** → Backend + Base de Datos
* **🐈‍⬛ Sarah González [Kata45](https://github.com/Kata45)** → Frontend + Base de Datos + Documentación

---

# 🔗 Enlace del Repositorio

👉 [https://github.com/WebHealthWalud/WALUD-1.0](https://github.com/WebHealthWalud/WALUD-1.0)

---
##### © **2026** Creado por *EQUIPO WALUD* — Todos los derechos reservados.
---

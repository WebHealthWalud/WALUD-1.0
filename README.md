<img width="1024" height="1024" alt="undefined" src="https://github.com/user-attachments/assets/f701908d-955b-4218-bf56-7431430279de" />

---

<div align="center">

<h1> 🏥 WALUD – Plataforma Digital de Servicios de Salud </h1>

> 👩🏻‍💻👨🏻‍💻 **Equipo Walud**

Walud es una plataforma digital que permite a pacientes y médicos gestionar consultas médicas en línea, incluyendo agendamiento de citas, historial médico y pagos digitales.

</div>

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

# 🌿 Estructura del Repositorio

## 📛 Nombre del repositorio

**Walud - 1.0**

---

## 🌱 Ramas principales

* `main` → versión estable
* `develop` → desarrollo general
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

## 👥 Equipo de Desarrollo

* **Yeisson Romero** → Backend + Base de Datos
* **Sarah González** → Frontend + Base de Datos + Documentación

---

# 🔗 Enlace del Repositorio

👉 [https://github.com/WebHealthWalud/WALUD-1.0](https://github.com/WebHealthWalud/WALUD-1.0)

---
##### © **2026** Creado por *EQUIPO WALUD* — Todos los derechos reservados.
---


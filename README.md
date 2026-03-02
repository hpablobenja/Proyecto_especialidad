# Nombre del Proyecto ## Descripción Breve explicación del problema que resuelve el sistema y qué hace el producto. 

Desarrollo de aplicación móvil Full Stack orientado a la gestión de microaprendizaje docente en educación secundaria basada en arquitectura limpia

## Objetivo general - (1 línea) Qué se busca lograr con este proyecto. 

Desarrollar una aplicación móvil basada en arquitectura limpia (Flutter y Firebase) que gestione microaprendizajes. permitiendo a maestros de educación de educación secundaria en Bolivia acceder a contenidos personalizados y fáciles de usar, adaptados a sus necesidades pedagógicas y tecnológicas.

## Objetivos específicos (medibles) 
●	Diseñar la arquitectura de software basada en los principios de Clean Architecture, definiendo la separación de capas (Data, Domain, Presentation).
●	Implementar la interfaz de usuario mediante el framework Flutter, aplicando patrones de diseño responsivo.
●	Desarrollar el backend y la persistencia de datos mediante los servicios de Firebase.

## Alcance (qué incluye / qué NO incluye) 

Incluye: - CRUD de tareas - Conexión a base de datos 

- Gestión Integral (CRUD) de Tareas y Módulos: Implementación completa de las operaciones de creación, lectura, actualización y eliminación de las unidades de aprendizaje y tareas asignadas al docente.

- Conexión a Base de Datos en Tiempo Real: Integración con Cloud Firestore para la persistencia de datos, permitiendo que el progreso del docente se sincronice instantáneamente entre dispositivos.

- Autenticación de Usuarios: Registro e inicio de sesión seguro vinculado a la base de datos de usuarios.

- Visualización de Contenido Multimedia: Capacidad de listar y reproducir los recursos de video y lectura asociados a cada tarea.

No incluye (por ahora): - Notificaciones - Roles avanzados 

- Sistema de Notificaciones Push: Las alertas automáticas sobre nuevas tareas o recordatorios de estudio quedan fuera de esta fase inicial.

- Gestión de Roles Avanzados: El sistema operará bajo un esquema de usuario estándar (Docente), postergando la implementación de jerarquías complejas (Administradores de distrito, Supervisores o Editores de contenido) para versiones futuras.

- Modo Offline Total: Si bien se utiliza Firebase, la descarga masiva de videos para uso sin conexión no está contemplada en este entregable

## Stack tecnológico 
- Backend: Firebase 
- Base de datos: Firebase 
- Testing: Postman 
- Control de versiones: GitHub

## Arquitectura (resumen simple) 
Clean Architecture
Cliente (Frontend) → API (Backend) → Base de datos 

## Endpoints core (priorizados) 

1. Clonar repositorio git clone https://github.com/hpablobenja/Proyecto_especialidad
2. Instalar dependencias flutter pub get
3. Inicializar un emulador de celular
4. Verificar la configuaración flutter doctor
5. Ejecutar la aplicación flutter run

## Variables de entorno (ejemplo) 
apiKey: 'AIzaSyDpxY8-TjTrDaq_64zeLFfYdqn5HMek9fk',
appId: '1:109441503898:android:2aee8b5fa875ac0b5c0523',
messagingSenderId: '109441503898',
projectId: 'flutter-project-24297',
storageBucket: 'flutter-project-24297.firebasestorage.app'

## Equipo y roles - – Pablo Huañapaco 1: Backend – Pablo Huañapaco 2: Frontend - – Pablo Huañapaco: DevOps / QA
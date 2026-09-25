# Nombre del Proyecto 

Desarrollo de aplicación móvil Full Stack orientado a la gestión de microaprendizaje docente en educación secundaria basada en arquitectura limpia

## Descripción Breve explicación del problema que resuelve el sistema y qué hace el producto. 
El objeto de estudio de este proyecto es el proceso de gestión y distribución de microaprendizaje mediante mediante el desarrollo de una aplicación móvil Full Stack, orientado específicamente a la actualización pedagógica de docentes de educación secundaria. Este estudio se centra en el diseño e implementación de una infraestructura tecnológica desacoplada que supere las limitaciones de los sistemas de gestión de aprendizaje (LMS) tradicionales, como la rigidez operativa y la necesidad de conexión para el acceso al contenido. Se analiza cómo la integración de una arquitectura limpia (Clean Architecture) y el uso de servicios en la nube con capacidades de persistencia local facilitan una entrega de contenido granular; esto permite al usuario acceder a videos de las clases, cuestionarios de conocimientos y material de lectura descargable directamente en el dispositivo, logrando una solución eficiente y adaptable a la realidad tecnológica del magisterio boliviano.

## Objetivo general - Qué se busca lograr con este proyecto.. 

Desarrollar una aplicación móvil Full Stack basada en una arquitectura limpia (Clean Architecture) y prácticas de seguridad avanzada alineada a recomendaciones OWASP, que permita a los docentes de secundaria en Bolivia acceder a un modelo de gestión de microaprendizaje personalizado, facilitando la actualización de competencias pedagógicas mediante el consumo de contenidos granulares.

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

## Pruebas (Testing)

**Pruebas Unitarias (Capa de Dominio y Datos):**
Evaluación aislada de las reglas de negocio críticas sin depender de la interfaz de usuario ni de conexiones a internet. Utilizando el paquete flutter_test y la librería mockito (o mocktail), se simularon (mockearon) las respuestas del servidor para validar el comportamiento exacto de los Casos de Uso (ej. EvaluateQuizUseCase, SyncLocalDataToCloudUseCase).

**Pruebas de Componentes / Widget Tests (Capa de Presentación):**
Verificación del comportamiento visual de los componentes atómicos en Flutter. Se comprobó que los formularios mostraran errores ante datos inválidos, que el reproductor de YouTube se inicializara correctamente y que los botones de progreso reaccionaran a los cambios de estado emitidos por los Providers.

**Pruebas de Integración (Frontend - Backend):**
Pruebas de caja negra diseñadas para comprobar el flujo de comunicación real entre la aplicación móvil y los servicios de Google Cloud (Firebase). Se validó el inicio de sesión con tokens JWT, la correcta ejecución de las Security Rules en Firestore y la inserción atómica de los registros de avance de los cursos.

**Pruebas de Usabilidad y Aceptación (User Acceptance Testing - UAT):**
Evaluación empírica en un entorno controlado con una muestra representativa de docentes de educación regular (grupo de control). Su propósito fue medir el grado de fricción en la navegación, la legibilidad del contenido en pantallas móviles y la efectividad del modelo de microaprendizaje, utilizando escenarios de prueba específicos (ej. "Inscribirse a un curso y completar el primer cuestionario").

**Pruebas de Humo (Smoke Tests):** 
Verificaciones rápidas de las funcionalidades críticas para asegurar la estabilidad tras cada despliegue.

### Tipos de pruebas implementadas:

**Widget Tests**
- Renderizado básico de MaterialApp
- Interacción con botones
- Entrada de texto en TextFormField
- ThemeProvider functionality

**Provider Tests**
- AuthProvider: login, logout, manejo de errores
- ThemeProvider: cambio de tema, persistencia
- ConnectivityProvider: inicialización

**Login Screen Tests**
- Renderizado del formulario
- Entrada de datos
- Interacción con botones
- Manejo de errores

**Use Case Tests**
- LoginUsecase: éxito y fallo
- RegisterUsecase: éxito y fallo
- GetCurrentUserUsecase: usuario actual y nulo

**Entity Tests**
- UserEntity: creación, igualdad, toString
- CourseEntity: estructura básica
- ContentEntity: diferentes tipos
- ProgressEntity: seguimiento de progreso
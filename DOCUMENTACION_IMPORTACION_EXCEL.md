# Documentación - Importación de Excel para Cursos

## Descripción General

Esta funcionalidad permite a los administradores importar cursos, módulos y lecciones desde un archivo Excel (.xlsx o .xls) de manera masiva. El archivo debe contener 3 pestañas: **Cursos**, **Modulos** y **Lecciones**.

## Características

- **Importación completa**: Puedes importar cursos con todos sus módulos y lecciones en un solo archivo
- **Importación parcial**: También puedes importar solo módulos y lecciones para cursos existentes
- **Validación automática**: El sistema valida que los datos sean correctos antes de importar
- **Mapeo de IDs**: Los IDs del Excel se mapean automáticamente a los IDs de Firestore
- **Soporte para videos y estrategias**: Las lecciones pueden incluir URLs de videos y estrategias en formato JSON

## Formato del Archivo Excel

El archivo Excel debe tener exactamente 3 pestañas con los siguientes nombres:

### 1. Pestaña "Cursos"

| Columna | Nombre | Descripción | Requerido | Ejemplo |
|---------|--------|-------------|-----------|---------|
| A | ID | Identificador temporal del curso (puede estar vacío) | No | curso_001 |
| B | Título | Nombre del curso | Sí | Introducción a las Ciencias Naturales |
| C | Descripción | Descripción detallada del curso | Sí | Curso introductorio sobre ciencias naturales para nivel primario |
| D | Público Objetivo | Audiencia del curso | Sí | Ciencias Naturales |
| E | Estado | Estado del curso (draft o published) | No | draft |

**Valores válidos para Público Objetivo:**
- Ciencias Sociales
- Ciencias Naturales
- Comunicación y Lenguaje
- Alternativa
- Otro(Especificar)

**Valores válidos para Estado:**
- draft (borrador)
- published (publicado)

### 2. Pestaña "Modulos"

| Columna | Nombre | Descripción | Requerido | Ejemplo |
|---------|--------|-------------|-----------|---------|
| A | ID | Identificador temporal del módulo (puede estar vacío) | No | modulo_001 |
| B | ID Curso | ID del curso al que pertenece (del Excel o de Firestore) | Sí | curso_001 |
| C | Título | Nombre del módulo | Sí | Módulo 1: Introducción |
| D | Descripción | Descripción del módulo | No | Introducción a los conceptos básicos |
| E | Orden | Número de orden del módulo dentro del curso | Sí | 1 |

**Nota sobre ID Curso:**
- Si el curso se está creando en el mismo Excel, usa el ID temporal de la pestaña Cursos
- Si el curso ya existe en Firestore, usa el ID real del curso de Firestore

### 3. Pestaña "Lecciones"

| Columna | Nombre | Descripción | Requerido | Ejemplo |
|---------|--------|-------------|-----------|---------|
| A | ID | Identificador temporal de la lección (puede estar vacío) | No | leccion_001 |
| B | ID Curso | ID del curso al que pertenece | Sí | curso_001 |
| C | ID Módulo | ID del módulo al que pertenece | Sí | modulo_001 |
| D | Título | Nombre de la lección | Sí | Lección 1: Conceptos básicos |
| E | Objetivos | Objetivos de aprendizaje de la lección | Sí | Comprender los fundamentos de... |
| F | URL Video | URL del video de la lección | No | https://youtube.com/watch?v=xxxxx |
| G | Tipo Video | Tipo de video (youtube, vimeo, etc.) | No | youtube |
| H | Estrategias (JSON) | Estrategias en formato JSON | No | [{"titulo":"Estrategia 1","descripcion":"Descripción"}] |
| I | Orden | Número de orden de la lección dentro del módulo | Sí | 1 |

**Formato de Estrategias (JSON):**
```json
[
  {
    "titulo": "Estrategia 1",
    "descripcion": "Descripción de la estrategia 1"
  },
  {
    "titulo": "Estrategia 2",
    "descripcion": "Descripción de la estrategia 2"
  }
]
```

## Ejemplo Completo de Archivo Excel

### Pestaña Cursos

| ID | Título | Descripción | URL Thumbnail | Público Objetivo | Estado |
|----|--------|-------------|---------------|------------------|--------|
| curso_001 | Introducción a las Ciencias | Curso de ciencias para primaria | | Ciencias Naturales | draft |
| curso_002 | Matemáticas Básicas | Curso de matemáticas nivel inicial | | Ciencias Naturales | draft |

### Pestaña Modulos

| ID | ID Curso | Título | Descripción | Orden |
|----|----------|--------|-------------|-------|
| modulo_001 | curso_001 | Módulo 1: Introducción | Conceptos básicos | 1 |
| modulo_002 | curso_001 | Módulo 2: Avanzado | Conceptos avanzados | 2 |
| modulo_003 | curso_002 | Módulo 1: Números | Números y operaciones | 1 |

### Pestaña Lecciones

| ID | ID Curso | ID Módulo | Título | Objetivos | URL Video | Tipo Video | Estrategias (JSON) | Orden |
|----|----------|-----------|--------|-----------|-----------|------------|-------------------|-------|
| leccion_001 | curso_001 | modulo_001 | Lección 1: ¿Qué son las ciencias? | Definir qué son las ciencias naturales | https://youtube.com/watch?v=abc123 | youtube | [{"titulo":"Lectura","descripcion":"Leer el capítulo 1"}] | 1 |
| leccion_002 | curso_001 | modulo_001 | Lección 2: El método científico | Comprender el método científico | https://youtube.com/watch?v=def456 | youtube | [{"titulo":"Práctica","descripcion":"Realizar experimento"}] | 2 |
| leccion_003 | curso_001 | modulo_002 | Lección 1: Laboratorio | Introducción al laboratorio | | | [{"titulo":"Observación","descripcion":"Observar el laboratorio"}] | 1 |

## Cómo Usar la Funcionalidad

### Paso 1: Preparar el Archivo Excel

1. Crea un archivo Excel (.xlsx o .xls)
2. Crea 3 pestañas con los nombres exactos: "Cursos", "Modulos", "Lecciones"
3. Agrega los encabezados en la primera fila de cada pestaña
4. Llena los datos según las especificaciones anteriores
5. Guarda el archivo

### Paso 2: Importar en la Aplicación

1. Inicia sesión como administrador
2. Navega a la pantalla "Gestionar Cursos"
3. Haz clic en el botón verde "Importar Excel"
4. Selecciona el archivo Excel preparado
5. Revisa el resumen de lo que se va a importar
6. Confirma la importación

### Paso 3: Verificar la Importación

1. La aplicación mostrará un mensaje de confirmación con el número de elementos importados
2. Los cursos aparecerán en la lista de cursos
3. Puedes entrar a cada curso para verificar que los módulos y lecciones se importaron correctamente

## Casos de Uso

### Caso 1: Importar un Curso Completo

**Escenario**: Quieres crear un nuevo curso con todos sus módulos y lecciones.

**Solución**:
- Llena la pestaña "Cursos" con los datos del curso
- Llena la pestaña "Modulos" con los módulos del curso (usa el ID temporal del curso)
- Llena la pestaña "Lecciones" con las lecciones (usa los IDs temporales del curso y módulos)
- Importa el archivo

### Caso 2: Agregar Módulos y Lecciones a un Curso Existente

**Escenario**: Ya tienes un curso en Firestore y quieres agregarle módulos y lecciones.

**Solución**:
- Deja la pestaña "Cursos" vacía
- En la pestaña "Modulos", usa el ID real del curso de Firestore en la columna "ID Curso"
- En la pestaña "Lecciones", usa el ID real del curso y los IDs temporales de los módulos
- Importa el archivo

### Caso 3: Importar Solo Lecciones a un Módulo Existente

**Escenario**: Ya tienes un curso y un módulo, solo quieres agregar lecciones.

**Solución**:
- Deja las pestañas "Cursos" y "Modulos" vacías
- En la pestaña "Lecciones", usa el ID real del curso y el ID real del módulo de Firestore
- Importa el archivo

## Validaciones

El sistema realiza las siguientes validaciones antes de importar:

1. **Formato de archivo**: Solo se aceptan archivos .xlsx y .xls
2. **Pestañas requeridas**: Deben existir las 3 pestañas con los nombres exactos
3. **Campos requeridos**: Los campos marcados como "Sí" en la tabla no pueden estar vacíos
4. **Consistencia de IDs**: Los IDs de curso y módulo en las lecciones deben existir
5. **Formato de JSON**: Las estrategias deben tener un formato JSON válido

## Manejo de Errores

Si ocurre algún error durante la importación:

1. El sistema mostrará un diálogo con los errores encontrados
2. No se importará ningún dato si hay errores
3. Corrige los errores en el archivo Excel
4. Intenta la importación nuevamente

## Limitaciones

1. **Cuestionarios**: Los cuestionarios no se importan desde Excel. Deben crearse manualmente después de importar las lecciones.
2. **Checkpoints**: Los checkpoints educativos no se importan desde Excel.
3. **Contenido Delta**: El contenido en formato Quill Delta no se importa desde Excel.
4. **Recursos descargables**: Los recursos descargables no se importan desde Excel.

## Recursos descargables**: Los recursos descargables no se importan desde Excel.

## Soporte

Si tienes problemas con la importación:

1. Verifica que el archivo tenga el formato correcto
2. Revisa que los nombres de las pestañas sean exactos ("Cursos", "Modulos", "Lecciones")
3. Asegúrate de que los campos requeridos estén llenos
4. Verifica que los IDs sean consistentes entre pestañas
5. Revisa el formato JSON de las estrategias

## Notas Técnicas

- Los IDs temporales del Excel se mapean automáticamente a los IDs reales de Firestore
- Los cursos se crean con estado "draft" por defecto
- Los módulos se guardan tanto en la subcolección del curso como en la colección "modules"
- Las lecciones se guardan tanto en la colección "lecciones" como en la subcolección del módulo
- La importación es una operación atómica: si falla, no se guarda nada

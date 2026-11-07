# Guía y Estructura del Archivo Excel (Plantilla de Cursos)

Este documento explica de forma clara la organización del archivo Excel `plantilla_cursos.xlsx` para facilitar su lectura, análisis o procesamiento mediante scripts.

---

## 1. Organización del Archivo

El libro de Excel se compone de **6 pestañas (hojas)** interconectadas:

1. **`Cursos`**: Contiene la información general del curso.
2. **`Modulos`**: Lista los módulos o temas que pertenecen a cada curso.
3. **`Lecciones`**: Lista las lecciones asociadas a cada módulo.
4. **`Estrategias`**: Define las actividades pedagógicas o dinámicas de cada lección.
5. **`Cuestionarios`**: Registra los exámenes o evaluaciones asociados a las lecciones.
6. **`Preguntas` y `Respuestas`**: Contienen los reactivos y sus respectivas opciones de respuesta.

---

## 2. Detalle de Columnas y Contenido por Pestaña

### Pestaña: `Cursos`
Describe los datos básicos del curso principal.

| Nombre de Columna | Descripción | Ejemplo de Fila |
| :--- | :--- | :--- |
| `ID` | Código identificador único del curso | `curso_bio_001` |
| `Título` | Nombre completo del curso | `Biología General: Fundamentos de la Vida` |
| `Descripción` | Resumen o explicación del curso | `Curso introductorio a la biología celular y ecología.` |
| `Público Objetivo` | Área o grupo al que va dirigido | `Ciencias Naturales` |
| `Estado` | Estado de publicación del curso | `draft` (o `published`) |

---

### Pestaña: `Modulos`
Contiene los bloques de contenido que componen un curso.

| Nombre de Columna | Descripción | Ejemplo de Fila |
| :--- | :--- | :--- |
| `ID` | Código identificador único del módulo | `modulo_bio_001` |
| `ID Curso` | Código del curso al que pertenece | `curso_bio_001` |
| `Título` | Nombre del módulo | `Módulo 1: La Célula y su Entorno` |
| `Descripción` | Explicación breve de este módulo | `Estudio de las partes de la célula y su funcionamiento.` |
| `Orden` | Posición en la secuencia de módulos | `1` |

---

### Pestaña: `Lecciones`
Contiene las lecciones individuales agrupadas en cada módulo.

| Nombre de Columna | Descripción | Ejemplo de Fila |
| :--- | :--- | :--- |
| `ID` | Código identificador único de la lección | `leccion_bio_001` |
| `ID Curso` | Código del curso relacionado | `curso_bio_001` |
| `ID Módulo` | Código del módulo al que pertenece | `modulo_bio_001` |
| `Título` | Nombre de la lección | `La fotosíntesis y la energía celular` |
| `Objetivos` | Lo que el estudiante aprenderá | `Comprender el proceso fotosintético en plantas.` |
| `URL Video` | Enlace al video de la lección | `https://www.youtube.com/watch?v=example` |
| `Tipo Video` | Plataforma del video | `youtube` |
| `Orden` | Posición de la lección dentro del módulo | `1` |

---

### Pestaña: `Estrategias`
Define las actividades didácticas asociadas a cada lección.

| Nombre de Columna | Descripción | Ejemplo de Fila |
| :--- | :--- | :--- |
| `ID` | Código identificador único de la estrategia | `estrategia_001` |
| `ID Lección` | Código de la lección a la que aplica | `leccion_bio_001` |
| `Título` | Nombre de la actividad o estrategia | `Sopa de letras de organelos` |
| `Descripción` | Explicación de cómo realizar la actividad | `Encontrar 10 términos clave sobre la célula vegetal.` |

---

### Pestaña: `Cuestionarios`
Identifica las evaluaciones de las lecciones.

| Nombre de Columna | Descripción | Ejemplo de Fila |
| :--- | :--- | :--- |
| `ID` | Código identificador del cuestionario | `quiz_001` |
| `ID Lección` | Código de la lección que evalúa | `leccion_bio_001` |
| `Título` | Nombre del cuestionario | `Evaluación de Fotosíntesis` |

---

### Pestaña: `Preguntas`
Preguntas individuales contenidas en un cuestionario.

| Nombre de Columna | Descripción | Ejemplo de Fila |
| :--- | :--- | :--- |
| `ID` | Código identificador de la pregunta | `pregunta_001` |
| `ID Cuestionario` | Código del cuestionario al que pertenece | `quiz_001` |
| `Pregunta` | Enunciado de la pregunta | `¿En qué orgánulo celular ocurre la fotosíntesis?` |

---

### Pestaña: `Respuestas`
Opciones de respuesta asociadas a cada pregunta.

| Nombre de Columna | Descripción | Ejemplo de Fila |
| :--- | :--- | :--- |
| `ID Pregunta` | Código de la pregunta a la que pertenece | `pregunta_001` |
| `Opción` | Letra identificadora de la opción | `A` |
| `Texto` | Texto explicativo de la respuesta | `Cloroplasto` |
| `Es Correcta` | Indica si es la respuesta acertada | `TRUE` (o `FALSE`) |

---

## 3. Ejemplo Ilustrativo de Filas Relacionadas

A continuación se muestra cómo se vincula una fila de cada pestaña usando los identificadores (`ID`):

* **Cursos:** Fila `ID` = `curso_bio_001`
* **Modulos:** Fila `ID` = `modulo_bio_001` con `ID Curso` = `curso_bio_001`
* **Lecciones:** Fila `ID` = `leccion_bio_001` con `ID Módulo` = `modulo_bio_001` y `ID Curso` = `curso_bio_001`
* **Estrategias:** Fila `ID` = `estrategia_001` con `ID Lección` = `leccion_bio_001`
* **Cuestionarios:** Fila `ID` = `quiz_001` con `ID Lección` = `leccion_bio_001`
* **Preguntas:** Fila `ID` = `pregunta_001` con `ID Cuestionario` = `quiz_001`
* **Respuestas:** 
  * Fila con `ID Pregunta` = `pregunta_001`, `Opción` = `A`, `Texto` = `Cloroplasto`, `Es Correcta` = `TRUE`
  * Fila con `ID Pregunta` = `pregunta_001`, `Opción` = `B`, `Texto` = `Mitocondria`, `Es Correcta` = `FALSE`
# TICKETEXPRESS+
**Implementación de Base de Datos (DDL)**
Este repositorio contiene la implementación oficial de la base de datos para el proyecto **TicketExpress+**, desarrollada en **PostgreSQL** mediante el Lenguaje de Definición de Datos (DDL).

# Integrantes del Equipo D.

* **Claudia Navarrete**
* **Luis Pacheco**
* **Andrés Herrera**

# Objetivo de la Actividad

El propósito de esta tarea es traducir el diagrama relacional oficial del proyecto a un script `.sql` funcional, estructurado y libre de errores. La implementación garantiza la integridad de los datos mediante el uso explícito de claves y restricciones de negocio.

# ¿Qué contiene este proyecto?

1. **Creación de la Base de Datos:** Sentencias para inicializar la base de datos de TicketExpress+.

2. **Definición de Tablas:** Creación de las 9 entidades del modelo relacional respetando estrictamente el orden lógico de dependencias (`categoria`, `recinto`, `evento`, `asiento`, `funcion`, `usuario`, `pago`, `tarifa` y `tique`).

3. **Claves Primarias y Foráneas:** Definición explícita de `PRIMARY KEY` y `FOREIGN KEY` para asegurar las relaciones entre entidades.

4. **Restricciones de Negocio:** Aplicación de validaciones con `NOT NULL`, `UNIQUE` y `CHECK` (estados permitidos, valores numéricos mayores a cero, campos obligatorios, etc.).



## Insertar datos en las tablas

La actividad consiste en poblar, validar y mantener la base de datos relacional del sistema mediante la elaboración de un script SQL unificado (`script_dml.sql`). El trabajo abarca la inserción de datos iniciales coherentes, la modificación de información clave y la eliminación controlada de registros, aplicando buenas prácticas de integridad referencial y validación mediante consultas previas.


# Requerimientos Generales

El script unificado debe incluir los siguientes componentes en su estructura:

1. **Inserciones (`INSERT`):**
   * Carga de **10 registros coherentes por cada tabla** del sistema.
   * Respeto estricto al orden de dependencias de claves foráneas (`FOREIGN KEY`) para evitar errores de integridad durante la ejecución.

2. **Actualizaciones con Verificación (`UPDATE`):**
   * Realización de sentencias `UPDATE` sobre campos específicos.
   * **Requisito obligatorio:** Cada sentencia `UPDATE` debe estar precedida por una consulta `SELECT` de validación previa para verificar el estado original del registro antes de modificarlo.

3. **Eliminaciones con Verificación (`DELETE`):**
   * Realización de sentencias `DELETE` para registros de prueba, temporales o cancelados.
   * **Requisito obligatorio:** Cada sentencia `DELETE` debe estar precedida por su respectivo `SELECT` previo para asegurar la identificación precisa del registro a eliminar.

4. **Comprobación de Datos:**
   * Inclusión de consultas `SELECT` y conteos al final de cada sección para validar que los cambios fueron registrados correctamente en PostgreSQL.


## Generación e Importación Masiva de Datos Sintéticos

En esta etapa del proyecto se diseñaron los esquemas de datos sintéticos utilizando la herramienta Mockaroo y se ejecutó la **importación masiva en PostgreSQL**, asegurando la integridad referencial y respetando el orden de dependencias de llaves foráneas (*Foreign Keys*).


# Herramientas Utilizadas
* **PostgreSQL** Motor de base de datos relacional.
* **VScode:** Entorno de desarrollo para la gestión del repositorio y scripts SQL.
* **Mockaroo:** Generación de archivos CSV con volumen de datos de prueba.
* **Git & GitHub:** Control de versiones bajo el flujo de trabajo Gitflow.


# Entidades y Registros Generados en Mockaroo

A continuación se detalla el volumen de registros por cada tabla ubicada dentro de la carpeta `CSV/`:

| Entidad | Registros Generados |
|   :---          | :---: |
| **`categoria`** | 5 |
| **`recinto`**   | 5 |
| **`usuario`**   | 100 |
| **`evento`**    | 20 |
| **`asiento`**   | 100 |
| **`funcion`**   | 50 |
| **`pago`**      | 300 |
| **`tarifa`**    | 100 |
| **`tique`**     | 500 |
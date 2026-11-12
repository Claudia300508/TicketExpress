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


## Encapsulamiento de reglas de negocio en TicketExpress+

El objetivo es aplicar procedimientos almacenados, funciones, disparadores (triggers) y control de 
transacciones para que el propio motor de base de datos (PostgreSQL) controle las reglas de negocio 
de la venta de tiques.

**Reglas de negocio implementadas**

1. Un asiento solo se puede vender si su tarifa para esa función está en estado `disponible`.
2. La compra es atómica ("todo o nada"): si un asiento de la compra no está disponible, no se registra nada.
3. Cada compra genera un pago `completado` cuyo monto es la suma de los precios de sus tiques.
4. Al vender, la tarifa pasa a `vendido` y el tique queda `emitido`.
5. Al cancelar una compra, el pago pasa a `reembolsado`, sus tiques a `cancelado` y los asientos vuelven a `disponible`. No se pueden cancelar compras con tiques ya `usado`.
6. No se pueden vender tiques para funciones cuya fecha y hora ya pasaron, ni para funciones finalizadas o canceladas.
7. Toda venta de un tique queda registrada automáticamente en una tabla de auditoría.
8. Los ingresos de un evento suman el `preciopagado` de los tiques no cancelados dicho pago está `completado`.

### Elementos implementados

| Tipo | Nombre | Descripción |
|---|---|---|
| Procedimiento | `sp_registrar_compra(p_idusuario, p_idfuncion, p_asientos, p_metodopago)` | Registra la 
compra de uno o más tiques para una función, validando la disponibilidad |
| Procedimiento | `sp_cancelar_compra(p_idpago)` | Cancela una compra y libera sus asientos |
| Función | `fn_asientos_disponibles(p_idfuncion)` | Devuelve la cantidad de asientos disponibles de una función |
| Función | `fn_ingresos_evento(p_idevento)` | Devuelve el monto total de ingresos de un evento |
| Tabla | `auditoria_venta_tique` | Guarda `idtique`, fecha de la venta y usuario de cada venta |
| Trigger | `trg_auditar_venta_tique` (`AFTER INSERT` en `tique`) | Registra la venta en la tabla de auditoría |
| Trigger | `trg_validar_funcion_vigente` (`BEFORE INSERT` en `tique`) | Rechaza ventas para funciones que ya pasaron |


# TICKETEXPRESS+
**Implementación de Base de Datos (DDL)**
Este repositorio contiene la implementación oficial de la base de datos para el proyecto **TicketExpress+**, desarrollada en **PostgreSQL** mediante el Lenguaje de Definición de Datos (DDL).

##  Integrantes del Equipo D.

* **Claudia Navarrete**
* **Luis Pacheco**
* **Andrés Herrera**

## Objetivo de la Actividad

El propósito de esta tarea es traducir el diagrama relacional oficial del proyecto a un script `.sql` funcional, estructurado y libre de errores. La implementación garantiza la integridad de los datos mediante el uso explícito de claves y restricciones de negocio.

---

## ¿Qué contiene este proyecto?

1. **Creación de la Base de Datos:** Sentencias para inicializar la base de datos de TicketExpress+.

2. **Definición de Tablas:** Creación de las 9 entidades del modelo relacional respetando estrictamente el orden lógico de dependencias (`categoria`, `recinto`, `evento`, `asiento`, `funcion`, `usuario`, `pago`, `tarifa` y `tique`).

3. **Claves Primarias y Foráneas:** Definición explícita de `PRIMARY KEY` y `FOREIGN KEY` para asegurar las relaciones entre entidades.

4. **Restricciones de Negocio:** Aplicación de validaciones con `NOT NULL`, `UNIQUE` y `CHECK` (estados permitidos, valores numéricos mayores a cero, campos obligatorios, etc.).

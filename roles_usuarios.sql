-- SEGURIDAD | Roles y usuarios
-- Roles = grupos de permisos (no inician sesion)
-- Usuarios = personas con contraseña, pertenecen a un rol

CREATE ROLE rol_administrador   NOLOGIN;
CREATE ROLE rol_operador_ventas NOLOGIN;
CREATE ROLE rol_analista        NOLOGIN;

CREATE USER usr_admin    PASSWORD 'Demo_admin_2026'    IN ROLE rol_administrador;
CREATE USER usr_ventas   PASSWORD 'Demo_ventas_2026'   IN ROLE rol_operador_ventas;
CREATE USER usr_analista PASSWORD 'Demo_analista_2026' IN ROLE rol_analista;
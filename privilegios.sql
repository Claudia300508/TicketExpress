
-- SEGURIDAD | Privilegios (GRANT / REVOKE)
-- Se ejecuta DESPUES de roles_usuarios.sql y de la auditoria.


-- BLOQUE 1: partir de cero y permisos del administrador

-- Nadie tiene permisos por defecto (PUBLIC = todo el mundo)
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE sp_registrar_compra(BIGINT, BIGINT, BIGINT[], VARCHAR) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE sp_cancelar_compra(BIGINT) FROM PUBLIC;

-- Los tres roles pueden entrar al esquema public
GRANT USAGE ON SCHEMA public TO rol_administrador, rol_operador_ventas, rol_analista;

-- Administrador: control total
GRANT ALL ON ALL TABLES IN SCHEMA public TO rol_administrador;
GRANT EXECUTE ON PROCEDURE sp_registrar_compra(BIGINT, BIGINT, BIGINT[], VARCHAR) TO rol_administrador;
GRANT EXECUTE ON PROCEDURE sp_cancelar_compra(BIGINT) TO rol_administrador;


-- BLOQUE 2: operador de ventas

-- Catalogos: solo lectura
GRANT SELECT ON categoria, recinto, evento, asiento, funcion TO rol_operador_ventas;

-- Tarifas: leer y cambiar estado/precio
GRANT SELECT, UPDATE ON tarifa TO rol_operador_ventas;

-- Pagos y tiques: leer, crear y modificar (sin borrar)
GRANT SELECT, INSERT, UPDATE ON pago, tique TO rol_operador_ventas;

-- Usuarios: puede ver sus datos, pero NO la columna clave
GRANT SELECT (idusuario, nombre, apellido, correo, telefono, usuario, fechaRegistro, estado) ON usuario TO rol_operador_ventas;

-- El trigger de auditoria de ventas escribe con el permiso de quien vende
GRANT INSERT ON auditoria_venta_tique TO rol_operador_ventas;

-- Puede usar los dos procedimientos
GRANT EXECUTE ON PROCEDURE sp_registrar_compra(BIGINT, BIGINT, BIGINT[], VARCHAR) TO rol_operador_ventas;
GRANT EXECUTE ON PROCEDURE sp_cancelar_compra(BIGINT) TO rol_operador_ventas;


-- BLOQUE 3: analista (solo lectura)

-- Catalogos, tarifas, pagos y tiques: solo lectura
GRANT SELECT ON categoria, recinto, evento, asiento, funcion, tarifa, pago, tique TO rol_analista;

-- Usuarios: puede ver sus datos, pero NO la columna clave
GRANT SELECT (idusuario, nombre, apellido, correo, telefono, usuario, fechaRegistro, estado) ON usuario TO rol_analista;
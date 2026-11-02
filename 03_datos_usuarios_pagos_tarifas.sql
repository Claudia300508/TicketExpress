-- =====================================================================
-- TicketExpress+  |  Manipulación de datos (DML)
-- Integrante 2 (Andres Herrera): usuario, pago y tarifa
-- Rama: feature/usuarios-tarifas
--  PostgreSQL
--
-- Requiere que ya existan (y estén pobladas) las tablas de la parte 1:
-- categoria, recinto, evento, asiento y funcion.
-- No contiene DDL: no se modifica la estructura de la base de datos.
--
-- Orden del archivo (según la consigna):
--   1. INSERT   2. UPDATE   3. DELETE   4. SELECT de verificación
-- Los identificadores (idusuario, idpago, idtarifa) los genera la base
-- de datos en orden 1, 2, 3... por lo que las referencias de abajo
-- dependen de que las tablas estén vacías al ejecutar este script.
-- =====================================================================


-- =====================================================================
-- 1. INSERCIONES
-- Orden por llaves foráneas: usuario -> pago -> tarifa
-- =====================================================================

-- 1.1 usuario (12 registros) 
-- Las claves son hashes de ejemplo; nunca se guarda una contraseña real.
-- El usuario 11 es un cliente real sin compras; el 12 es una cuenta de
-- prueba que se elimina más adelante.
INSERT INTO usuario (nombre, apellido, correo, telefono, usuario, clave, fechaRegistro, estado) VALUES
('Carlos',    'Martínez',  'carlos.martinez@gmail.com',    '7012-3456', 'cmartinez',  'hash_a91f03c2', '2026-01-15', 'activo'),
('María',     'Hernández', 'maria.hernandez@hotmail.com',  '7123-4567', 'mhernandez', 'hash_b72e18d4', '2026-02-03', 'activo'),
('José',      'Ramírez',   'jose.ramirez@gmail.com',       '7234-5678', 'jramirez',   'hash_c53d29e6', '2026-02-20', 'activo'),
('Ana',       'Gómez',     'ana.gomez@yahoo.com',          '7345-6789', 'agomez',     'hash_d34c3af8', '2026-03-11', 'activo'),
('Luis',      'Flores',    'luis.flores@gmial.com',        '7456-7890', 'lflores',    'hash_e15b4b0a', '2026-03-29', 'activo'),
('Sofía',     'Castillo',  'sofia.castillo@outlook.com',   '7567-8901', 'scastillo',  'hash_f06a5c1c', '2026-04-14', 'activo'),
('Diego',     'Mejía',     'diego.mejia@gmail.com',        '7678-9012', 'dmejia',     'hash_017b6d2e', '2026-05-02', 'activo'),
('Gabriela',  'Rivas',     'gabriela.rivas@gmail.com',     '7789-0123', 'grivas',     'hash_128c7e3f', '2026-05-23', 'activo'),
('Fernando',  'Orellana',  'fernando.orellana@hotmail.com','7890-1234', 'forellana',  'hash_239d8f40', '2026-06-08', 'activo'),
('Lucía',     'Portillo',  'lucia.portillo@gmail.com',     NULL,        'lportillo',  'hash_34ae9051', '2026-07-19', 'activo'),
('Ricardo',   'Alvarado',  'ricardo.alvarado@yahoo.com',   '7901-2345', 'ralvarado',  'hash_45bfa162', '2026-08-05', 'activo'),
('Prueba',    'Sistema',   'prueba@test.com',              NULL,        'usuario_prueba', 'hash_000test', '2026-08-30', 'activo');

-- 1.2 pago (11 registros) 
-- Cada fecha de pago es anterior a la fecha de la función correspondiente.
INSERT INTO pago (fecha, hora, montoTotal, metodoPago, estado, idusuario) VALUES
('2026-09-20', '10:15:00', 300.00, 'tarjeta_credito', 'completado',  1),   -- 1: dos entradas VIP (tarifas 1 y 2)
('2026-09-22', '14:40:00',  85.00, 'tarjeta_debito',  'completado',  2),   -- 2: tarifa 3
('2026-10-10', '12:30:00',  40.00, 'efectivo',        'completado', 10),   -- 3: tarifa 4
('2026-10-01', '09:05:00', 120.00, 'transferencia',   'completado',  3),   -- 4: tarifa 5
('2026-10-02', '16:30:00', 120.00, 'tarjeta_credito', 'reembolsado', 9),   -- 5: tarifa 6 (se devolvió)
('2026-10-18', '11:20:00',  95.00, 'tarjeta_credito', 'completado',  4),   -- 6: tarifa 9
('2026-10-19', '17:45:00',  60.00, 'efectivo',        'completado',  5),   -- 7: tarifa 10
('2026-10-21', '19:05:00',  90.00, 'tarjeta_debito',  'completado',  6),   -- 8: tarifas 14 y 15
('2026-10-20', '20:10:00',  70.00, 'tarjeta_debito',  'pendiente',   7),   -- 9: tarifa 7 (reservada)
('2026-10-18', '08:55:00',  35.00, 'transferencia',   'pendiente',   8),   -- 10: tarifa 11 (reservada)
('2026-10-05', '13:00:00', 150.00, 'tarjeta_credito', 'rechazado',   8);   -- 11: intento fallido, sin tique

-- 1.3 tarifa (15 registros) --------------------------------------------
-- Cada asiento pertenece al mismo recinto que la función:
--   funciones 1 y 3 -> Estadio Cuscatlán (asientos 1 a 4)
--   función 2 y 7   -> Teatro Nacional    (asientos 5 a 7)
--   función 8       -> Gimnasio Nacional  (asientos 8 y 9)
-- No se usan la función 9 ni el asiento 10 porque la parte 1 los elimina.
INSERT INTO tarifa (precio, estado, idfuncion, idasiento) VALUES
(150.00, 'vendido',    1, 1),   --  1
(150.00, 'vendido',    1, 2),   --  2
( 85.00, 'vendido',    1, 3),   --  3
( 40.00, 'vendido',    1, 4),   --  4
(120.00, 'vendido',    3, 1),   --  5
(120.00, 'vendido',    3, 2),   --  6  (reembolsada, se libera con un UPDATE)
( 70.00, 'reservado',  3, 3),   --  7
( 35.00, 'disponible', 3, 4),   --  8
( 95.00, 'vendido',    8, 8),   --  9
( 60.00, 'vendido',    8, 9),   -- 10
( 35.00, 'reservado',  2, 5),   -- 11
( 35.00, 'disponible', 2, 6),   -- 12
( 28.00, 'inactivo',   2, 7),   -- 13 (mal cargada, se elimina)
( 45.00, 'vendido',    7, 5),   -- 14
( 45.00, 'vendido',    7, 6);   -- 15


-- =====================================================================
-- 2. ACTUALIZACIONES (cada UPDATE va precedido de su SELECT)
-- =====================================================================

-- 2.1 La clienta María cambió de número de teléfono
SELECT * FROM usuario WHERE idusuario = 2;
UPDATE usuario
SET telefono = '7123-9900'
WHERE idusuario = 2;

-- 2.2 Corregir un correo mal escrito (gmial.com -> gmail.com)
SELECT * FROM usuario WHERE idusuario = 5 AND correo = 'luis.flores@gmial.com';
UPDATE usuario
SET correo = 'luis.flores@gmail.com'
WHERE idusuario = 5 AND correo = 'luis.flores@gmial.com';

-- 2.3 Marcar como inactivo a un usuario que nunca realizó compras
SELECT * FROM usuario WHERE idusuario = 11 AND estado = 'activo';
UPDATE usuario
SET estado = 'inactivo'
WHERE idusuario = 11 AND estado = 'activo';

-- 2.4 Cambiar el método de un pago pendiente (el cliente pagará por transferencia)
SELECT * FROM pago WHERE idpago = 9 AND estado = 'pendiente';
UPDATE pago
SET metodoPago = 'transferencia'
WHERE idpago = 9 AND estado = 'pendiente';

-- 2.5 Liberar la entrada reembolsada para que pueda venderse de nuevo
SELECT * FROM tarifa WHERE idtarifa = 6 AND estado = 'vendido';
UPDATE tarifa
SET estado = 'disponible'
WHERE idtarifa = 6 AND estado = 'vendido';

-- 2.6 Ajustar el precio de una entrada disponible
SELECT * FROM tarifa WHERE idtarifa = 8 AND estado = 'disponible';
UPDATE tarifa
SET precio = 45.00
WHERE idtarifa = 8 AND estado = 'disponible';

-- 3.1 Eliminar la cuenta de prueba (no tiene pagos ni tiques)
SELECT * FROM usuario WHERE idusuario = 12 AND usuario = 'usuario_prueba';
DELETE FROM usuario
WHERE idusuario = 12 AND usuario = 'usuario_prueba';

-- 3.2 Eliminar un pago rechazado que no generó ningún tique
SELECT * FROM pago WHERE idpago = 11 AND estado = 'rechazado';
DELETE FROM pago
WHERE idpago = 11 AND estado = 'rechazado';

-- 3.3 Eliminar una tarifa inactiva cargada por error
SELECT * FROM tarifa WHERE idtarifa = 13 AND estado = 'inactivo';
DELETE FROM tarifa
WHERE idtarifa = 13 AND estado = 'inactivo';


-- =====================================================================
-- 4. CONSULTAS DE VERIFICACIÓN
-- =====================================================================

SELECT * FROM usuario ORDER BY idusuario;

SELECT * FROM pago ORDER BY idpago;

SELECT * FROM tarifa ORDER BY idtarifa;

-- Pagos con el nombre del cliente
SELECT p.idpago, u.nombre || ' ' || u.apellido AS cliente,
       p.montoTotal, p.metodoPago, p.estado
FROM pago p
JOIN usuario u ON u.idusuario = p.idusuario
ORDER BY p.idpago;

-- Tarifas con el evento, el recinto y el asiento
SELECT t.idtarifa, e.nombre AS evento, f.fecha, r.nombre AS recinto,
       a.zona, a.fila, a.numero, t.precio, t.estado
FROM tarifa t
JOIN funcion f ON f.idfuncion = t.idfuncion
JOIN evento  e ON e.idevento  = f.idevento
JOIN asiento a ON a.idasiento = t.idasiento
JOIN recinto r ON r.idrecinto = a.idrecinto
ORDER BY t.idtarifa;


-- =====================================================================
-- GUÍA PARA EL INTEGRANTE 3 (tabla tique, 10 registros)
-- Una fila por cada tarifa 'vendido'. idprecio = idtarifa.
-- El preciopagado coincide con el precio de la tarifa, y la suma de los
-- tiques de un pago coincide con su montoTotal (pago 1 = 150 + 150,
-- pago 8 = 45 + 45). Estados válidos según el DDL de main:
-- 'emitido', 'usado', 'cancelado', 'vencido'.
--
--  codigo    preciopagado  estado      idprecio  idpago  idusuario
--  TE-0001      150.00     emitido        1        1        1
--  TE-0002      150.00     emitido        2        1        1
--  TE-0003       85.00     emitido        3        2        2
--  TE-0004       40.00     emitido        4        3       10
--  TE-0005      120.00     emitido        5        4        3
--  TE-0006      120.00     cancelado      6        5        9   (pago reembolsado)
--  TE-0007       95.00     emitido        9        6        4
--  TE-0008       60.00     emitido       10        7        5
--  TE-0009       45.00     emitido       14        8        6
--  TE-0010       45.00     emitido       15        8        6
--
-- No asociar tiques a: pago 11, tarifa 13 ni usuario 12 (se eliminan).
-- =====================================================================

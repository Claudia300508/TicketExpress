-- =====================================================================
-- TicketExpress+  |  Semana 6: reglas de negocio en la base de datos
-- Procedimientos, funciones, triggers y pruebas  (script final)
-- Motor: PostgreSQL
--
-- Orden del script:
--   1. Procedimientos (compra y cancelacion con transaccion)  - Claudia Navarrete
--   2. Funciones y trigger de validacion de tiempo             - Luis Pacheco
--   3. Auditoria de ventas (tabla + trigger)                   - Integrante 3
--   4. Pruebas ejecutadas
--
-- Requisito: la base ya cargada con preparar_bd.sql (tablas + datos de los CSV).
-- Las secciones 1 a 3 se pueden ejecutar varias veces sin error.
--
-- Nota de unificacion: en las funciones de la seccion 2 el parametro paso de
-- INT a BIGINT, porque las llaves del modelo son BIGINT y con INT la funcion
-- no se puede usar con columnas (ej. fn_asientos_disponibles(f.idfuncion)).
-- =====================================================================

-- =====================================================================
-- 1. PROCEDIMIENTOS
-- =====================================================================
-- PARTE 1 - PROCEDIMIENTOS ALMACENADOS - Claudia Navarrete

-- Registrar la compra de uno o más tiques para una función
CREATE OR REPLACE PROCEDURE sp_registrar_compra(
    p_idusuario  BIGINT,
    p_idfuncion  BIGINT,
    p_asientos   BIGINT[],         
    p_metodopago VARCHAR            
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_idpago BIGINT;
    v_total  NUMERIC(10,2);
    v_n      INT;
    r        RECORD;
BEGIN

    -- 1. Validaciones de entrada
    IF p_asientos IS NULL OR cardinality(p_asientos) = 0 THEN
        RAISE EXCEPTION 'Debe indicar al menos un asiento';
    END IF;

    IF (SELECT COUNT(DISTINCT a) FROM unnest(p_asientos) AS a) <> cardinality(p_asientos) THEN
        RAISE EXCEPTION 'La lista de asientos tiene valores repetidos';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM usuario WHERE idusuario = p_idusuario AND estado = 'activo') THEN
        RAISE EXCEPTION 'El usuario % no existe o no está activo', p_idusuario;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM funcion WHERE idfuncion = p_idfuncion) THEN
        RAISE EXCEPTION 'La función % no existe', p_idfuncion;
    END IF;

    -- 2. Validar que TODOS los asientos estén disponibles (y bloquearlos para que nadie más los compre al mismo tiempo)
    SELECT COUNT(*), SUM(precio)
      INTO v_n, v_total
      FROM (SELECT precio
              FROM tarifa
             WHERE idfuncion = p_idfuncion
               AND idasiento = ANY (p_asientos)
               AND estado = 'disponible'
               FOR UPDATE) AS t;

    IF v_n <> cardinality(p_asientos) THEN
        RAISE EXCEPTION 'Uno o más asientos no están disponibles para la función %', p_idfuncion;
    END IF;

    -- 3. Registrar el pago
    INSERT INTO pago (fecha, hora, montoTotal, metodoPago, estado, idusuario)
    VALUES (CURRENT_DATE, CURRENT_TIME, v_total, p_metodopago, 'completado', p_idusuario)
    RETURNING idpago INTO v_idpago;

    -- 4. Registrar un tique por asiento y marcar la tarifa como vendida
    FOR r IN SELECT idtarifa, precio
               FROM tarifa
              WHERE idfuncion = p_idfuncion
                AND idasiento = ANY (p_asientos)
              ORDER BY idtarifa
    LOOP
        INSERT INTO tique (codigo, preciopagado, idprecio, idpago, idusuario)
        VALUES (gen_random_uuid()::text, r.precio, r.idtarifa, v_idpago, p_idusuario);

        UPDATE tarifa SET estado = 'vendido' WHERE idtarifa = r.idtarifa;
    END LOOP;

    RAISE NOTICE 'Compra registrada: pago % | % tique(s) | total %', v_idpago, v_n, v_total;
END;
$$;



-- Cancelar una compra (se cancela el pago completo y todos sus tiques)
CREATE OR REPLACE PROCEDURE sp_cancelar_compra(p_idpago BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_pago VARCHAR;
    v_n           INT;
BEGIN
    SELECT estado INTO v_estado_pago FROM pago WHERE idpago = p_idpago FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El pago % no existe', p_idpago;
    END IF;

    IF v_estado_pago <> 'completado' THEN
        RAISE EXCEPTION 'Solo se pueden cancelar compras completadas (el pago % está %)', p_idpago, v_estado_pago;
    END IF;

    IF EXISTS (SELECT 1 FROM tique WHERE idpago = p_idpago AND estado = 'usado') THEN
        RAISE EXCEPTION 'No se puede cancelar: el pago % tiene tiques ya usados', p_idpago;
    END IF;

    -- Liberar los asientos (las tarifas vuelven a estar disponibles)
    UPDATE tarifa
       SET estado = 'disponible'
     WHERE idtarifa IN (SELECT idprecio FROM tique WHERE idpago = p_idpago AND estado = 'emitido');

    -- Cancelar los tiques (no se borran, para conservar el historial)
    UPDATE tique SET estado = 'cancelado'
     WHERE idpago = p_idpago AND estado = 'emitido';
    GET DIAGNOSTICS v_n = ROW_COUNT;

    IF v_n = 0 THEN
        RAISE EXCEPTION 'El pago % no tiene tiques para cancelar', p_idpago;
    END IF;

    UPDATE pago SET estado = 'reembolsado' WHERE idpago = p_idpago;

    RAISE NOTICE 'Compra % cancelada: % tique(s) cancelado(s) y asientos liberados', p_idpago, v_n;
END;
$$;

-- =====================================================================
-- 2. FUNCIONES Y TRIGGER DE VALIDACION DE TIEMPO
-- =====================================================================
-- Se eliminan las versiones con parametro INT para que no queden dos
-- versiones de la misma funcion.
DROP FUNCTION IF EXISTS fn_asientos_disponibles(INT);
DROP FUNCTION IF EXISTS fn_ingresos_evento(INT);

-- Funciones y validación de tiempo para el sistema

CREATE OR REPLACE FUNCTION fn_asientos_disponibles(p_idfuncion BIGINT)
RETURNS INT AS $$
DECLARE
    v_disponibles INT;
BEGIN
    SELECT COUNT(*)
    INTO v_disponibles
    FROM tarifa t
    WHERE t.idfuncion = p_idfuncion
      AND t.estado = 'disponible';
      
    RETURN v_disponibles;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_ingresos_evento(p_idevento BIGINT)
RETURNS NUMERIC AS $$
DECLARE
    v_total_ingresos NUMERIC;
BEGIN
    SELECT COALESCE(SUM(ti.preciopagado), 0)
    INTO v_total_ingresos
    FROM pago p
    JOIN tique ti ON p.idpago = ti.idpago
    JOIN tarifa ta ON ti.idprecio = ta.idtarifa
    JOIN funcion f ON ta.idfuncion = f.idfuncion
    WHERE f.idevento = p_idevento
      AND p.estado = 'completado'
      AND ti.estado != 'cancelado';
      
    RETURN v_total_ingresos;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION trg_fn_validar_funcion_vigente()
RETURNS TRIGGER AS $$
DECLARE
    v_fecha_funcion DATE;
    v_hora_funcion TIME;
    v_estado_funcion VARCHAR(255);
BEGIN
    SELECT f.fecha, f.hora, f.estado
    INTO v_fecha_funcion, v_hora_funcion, v_estado_funcion
    FROM tarifa ta
    JOIN funcion f ON ta.idfuncion = f.idfuncion
    WHERE ta.idtarifa = NEW.idprecio;

    IF (v_fecha_funcion + v_hora_funcion) < CURRENT_TIMESTAMP OR v_estado_funcion IN ('finalizada', 'cancelada') THEN
        RAISE EXCEPTION 'Operación rechazada: No se pueden vender tiques para una función que ya pasó, está finalizada o cancelada.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trg_validar_funcion_vigente ON tique;
CREATE TRIGGER trg_validar_funcion_vigente
    BEFORE INSERT ON tique
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_validar_funcion_vigente();

-- =====================================================================
-- PARTE 3a - AUDITORIA DE VENTAS
-- Cada vez que se inserta un tique (una venta), queda registrado
-- automaticamente: id del tique, fecha de la venta y usuario.
-- Nombres acordados: tabla auditoria_venta_tique y
-- trigger trg_auditar_venta_tique (AFTER INSERT en tique).
-- =====================================================================

-- Se limpia primero para poder ejecutar el script varias veces
DROP TRIGGER  IF EXISTS trg_auditar_venta_tique ON tique;
DROP FUNCTION IF EXISTS trg_fn_auditar_venta_tique();
DROP TABLE    IF EXISTS auditoria_venta_tique;

CREATE TABLE auditoria_venta_tique (
    idauditoria BIGINT GENERATED ALWAYS AS IDENTITY,
    idtique     BIGINT       NOT NULL,
    fecha_venta TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    idusuario   BIGINT       NOT NULL,   -- cliente que realizo la compra
    usuario_bd  VARCHAR(255) NOT NULL DEFAULT CURRENT_USER,  -- rol de PostgreSQL que ejecuto la operacion
    CONSTRAINT pk_auditoria_venta_tique PRIMARY KEY (idauditoria),
    CONSTRAINT fk_auditoria_tique   FOREIGN KEY (idtique)
        REFERENCES tique (idtique)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,            -- el historial de auditoria no se pierde borrando el tique
    CONSTRAINT fk_auditoria_usuario FOREIGN KEY (idusuario)
        REFERENCES usuario (idusuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE OR REPLACE FUNCTION trg_fn_auditar_venta_tique()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO auditoria_venta_tique (idtique, fecha_venta, idusuario)
    VALUES (NEW.idtique, CURRENT_TIMESTAMP, NEW.idusuario);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- AFTER INSERT: se audita solo cuando el tique ya fue aceptado
-- (si trg_validar_funcion_vigente lo rechaza, no queda registro).
CREATE TRIGGER trg_auditar_venta_tique
    AFTER INSERT ON tique
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_auditar_venta_tique();


-- =====================================================================
-- PRUEBAS EJECUTADAS
-- Requisito: base recien cargada con preparar_bd.sql (la compra exitosa
-- genera el pago 301). Ejecutar las pruebas UNA sola vez por carga.
-- La funcion 29 es del 25/11/2026: si el script se ejecuta cuando esa fecha
-- ya paso, el paso PREPARACION la mueve 30 dias hacia adelante para que las
-- pruebas funcionen igual en cualquier fecha (antes del 25/11 no cambia nada).
-- Las pruebas que DEBEN fallar estan dentro de un bloque DO que atrapa el
-- error y muestra el mensaje (pestana Messages), para que el script corra
-- completo. Para ver el error real, ejecutar solo la linea CALL indicada.
-- Si se ejecuta en pgAdmin, correr cada bloque seleccionandolo (F5).
-- =====================================================================

-- ---------------------------------------------------------------------
-- PREPARACION: la funcion 29 debe ser futura para poder venderle tiques.
-- Si su fecha y hora ya pasaron (o faltan menos de 24 horas), se mueve a
-- 30 dias desde hoy. Si todavia es futura, el UPDATE no modifica ninguna fila.
-- ---------------------------------------------------------------------
SELECT idfuncion, fecha, hora, estado FROM funcion WHERE idfuncion = 29;

UPDATE funcion
   SET fecha = CURRENT_DATE + 30
 WHERE idfuncion = 29
   AND fecha + hora < CURRENT_TIMESTAMP + INTERVAL '1 day';

SELECT idfuncion, fecha, hora, estado FROM funcion WHERE idfuncion = 29;


-- ---------------------------------------------------------------------
-- 0. ESTADO INICIAL (funcion 29, evento 6, usuario 5)
-- ---------------------------------------------------------------------
SELECT (SELECT COUNT(*) FROM pago)                    AS pagos,
       (SELECT COUNT(*) FROM tique)                   AS tiques,
       (SELECT COUNT(*) FROM auditoria_venta_tique)   AS filas_auditoria,
       fn_asientos_disponibles(29)                    AS asientos_libres_func29,
       fn_ingresos_evento(6)                          AS ingresos_evento6;


-- ---------------------------------------------------------------------
-- 1. COMPRA EXITOSA: usuario 5 compra los asientos 8 y 10 de la funcion 29
-- ---------------------------------------------------------------------
CALL sp_registrar_compra(5, 29, ARRAY[8, 10], 'tarjeta_credito');

-- Verificacion: pago completado, tiques emitidos y tarifas vendidas
SELECT p.idpago, p.montototal, p.estado AS estado_pago,
       t.idtique, t.codigo, t.preciopagado, t.estado AS estado_tique,
       r.idasiento, r.estado AS estado_tarifa
  FROM pago p
  JOIN tique t  USING (idpago)
  JOIN tarifa r ON r.idtarifa = t.idprecio
 WHERE p.idpago = (SELECT MAX(idpago) FROM pago)
 ORDER BY r.idasiento;

-- Verificacion de la AUDITORIA: cada tique vendido quedo registrado solo
SELECT a.idauditoria, a.idtique, a.fecha_venta, a.idusuario, a.usuario_bd
  FROM auditoria_venta_tique a
 ORDER BY a.idauditoria;

-- Verificacion de las FUNCIONES: bajaron 2 asientos y subieron los ingresos
SELECT fn_asientos_disponibles(29) AS asientos_libres_func29,   -- era 34, ahora 32
       fn_ingresos_evento(6)       AS ingresos_evento6;         -- sube el monto del pago


-- ---------------------------------------------------------------------
-- 2. COMPRA FALLIDA (ROLLBACK): usuario 6 pide el asiento 14 (libre) y el 8
--    (ya vendido en la prueba 1). Todo o nada: no debe quedar nada a medias.
-- ---------------------------------------------------------------------
SELECT (SELECT COUNT(*) FROM pago)                  AS pagos_antes,
       (SELECT COUNT(*) FROM tique)                 AS tiques_antes,
       (SELECT COUNT(*) FROM auditoria_venta_tique) AS auditoria_antes,
       (SELECT estado FROM tarifa WHERE idfuncion = 29 AND idasiento = 14) AS estado_asiento_14;

-- Para ver el error real, ejecutar solo la linea:
--   CALL sp_registrar_compra(6, 29, ARRAY[14, 8], 'efectivo');
DO $$
BEGIN
    CALL sp_registrar_compra(6, 29, ARRAY[14, 8], 'efectivo');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'COMPRA RECHAZADA Y DESHECHA: %', SQLERRM;
END $$;

SELECT (SELECT COUNT(*) FROM pago)                  AS pagos_despues,
       (SELECT COUNT(*) FROM tique)                 AS tiques_despues,
       (SELECT COUNT(*) FROM auditoria_venta_tique) AS auditoria_despues,
       (SELECT estado FROM tarifa WHERE idfuncion = 29 AND idasiento = 14) AS estado_asiento_14;  -- sigue 'disponible'


-- ---------------------------------------------------------------------
-- 3. CANCELACION de la compra de la prueba 1 (pago 301)
-- ---------------------------------------------------------------------
CALL sp_cancelar_compra(301);

SELECT p.idpago, p.estado AS estado_pago,                 -- reembolsado
       t.idtique, t.estado AS estado_tique,               -- cancelado
       r.idasiento, r.estado AS estado_tarifa             -- disponible otra vez
  FROM pago p
  JOIN tique t  USING (idpago)
  JOIN tarifa r ON r.idtarifa = t.idprecio
 WHERE p.idpago = 301
 ORDER BY r.idasiento;

-- Las funciones vuelven al valor inicial y la auditoria conserva el historial
SELECT fn_asientos_disponibles(29) AS asientos_libres_func29,   -- vuelve a 34
       fn_ingresos_evento(6)       AS ingresos_evento6,         -- vuelve al valor inicial
       (SELECT COUNT(*) FROM auditoria_venta_tique) AS filas_auditoria;  -- siguen las 2 de la venta


-- ---------------------------------------------------------------------
-- 4. ERRORES CONTROLADOS de los procedimientos
--    Para ver el error real, ejecutar solo la linea CALL de cada uno.
-- ---------------------------------------------------------------------
-- CALL sp_cancelar_compra(301);      -- ya esta reembolsado
DO $$
BEGIN
    CALL sp_cancelar_compra(301);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'RECHAZADO: %', SQLERRM;
END $$;

-- CALL sp_cancelar_compra(99999);    -- pago inexistente
DO $$
BEGIN
    CALL sp_cancelar_compra(99999);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'RECHAZADO: %', SQLERRM;
END $$;

-- CALL sp_registrar_compra(999, 29, ARRAY[16], 'efectivo');   -- usuario inexistente
DO $$
BEGIN
    CALL sp_registrar_compra(999, 29, ARRAY[16], 'efectivo');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'RECHAZADO: %', SQLERRM;
END $$;


-- ---------------------------------------------------------------------
-- 5. TRIGGER DE TIEMPO: no se vende para funciones que ya pasaron o
--    estan finalizadas. La auditoria NO debe registrar nada de esto.
-- ---------------------------------------------------------------------
SELECT (SELECT COUNT(*) FROM pago)                  AS pagos_antes,
       (SELECT COUNT(*) FROM tique)                 AS tiques_antes,
       (SELECT COUNT(*) FROM auditoria_venta_tique) AS auditoria_antes;

-- 5a. Funcion 50 (13/11/2026, ya paso) con asientos libres: el procedimiento
--     crea el pago, pero el trigger rechaza el tique y TODO se deshace.
-- Para ver el error real, ejecutar solo la linea:
--   CALL sp_registrar_compra(5, 50, ARRAY[8, 10], 'tarjeta_credito');
DO $$
BEGIN
    CALL sp_registrar_compra(5, 50, ARRAY[8, 10], 'tarjeta_credito');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'VENTA RECHAZADA (funcion que ya paso): %', SQLERRM;
END $$;

-- 5b. Funcion 25 (finalizada): intento de insertar un tique directamente.
-- Para ver el error real, ejecutar solo el INSERT.
DO $$
BEGIN
    INSERT INTO tique (codigo, preciopagado, idprecio, idpago, idusuario)
    SELECT 'PRUEBA-FINALIZADA', precio, idtarifa, 1, 1
      FROM tarifa
     WHERE idfuncion = 25
     ORDER BY idtarifa
     LIMIT 1;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'VENTA RECHAZADA (funcion finalizada): %', SQLERRM;
END $$;

SELECT (SELECT COUNT(*) FROM pago)                  AS pagos_despues,      -- igual que antes
       (SELECT COUNT(*) FROM tique)                 AS tiques_despues,     -- igual que antes
       (SELECT COUNT(*) FROM auditoria_venta_tique) AS auditoria_despues,  -- igual que antes
       (SELECT estado FROM tarifa WHERE idfuncion = 50 AND idasiento = 8) AS estado_asiento_8_func50;  -- sigue 'disponible'

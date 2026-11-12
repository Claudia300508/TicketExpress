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
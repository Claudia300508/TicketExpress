-- Funciones y validación de tiempo para el sistema

CREATE OR REPLACE FUNCTION fn_asientos_disponibles(p_idfuncion INT)
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


CREATE OR REPLACE FUNCTION fn_ingresos_evento(p_idevento INT)
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
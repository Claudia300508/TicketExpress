-- Asientos libres de la función 50
SELECT idasiento, precio
  FROM tarifa
 WHERE idfuncion = 50 AND estado = 'disponible'
 ORDER BY idasiento
 LIMIT 2;

-- COMPRA EXITOSA (cambia los asientos por los que salieron arriba)
CALL sp_registrar_compra(5, 50, ARRAY[8, 10], 'tarjeta_credito');

-- Verificar la compra
SELECT p.idpago, p.montototal, p.estado AS estado_pago,
       t.idtique, t.preciopagado, t.estado AS estado_tique,
       r.idasiento, r.estado AS estado_tarifa
  FROM pago p
  JOIN tique t  USING (idpago)
  JOIN tarifa r ON r.idtarifa = t.idprecio
 WHERE p.idpago = (SELECT MAX(idpago) FROM pago);

-- COMPRA FALLIDA (rollback): un asiento libre + uno ya vendido
SELECT (SELECT COUNT(*) FROM pago)  AS pagos_antes,
       (SELECT COUNT(*) FROM tique) AS tiques_antes;

-- El asiento 8 ya está vendido; cambia el 14 por un asiento libre
CALL sp_registrar_compra(5, 50, ARRAY[14, 8], 'efectivo');

SELECT (SELECT COUNT(*) FROM pago)  AS pagos_despues,
       (SELECT COUNT(*) FROM tique) AS tiques_despues;


-- CANCELACIÓN (cambia 301 por el idpago de la compra exitosa)
CALL sp_cancelar_compra(301);

SELECT p.idpago, p.estado AS estado_pago,
       t.idtique, t.estado AS estado_tique,
       r.idasiento, r.estado AS estado_tarifa
  FROM pago p
  JOIN tique t  USING (idpago)
  JOIN tarifa r ON r.idtarifa = t.idprecio
 WHERE p.idpago = 301;

-- ERRORES CONTROLADOS
CALL sp_cancelar_compra(301);                     
CALL sp_cancelar_compra(99999);                    
CALL sp_registrar_compra(999, 50, ARRAY[1], 'efectivo');
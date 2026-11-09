-- =====================================================================
-- TicketExpress+  |  Semana 5 - Parte 2 y Parte 3
-- Validación de volumen de datos y preguntas analíticas
-- Motor: PostgreSQL   |   Base de datos: ticketexpress
-- (Ejecutar DESPUÉS de importar los CSV)
-- =====================================================================

-- ---------------------------------------------------------------------
-- CRITERIO DE "TIQUE VENDIDO"
-- Un tique cuenta como vendido cuando:
--   * su pago está 'completado' (el dinero realmente entró), y
--   * el tique no está 'cancelado'.
-- Se deja fuera lo que NO es una venta real: pagos rechazados,
-- pendientes o reembolsados, y tiques cancelados.
-- Se guarda como vista para no repetir la condición en cada pregunta.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_tiques_vendidos AS
SELECT  t.idtique,
        t.preciopagado,
        t.idusuario,
        t.idprecio AS idtarifa,
        ta.idfuncion,
        f.idevento
FROM    tique   t
JOIN    pago    p  ON p.idpago     = t.idpago
JOIN    tarifa  ta ON ta.idtarifa  = t.idprecio
JOIN    funcion f  ON f.idfuncion  = ta.idfuncion
WHERE   p.estado = 'completado'
  AND   t.estado <> 'cancelado';


-- =====================================================================
-- PARTE 2 - Total de registros por tabla
-- =====================================================================
SELECT 'categoria' AS tabla, COUNT(*) AS total_registros FROM categoria
UNION ALL SELECT 'recinto',  COUNT(*) FROM recinto
UNION ALL SELECT 'usuario',  COUNT(*) FROM usuario
UNION ALL SELECT 'evento',   COUNT(*) FROM evento
UNION ALL SELECT 'asiento',  COUNT(*) FROM asiento
UNION ALL SELECT 'funcion',  COUNT(*) FROM funcion
UNION ALL SELECT 'pago',     COUNT(*) FROM pago
UNION ALL SELECT 'tarifa',   COUNT(*) FROM tarifa
UNION ALL SELECT 'tique',    COUNT(*) FROM tique
ORDER BY total_registros DESC, tabla;


-- =====================================================================
-- PARTE 3 - Preguntas analíticas
-- =====================================================================

-- ---------------------------------------------------------------------
-- Pregunta 1: ¿Cuál es el evento con mayor cantidad de tiques vendidos?
-- Ruta: tique -> tarifa -> funcion -> evento (dentro de la vista).
-- WITH TIES: si hay empate en el primer lugar, salen todos los empatados.
-- ---------------------------------------------------------------------
SELECT  e.idevento,
        e.nombre            AS evento,
        COUNT(*)            AS tiques_vendidos
FROM    v_tiques_vendidos v
JOIN    evento e ON e.idevento = v.idevento
GROUP BY e.idevento, e.nombre
ORDER BY tiques_vendidos DESC
FETCH FIRST 1 ROWS WITH TIES;


-- ---------------------------------------------------------------------
-- Pregunta 2: ¿Cuál es el ingreso total generado por cada evento?
-- Se suma preciopagado de los tiques vendidos. LEFT JOIN para que
-- aparezcan también los eventos sin ventas (con ingreso 0).
-- ---------------------------------------------------------------------
SELECT  e.idevento,
        e.nombre                              AS evento,
        COUNT(v.idtique)                      AS tiques_vendidos,
        COALESCE(SUM(v.preciopagado), 0)      AS ingreso_total
FROM    evento e
LEFT JOIN v_tiques_vendidos v ON v.idevento = e.idevento
GROUP BY e.idevento, e.nombre
ORDER BY ingreso_total DESC, e.nombre;


-- ---------------------------------------------------------------------
-- Pregunta 3: ¿Qué cliente ha comprado más tiques y cuántos adquirió?
-- ---------------------------------------------------------------------
SELECT  u.idusuario,
        u.nombre || ' ' || u.apellido   AS cliente,
        COUNT(*)                        AS tiques_comprados
FROM    v_tiques_vendidos v
JOIN    usuario u ON u.idusuario = v.idusuario
GROUP BY u.idusuario, u.nombre, u.apellido
ORDER BY tiques_comprados DESC
FETCH FIRST 1 ROWS WITH TIES;


-- ---------------------------------------------------------------------
-- Pregunta 4: ¿Qué funciones superan el 70% de ocupación?
-- Asientos disponibles de una función = sus tarifas (un asiento por
-- tarifa, todos del recinto de la función).
-- Ocupación = tiques vendidos / asientos de la función * 100.
-- ---------------------------------------------------------------------
SELECT  f.idfuncion,
        e.nombre                                         AS evento,
        f.fecha,
        f.hora,
        COUNT(DISTINCT ta.idtarifa)                      AS asientos_disponibles,
        COUNT(DISTINCT v.idtique)                        AS asientos_vendidos,
        ROUND(100.0 * COUNT(DISTINCT v.idtique)
                    / COUNT(DISTINCT ta.idtarifa), 2)    AS porcentaje_ocupacion
FROM    funcion f
JOIN    evento  e  ON e.idevento   = f.idevento
JOIN    tarifa  ta ON ta.idfuncion = f.idfuncion
LEFT JOIN v_tiques_vendidos v ON v.idtarifa = ta.idtarifa
GROUP BY f.idfuncion, e.nombre, f.fecha, f.hora
HAVING  100.0 * COUNT(DISTINCT v.idtique) / COUNT(DISTINCT ta.idtarifa) > 70
ORDER BY porcentaje_ocupacion DESC, f.idfuncion;


-- ---------------------------------------------------------------------
-- Pregunta 5: ¿Existen funciones sin ninguna venta? Listarlas.
-- NOT EXISTS: funciones para las que no hay ningún tique vendido.
-- ---------------------------------------------------------------------
SELECT  f.idfuncion,
        e.nombre   AS evento,
        r.nombre   AS recinto,
        f.fecha,
        f.hora,
        f.estado
FROM    funcion f
JOIN    evento  e ON e.idevento  = f.idevento
JOIN    recinto r ON r.idrecinto = f.idrecinto
WHERE   NOT EXISTS (SELECT 1
                    FROM   v_tiques_vendidos v
                    WHERE  v.idfuncion = f.idfuncion)
ORDER BY f.idfuncion;


-- =====================================================================
-- EXTRA (Parte 1, punto 4) - Verificación de integridad referencial
-- Cuenta los registros "huérfanos" de cada llave foránea.
-- Todos los resultados deben ser 0.
-- =====================================================================
SELECT 'evento -> categoria'  AS relacion, COUNT(*) AS huerfanos
FROM evento e   WHERE NOT EXISTS (SELECT 1 FROM categoria c WHERE c.idcategoria = e.idcategoria)
UNION ALL SELECT 'asiento -> recinto', COUNT(*)
FROM asiento a  WHERE NOT EXISTS (SELECT 1 FROM recinto r   WHERE r.idrecinto   = a.idrecinto)
UNION ALL SELECT 'funcion -> evento', COUNT(*)
FROM funcion f  WHERE NOT EXISTS (SELECT 1 FROM evento e    WHERE e.idevento    = f.idevento)
UNION ALL SELECT 'funcion -> recinto', COUNT(*)
FROM funcion f  WHERE NOT EXISTS (SELECT 1 FROM recinto r   WHERE r.idrecinto   = f.idrecinto)
UNION ALL SELECT 'pago -> usuario', COUNT(*)
FROM pago p     WHERE NOT EXISTS (SELECT 1 FROM usuario u   WHERE u.idusuario   = p.idusuario)
UNION ALL SELECT 'tarifa -> funcion', COUNT(*)
FROM tarifa ta  WHERE NOT EXISTS (SELECT 1 FROM funcion f   WHERE f.idfuncion   = ta.idfuncion)
UNION ALL SELECT 'tarifa -> asiento', COUNT(*)
FROM tarifa ta  WHERE NOT EXISTS (SELECT 1 FROM asiento a   WHERE a.idasiento   = ta.idasiento)
UNION ALL SELECT 'tique -> tarifa', COUNT(*)
FROM tique t    WHERE NOT EXISTS (SELECT 1 FROM tarifa ta   WHERE ta.idtarifa   = t.idprecio)
UNION ALL SELECT 'tique -> pago', COUNT(*)
FROM tique t    WHERE NOT EXISTS (SELECT 1 FROM pago p      WHERE p.idpago      = t.idpago)
UNION ALL SELECT 'tique -> usuario', COUNT(*)
FROM tique t    WHERE NOT EXISTS (SELECT 1 FROM usuario u   WHERE u.idusuario   = t.idusuario);

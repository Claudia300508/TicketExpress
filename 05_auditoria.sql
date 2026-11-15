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

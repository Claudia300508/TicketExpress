CREATE TABLE tique (
    idtique BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(255) NOT NULL UNIQUE,
    preciopagado DECIMAL(10, 2) NOT NULL CHECK (preciopagado >= 0),
    fechaemision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(50) NOT NULL DEFAULT 'VENDIDO'
        CHECK (estado IN ('RESERVADO', 'VENDIDO', 'CANCELADO', 'USADO')),
    idprecio BIGINT NOT NULL,
    idpago BIGINT,
    idusuario BIGINT NOT NULL,
    
    CONSTRAINT fk_tique_tarifa FOREIGN KEY (idprecio)
        REFERENCES tarifa(idtarifa)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
        
    CONSTRAINT fk_tique_pago FOREIGN KEY (idpago)
        REFERENCES pago(idpago)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
        
    CONSTRAINT fk_tique_usuario FOREIGN KEY (idusuario)
        REFERENCES usuario(idusuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);
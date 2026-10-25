CREATE TABLE Categoria (
    idcategoria BIGINT PRIMARY KEY,
    categoria VARCHAR(255) NOT NULL
);

CREATE TABLE recinto (
    idrecinto BIGINT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    ciudad VARCHAR(255) NOT NULL,
    capacidadTotal INT NOT NUL
);

CREATE TABLE evento (
    idevento BIGINT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion VARCHAR(255),
    idcategoria BIGINT NOT NULL,
    CONSTRAINT fk_evento_categoria FOREIGN KEY (idcategoria) 
        REFERENCES Categoria(idcategoria)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE asiento (
    idasiento BIGINT PRIMARY KEY,
    fila VARCHAR(255) NOT NULL,
    numero VARCHAR(255) NOT NULL,
    zona VARCHAR(255) NOT NULL,
    idrecinto BIGINT NOT NULL,
    CONSTRAINT fk_asiento_recinto FOREIGN KEY (idrecinto) 
        REFERENCES recinto(idrecinto)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE funcion (
    idfuncion BIGINT PRIMARY KEY,
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    idevento BIGINT NOT NULL,
    idrecinto BIGINT NOT NULL,
    estado VARCHAR(255) NOT NULL,
    CONSTRAINT fk_funcion_evento FOREIGN KEY (idevento) 
        REFERENCES evento(idevento)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_funcion_recinto FOREIGN KEY (idrecinto) 
        REFERENCES recinto(idrecinto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

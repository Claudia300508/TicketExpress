CREATE TABLE categoria (
    id_categoria SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT
);

CREATE TABLE recinto (
    id_recinto SERIAL PRIMARY KEY,
    nombre_recinto VARCHAR(100) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    capacidad_maxima INT NOT NULL CHECK (capacidad_maxima > 0)
);

CREATE TABLE evento (
    id_evento SERIAL PRIMARY KEY,
    nombre_evento VARCHAR(150) NOT NULL,
    descripcion TEXT,
    fecha_inicio TIMESTAMP NOT NULL,
    fecha_fin TIMESTAMP NOT NULL,
    id_categoria INT NOT NULL,
    CONSTRAINT fk_evento_categoria FOREIGN KEY (id_categoria) 
        REFERENCES categoria(id_categoria)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_fechas_evento CHECK (fecha_fin >= fecha_inicio)
);

CREATE TABLE asiento (
    id_asiento SERIAL PRIMARY KEY,
    numero_asiento VARCHAR(10) NOT NULL,
    fila VARCHAR(10) NOT NULL,
    seccion VARCHAR(50) NOT NULL,
    id_recinto INT NOT NULL,
    CONSTRAINT fk_asiento_recinto FOREIGN KEY (id_recinto) 
        REFERENCES recinto(id_recinto)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE funcion (
    id_funcion SERIAL PRIMARY KEY,
    fecha_hora_funcion TIMESTAMP NOT NULL,
    id_evento INT NOT NULL,
    id_recinto INT NOT NULL,
    CONSTRAINT fk_funcion_evento FOREIGN KEY (id_evento) 
        REFERENCES evento(id_evento)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_funcion_recinto FOREIGN KEY (id_recinto) 
        REFERENCES recinto(id_recinto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);
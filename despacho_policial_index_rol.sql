-- Active: 1776781492297@@127.0.0.1@5434@despacho_policial
CREATE TABLE catalogo_roles (
    id          SMALLSERIAL     PRIMARY KEY,
    codigo      VARCHAR(40)     NOT NULL UNIQUE,
    descripcion VARCHAR(100)    NOT NULL,
    activo      BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_catalogo_roles_codigo CHECK (codigo = UPPER(codigo))
);

COMMENT ON TABLE  catalogo_roles              IS 'Roles de acceso al sistema';
COMMENT ON COLUMN catalogo_roles.codigo       IS 'ADMIN, OPERADOR, OFICIAL_CAMPO, SUPERVISOR, AUDITOR';
COMMENT ON COLUMN catalogo_roles.activo       IS 'FALSE = soft delete';

CREATE TABLE catalogo_rangos (
    id          SMALLSERIAL     PRIMARY KEY,
    codigo      VARCHAR(50)     NOT NULL UNIQUE,
    descripcion VARCHAR(100)    NOT NULL,
    nivel       SMALLINT        NOT NULL,
    activo      BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_catalogo_rangos_nivel  CHECK (nivel BETWEEN 1 AND 20),
    CONSTRAINT chk_catalogo_rangos_codigo CHECK (codigo = UPPER(codigo))
);

COMMENT ON TABLE  catalogo_rangos              IS 'Jerarquía de rangos policiales municipales';
COMMENT ON COLUMN catalogo_rangos.nivel        IS '1 = menor jerarquía, 20 = mayor jerarquía';
COMMENT ON COLUMN catalogo_rangos.codigo       IS 'POLICIA_RASO, CABO, SARGENTO_PRIMERO, INSPECTOR, etc.';

CREATE TABLE catalogo_tipos_vehiculos (
    id          SMALLSERIAL     PRIMARY KEY,
    codigo      VARCHAR(40)     NOT NULL UNIQUE,
    descripcion VARCHAR(100)    NOT NULL,
    activo      BOOLEAN         NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE  catalogo_tipos_vehiculos        IS 'Tipos de vehículos policiales';
COMMENT ON COLUMN catalogo_tipos_vehiculos.codigo IS 'PATRULLA, MOTOCICLETA, CAMIONETA, AMBULANCIA, etc.';

CREATE TABLE catalogo_estados_unidades (
    id                   SMALLSERIAL  PRIMARY KEY,
    codigo               VARCHAR(30)  NOT NULL UNIQUE,
    descripcion          VARCHAR(100) NOT NULL,
    disponible_despacho  BOOLEAN      NOT NULL,
    es_operativo         BOOLEAN      NOT NULL,
    es_terminal          BOOLEAN      NOT NULL DEFAULT FALSE,
    activo               BOOLEAN      NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_catalogo_estados_unidades_codigo CHECK (codigo = UPPER(codigo))
);

COMMENT ON TABLE  catalogo_estados_unidades                      IS 'Estados operativos de unidades policiales';
COMMENT ON COLUMN catalogo_estados_unidades.disponible_despacho  IS 'TRUE = puede recibir un despacho nuevo';
COMMENT ON COLUMN catalogo_estados_unidades.es_operativo         IS 'TRUE = cuenta en estadísticas de flota activa';
COMMENT ON COLUMN catalogo_estados_unidades.es_terminal          IS 'TRUE = BAJA_DEFINITIVA, no puede cambiar de estado';

CREATE TABLE catalogo_estados_despachos (
    id           SMALLSERIAL  PRIMARY KEY,
    codigo       VARCHAR(30)  NOT NULL UNIQUE,
    descripcion  VARCHAR(100) NOT NULL,
    requiere_gps BOOLEAN      NOT NULL,
    es_terminal  BOOLEAN      NOT NULL DEFAULT FALSE,
    orden        SMALLINT     NOT NULL,
    activo       BOOLEAN      NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_catalogo_estados_despachos_codigo CHECK (codigo = UPPER(codigo))
);

COMMENT ON TABLE  catalogo_estados_despachos              IS 'Estados del ciclo de vida de un despacho';
COMMENT ON COLUMN catalogo_estados_despachos.requiere_gps IS 'TRUE = debe existir evidencia GPS válida para entrar a este estado';
COMMENT ON COLUMN catalogo_estados_despachos.es_terminal  IS 'TRUE = CERRADO o CANCELADO, no admite más transiciones';
COMMENT ON COLUMN catalogo_estados_despachos.orden        IS 'Secuencia lógica para validar transiciones en triggers';

CREATE TABLE catalogo_categorias_incidentes (
    id          SMALLSERIAL     PRIMARY KEY,
    codigo      VARCHAR(40)     NOT NULL UNIQUE,
    descripcion VARCHAR(100)    NOT NULL,
    activo      BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_catalogo_categorias_incidentes_codigo CHECK (codigo = UPPER(codigo))
);

COMMENT ON TABLE catalogo_categorias_incidentes IS 'Categorías agrupadoras de tipos de incidente';

CREATE TABLE catalogo_tipos_incidentes (
    id                SMALLSERIAL  PRIMARY KEY,
    id_categoria      SMALLINT     NOT NULL REFERENCES catalogo_categorias_incidentes(id),
    codigo            VARCHAR(60)  NOT NULL UNIQUE,
    descripcion       VARCHAR(150) NOT NULL,
    prioridad_default SMALLINT     NOT NULL,
    requiere_apoyo    BOOLEAN      NOT NULL DEFAULT FALSE,
    activo            BOOLEAN      NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_catalogo_tipos_incidentes_prioridad CHECK (prioridad_default BETWEEN 1 AND 4),
    CONSTRAINT chk_catalogo_tipos_incidentes_codigo    CHECK (codigo = UPPER(codigo))
);

COMMENT ON TABLE  catalogo_tipos_incidentes                  IS 'Tipos de incidente clasificados por categoría';
COMMENT ON COLUMN catalogo_tipos_incidentes.prioridad_default IS '1=baja, 2=media, 3=alta, 4=crítica';
COMMENT ON COLUMN catalogo_tipos_incidentes.requiere_apoyo    IS 'TRUE = suele necesitar más de una unidad';

CREATE TABLE catalogo_estados_incidentes (
    id                SMALLSERIAL  PRIMARY KEY,
    codigo            VARCHAR(30)  NOT NULL UNIQUE,
    descripcion       VARCHAR(100) NOT NULL,
    es_terminal       BOOLEAN      NOT NULL DEFAULT FALSE,
    requiere_despacho BOOLEAN      NOT NULL DEFAULT FALSE,
    orden             SMALLINT     NOT NULL,
    activo            BOOLEAN      NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_catalogo_estados_incidentes_codigo CHECK (codigo = UPPER(codigo))
);

COMMENT ON TABLE  catalogo_estados_incidentes                   IS 'Estados del ciclo de vida de un incidente';
COMMENT ON COLUMN catalogo_estados_incidentes.es_terminal       IS 'TRUE = CERRADO, CANCELADO o DERIVADO';
COMMENT ON COLUMN catalogo_estados_incidentes.requiere_despacho IS 'TRUE = debe existir al menos un despacho asociado';
COMMENT ON COLUMN catalogo_estados_incidentes.orden             IS 'Secuencia lógica para validar transiciones en triggers';

CREATE TABLE municipios (
    id        BIGSERIAL    PRIMARY KEY,
    nombre    VARCHAR(100) NOT NULL,
    estado    VARCHAR(80)  NOT NULL DEFAULT 'Tabasco',
    poblacion INT          NOT NULL,

    CONSTRAINT chk_municipios_poblacion CHECK (poblacion > 0)
);

COMMENT ON COLUMN municipios.estado IS 'Estado geográfico, no estado lógico del sistema';

CREATE TABLE corporaciones_policiales (
    id           BIGSERIAL    PRIMARY KEY,
    id_municipio BIGINT       NOT NULL REFERENCES municipios(id),
    nombre       VARCHAR(150) NOT NULL,
    telefono     VARCHAR(20)  NOT NULL,
    direccion    VARCHAR(200) NOT NULL
);

COMMENT ON TABLE corporaciones_policiales IS 'Corporaciones policiales municipales';

CREATE TABLE oficiales (
    id              BIGSERIAL    PRIMARY KEY,
    id_corporacion  BIGINT       NOT NULL REFERENCES corporaciones_policiales(id),
    nombre          VARCHAR(100) NOT NULL,
    apellido        VARCHAR(100) NOT NULL,
    num_placa       VARCHAR(30)  NOT NULL UNIQUE,
    activo          BOOLEAN      NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE  oficiales         IS 'Personal policial operativo';
COMMENT ON COLUMN oficiales.activo  IS 'FALSE = oficial inactivo o dado de baja';

CREATE TABLE unidades_policiales (
    id             BIGSERIAL    PRIMARY KEY,
    id_corporacion BIGINT       NOT NULL REFERENCES corporaciones_policiales(id),
    id_estado      SMALLINT     NOT NULL REFERENCES catalogo_estados_unidades(id),
    id_tipo        SMALLINT     NOT NULL REFERENCES catalogo_tipos_vehiculos(id),
    num_economico  VARCHAR(20)  NOT NULL UNIQUE,
    num_placas     VARCHAR(20)  NOT NULL UNIQUE,
    marca          VARCHAR(50)  NOT NULL,
    modelo         VARCHAR(50)  NOT NULL,
    anio           SMALLINT     NOT NULL,
    fecha_alta     DATE         NOT NULL,

    CONSTRAINT chk_unidades_anio CHECK (anio BETWEEN 1990 AND 2100)
);

COMMENT ON TABLE unidades_policiales IS 'Vehículos policiales asignados a corporaciones';

CREATE TABLE usuarios (
    id              BIGSERIAL    PRIMARY KEY,
    id_corporacion  BIGINT       NOT NULL REFERENCES corporaciones_policiales(id),
    id_oficial      BIGINT       NULL     REFERENCES oficiales(id),
    id_rol          SMALLINT     NOT NULL REFERENCES catalogo_roles(id),
    username        VARCHAR(60)  NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    nombres         VARCHAR(100) NOT NULL,
    apellidos       VARCHAR(100) NOT NULL,
    email           VARCHAR(120) NULL     UNIQUE,
    activo          BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_creacion  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    ultimo_acceso   TIMESTAMPTZ  NULL
);

COMMENT ON COLUMN usuarios.id_oficial IS 'NULL = usuario operador sin rol en campo (ej. despachador)';

CREATE TABLE oficial_rangos (
    id             BIGSERIAL    PRIMARY KEY,
    id_oficial     BIGINT       NOT NULL REFERENCES oficiales(id),
    id_rango       SMALLINT     NOT NULL REFERENCES catalogo_rangos(id),
    fecha_inicio   DATE         NOT NULL,
    fecha_fin      DATE         NULL,
    motivo_cambio  VARCHAR(200) NULL,

    CONSTRAINT chk_oficial_rangos_fechas CHECK (fecha_fin IS NULL OR fecha_fin > fecha_inicio)
);

COMMENT ON COLUMN oficial_rangos.fecha_fin IS 'NULL = rango actual vigente';

CREATE TABLE unidad_estados (
    id           BIGSERIAL    PRIMARY KEY,
    id_unidad    BIGINT       NOT NULL REFERENCES unidades_policiales(id),
    id_estado    SMALLINT     NOT NULL REFERENCES catalogo_estados_unidades(id),
    id_usuario   BIGINT       NOT NULL REFERENCES usuarios(id),
    fecha_cambio TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    motivo       VARCHAR(200) NULL
);

COMMENT ON TABLE  unidad_estados           IS 'Historial de cambios de estado de unidades policiales';
COMMENT ON COLUMN unidad_estados.id_usuario IS 'Usuario que registró el cambio de estado';

CREATE TABLE incidentes (
    id                 BIGSERIAL    PRIMARY KEY,
    id_corporacion     BIGINT       NOT NULL REFERENCES corporaciones_policiales(id),
    id_tipo            SMALLINT     NOT NULL REFERENCES catalogo_tipos_incidentes(id),
    id_estado          SMALLINT     NOT NULL REFERENCES catalogo_estados_incidentes(id),
    id_usuario_registro BIGINT      NOT NULL REFERENCES usuarios(id),
    folio              VARCHAR(30)  NOT NULL UNIQUE,
    descripcion        TEXT         NULL,
    prioridad          SMALLINT     NOT NULL,
    latitud_reporte    DECIMAL(10,7) NOT NULL,
    longitud_reporte   DECIMAL(10,7) NOT NULL,
    fecha_reporte      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    fecha_cierre       TIMESTAMPTZ  NULL,

    CONSTRAINT chk_incidentes_prioridad CHECK (prioridad BETWEEN 1 AND 4),
    CONSTRAINT chk_incidentes_latitud   CHECK (latitud_reporte  BETWEEN -90  AND 90),
    CONSTRAINT chk_incidentes_longitud  CHECK (longitud_reporte BETWEEN -180 AND 180)
);

COMMENT ON COLUMN incidentes.prioridad          IS '1=baja, 2=media, 3=alta, 4=crítica';
COMMENT ON COLUMN incidentes.id_usuario_registro IS 'Operador que capturó el reporte ciudadano';

CREATE TABLE incidente_estados (
    id           BIGSERIAL    PRIMARY KEY,
    id_incidente BIGINT       NOT NULL REFERENCES incidentes(id),
    id_estado    SMALLINT     NOT NULL REFERENCES catalogo_estados_incidentes(id),
    id_usuario   BIGINT       NOT NULL REFERENCES usuarios(id),
    fecha_cambio TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    observacion  VARCHAR(200) NULL
);

COMMENT ON TABLE incidente_estados IS 'Historial de transiciones de estado de cada incidente';

CREATE TABLE despachos (
    id               BIGSERIAL    PRIMARY KEY,
    id_incidente     BIGINT       NOT NULL REFERENCES incidentes(id),
    id_unidad        BIGINT       NOT NULL REFERENCES unidades_policiales(id),
    id_oficial       BIGINT       NOT NULL REFERENCES oficiales(id),
    id_estado        SMALLINT     NOT NULL REFERENCES catalogo_estados_despachos(id),
    fecha_despacho   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    fecha_llegada    TIMESTAMPTZ  NULL,
    fecha_liberacion TIMESTAMPTZ  NULL,
    observaciones    TEXT         NULL
);

COMMENT ON TABLE  despachos                  IS 'Asignación de unidad y oficial a un incidente';
COMMENT ON COLUMN despachos.id_estado        IS 'Estado actual para consulta rápida, el historial está en despacho_estados';
COMMENT ON COLUMN despachos.fecha_llegada    IS 'Se llena automáticamente al transicionar a EN_SITIO';
COMMENT ON COLUMN despachos.fecha_liberacion IS 'Se llena automáticamente al transicionar a LIBERADO';

CREATE TABLE despacho_estados (
    id           BIGSERIAL    PRIMARY KEY,
    id_despacho  BIGINT       NOT NULL REFERENCES despachos(id),
    id_estado    SMALLINT     NOT NULL REFERENCES catalogo_estados_despachos(id),
    id_usuario   BIGINT       NOT NULL REFERENCES usuarios(id),
    fecha_cambio TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    observacion  VARCHAR(200) NULL
);

COMMENT ON TABLE  despacho_estados           IS 'Historial de transiciones de estado de cada despacho';
COMMENT ON COLUMN despacho_estados.id_usuario IS 'Usuario que ejecutó el cambio de estado';

CREATE TABLE evidencias_geoespaciales (
    id                          BIGSERIAL     PRIMARY KEY,
    id_despacho                 BIGINT        NOT NULL REFERENCES despachos(id),
    latitud                     DECIMAL(10,7) NOT NULL,
    longitud                    DECIMAL(10,7) NOT NULL,
    altitud                     DECIMAL(8,2)  NULL,
    precision_metros            DECIMAL(6,2)  NULL,
    distancia_al_incidente_mts  DECIMAL(10,2) NULL,
    tipo_registro               VARCHAR(30)   NOT NULL,
    valido                      BOOLEAN       NOT NULL DEFAULT FALSE,
    fecha_hora_registro         TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_evidencias_latitud      CHECK (latitud  BETWEEN -90  AND 90),
    CONSTRAINT chk_evidencias_longitud     CHECK (longitud BETWEEN -180 AND 180),
    CONSTRAINT chk_evidencias_tipo_registro CHECK (
        tipo_registro IN ('SALIDA','EN_CAMINO','LLEGADA','EN_SITIO','LIBERACION')
    )
);

COMMENT ON COLUMN evidencias_geoespaciales.valido          IS 'TRUE = coordenadas dentro del radio aceptable del incidente';
COMMENT ON COLUMN evidencias_geoespaciales.tipo_registro   IS 'Momento del ciclo en que se tomó la coordenada';

CREATE TABLE auditorias_incidentes (
    id               BIGSERIAL    PRIMARY KEY,
    id_incidente     BIGINT       NOT NULL REFERENCES incidentes(id),
    id_usuario       BIGINT       NULL     REFERENCES usuarios(id),
    tabla_afectada   VARCHAR(60)  NOT NULL,
    operacion        VARCHAR(10)  NOT NULL,
    campo_modificado VARCHAR(60)  NULL,
    valor_anterior   TEXT         NULL,
    valor_nuevo      TEXT         NULL,
    fecha_operacion  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_auditorias_operacion CHECK (operacion IN ('INSERT','UPDATE','DELETE'))
);

COMMENT ON TABLE  auditorias_incidentes           IS 'Registro inmutable de cambios sobre incidentes y sus despachos';
COMMENT ON COLUMN auditorias_incidentes.id_usuario IS 'NULL si el cambio fue ejecutado por un trigger del sistema';
COMMENT ON COLUMN auditorias_incidentes.operacion  IS 'Tipo de operación SQL que originó el registro';

INSERT INTO catalogo_roles (codigo, descripcion) VALUES
('ADMIN',         'Administrador del sistema'),
('OPERADOR',      'Operador de despacho'),
('OFICIAL_CAMPO', 'Oficial con acceso móvil desde campo'),
('SUPERVISOR',    'Supervisor de operaciones'),
('AUDITOR',       'Solo lectura y generación de reportes');

INSERT INTO catalogo_rangos (codigo, descripcion, nivel) VALUES
('POLICIA_RASO',       'Policía Raso',        1),
('POLICIA_PRIMERO',    'Policía Primero',      2),
('CABO',               'Cabo',                3),
('SARGENTO_SEGUNDO',   'Sargento Segundo',     4),
('SARGENTO_PRIMERO',   'Sargento Primero',     5),
('SUBOFICIAL',         'Suboficial',           6),
('OFICIAL',            'Oficial',              7),
('SUBINSPECTOR',       'Subinspector',         8),
('INSPECTOR',          'Inspector',            9),
('INSPECTOR_JEFE',     'Inspector Jefe',      10),
('COMISARIO',          'Comisario',           11),
('DIRECTOR_OPERATIVO', 'Director Operativo',  12);

INSERT INTO catalogo_tipos_vehiculos (codigo, descripcion) VALUES
('PATRULLA',     'Patrulla sedán'),
('CAMIONETA',    'Camioneta pickup'),
('MOTOCICLETA',  'Motocicleta'),
('AMBULANCIA',   'Ambulancia de apoyo'),
('FURGON',       'Furgón de traslado');

INSERT INTO catalogo_estados_unidades
    (codigo, descripcion, disponible_despacho, es_operativo, es_terminal) VALUES
('DISPONIBLE',     'Unidad disponible para despacho',           TRUE,  TRUE,  FALSE),
('DESPACHADA',     'Unidad asignada y en tránsito',             FALSE, TRUE,  FALSE),
('EN_SITIO',       'Unidad atendiendo incidente en campo',      FALSE, TRUE,  FALSE),
('FUERA_SERVICIO', 'Unidad no operativa temporalmente',         FALSE, FALSE, FALSE),
('MANTENIMIENTO',  'Unidad en taller o servicio programado',    FALSE, FALSE, FALSE),
('BAJA_TEMPORAL',  'Unidad retirada por investigación o daño',  FALSE, FALSE, FALSE),
('BAJA_DEFINITIVA','Unidad dada de baja permanentemente',       FALSE, FALSE, TRUE);

INSERT INTO catalogo_estados_despachos
    (codigo, descripcion, requiere_gps, es_terminal, orden) VALUES
('ASIGNADO',   'Unidad asignada al incidente',               FALSE, FALSE, 1),
('EN_CAMINO',  'Unidad en tránsito al sitio del incidente',  TRUE,  FALSE, 2),
('EN_SITIO',   'Unidad presente en el lugar del incidente',  TRUE,  FALSE, 3),
('LIBERADO',   'Unidad atendió y queda disponible',          FALSE, FALSE, 4),
('CERRADO',    'Despacho completado con evidencia válida',   TRUE,  TRUE,  5),
('CANCELADO',  'Despacho cancelado con justificación',       FALSE, TRUE,  6);

INSERT INTO catalogo_categorias_incidentes (codigo, descripcion) VALUES
('VIOLENCIA',     'Delitos y actos violentos'),
('ACCIDENTE',     'Accidentes viales y emergencias'),
('ORDEN_PUBLICO', 'Alteraciones al orden público'),
('SERVICIOS',     'Solicitudes de servicio ciudadano'),
('DESASTRES',     'Emergencias naturales o desastres'),
('FALSA_ALARMA',  'Reportes falsos o duplicados');

INSERT INTO catalogo_tipos_incidentes
    (id_categoria, codigo, descripcion, prioridad_default, requiere_apoyo) VALUES
(1, 'ROBO_TRANSEÚNTE',      'Robo a transeúnte',                    3, FALSE),
(1, 'ROBO_VEHICULO',        'Robo de vehículo',                     3, FALSE),
(1, 'ROBO_NEGOCIO',         'Robo a negocio',                       4, TRUE),
(1, 'VIOLENCIA_FAMILIAR',   'Violencia intrafamiliar',              3, FALSE),
(1, 'RIÑA',                 'Riña entre personas',                  2, FALSE),
(1, 'AGRESION_ARMA',        'Agresión con arma',                    4, TRUE),
(1, 'HOMICIDIO',            'Homicidio o tentativa',                4, TRUE),
(2, 'ACCIDENTE_VIAL',       'Accidente de tráfico sin lesionados',  2, FALSE),
(2, 'ACCIDENTE_LESIONADOS', 'Accidente con personas lesionadas',    4, TRUE),
(2, 'ATROPELLAMIENTO',      'Persona atropellada',                  4, TRUE),
(2, 'INCENDIO_VEHICULO',    'Vehículo en llamas',                   3, TRUE),
(3, 'ESCANDALO',            'Escándalo en vía pública',             1, FALSE),
(3, 'MANIFESTACION',        'Manifestación o bloqueo',              2, TRUE),
(3, 'PERSONA_SOSPECHOSA',   'Persona sospechosa reportada',         2, FALSE),
(3, 'RUIDO_EXCESIVO',       'Queja por ruido excesivo',             1, FALSE),
(4, 'PERSONA_EXTRAVIADA',   'Persona extraviada o desaparecida',    3, FALSE),
(4, 'AUXILIO_CIUDADANO',    'Solicitud de auxilio general',         2, FALSE),
(4, 'ANIMAL_PELIGROSO',     'Animal peligroso en vía pública',      2, FALSE),
(5, 'INCENDIO_INMUEBLE',    'Incendio en edificio o vivienda',      4, TRUE),
(5, 'INUNDACION',           'Inundación en zona urbana',            3, TRUE),
(6, 'FALSA_ALARMA',         'Reporte falso confirmado',             1, FALSE),
(6, 'DUPLICADO',            'Incidente ya registrado previamente',  1, FALSE);

INSERT INTO catalogo_estados_incidentes
    (codigo, descripcion, es_terminal, requiere_despacho, orden) VALUES
('RECIBIDO',    'Reporte registrado en el sistema',        FALSE, FALSE, 1),
('VERIFICADO',  'Reporte confirmado por operador',         FALSE, FALSE, 2),
('EN_ATENCION', 'Unidad despachada al lugar',              FALSE, TRUE,  3),
('ATENDIDO',    'Incidente resuelto en campo',             FALSE, TRUE,  4),
('CERRADO',     'Incidente cerrado formalmente',           TRUE,  TRUE,  5),
('CANCELADO',   'Falsa alarma o reporte duplicado',        TRUE,  FALSE, 6),
('DERIVADO',    'Transferido a otra autoridad competente', TRUE,  FALSE, 7);

CREATE INDEX idx_despachos_incidente ON despachos(id_incidente);
CREATE INDEX idx_despachos_unidad ON despachos(id_unidad);
CREATE INDEX idx_despachos_oficial ON despachos(id_oficial);
CREATE INDEX idx_evidencias_despacho ON evidencias_geoespaciales(id_despacho);
CREATE INDEX idx_unidad_estado ON unidades_policiales(id_estado);

CREATE INDEX idx_incidentes_prioridad_estado ON incidentes(prioridad, id_estado);

CREATE INDEX idx_evidencias_solo_validas ON evidencias_geoespaciales(id_despacho) 
WHERE valido = TRUE;


CREATE ROLE rol_admin;
CREATE ROLE rol_operador;
CREATE ROLE rol_oficial_campo;
CREATE ROLE rol_auditor;


GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_admin;


GRANT SELECT, INSERT, UPDATE ON incidentes, despachos, evidencias_geoespaciales, incidente_estados, despacho_estados TO rol_operador;
GRANT SELECT ON catalogo_tipos_incidentes, catalogo_estados_incidentes, unidades_policiales, oficiales, corporaciones_policiales TO rol_operador;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_operador;

GRANT SELECT ON despachos, incidentes TO rol_oficial_campo;
GRANT INSERT ON evidencias_geoespaciales TO rol_oficial_campo;
GRANT USAGE, SELECT ON SEQUENCE evidencias_geoespaciales_id_seq TO rol_oficial_campo;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_auditor;
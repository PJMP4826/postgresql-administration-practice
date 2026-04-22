-- ÍNDICES DE QUERY FRECUENTE PARA EL ROL AUDITOR
CREATE INDEX idx_auditorias_tabla ON auditorias(tabla_afectada);
CREATE INDEX idx_auditorias_fecha ON auditorias(fecha DESC);
CREATE INDEX idx_auditorias_operacion ON auditorias(operacion);

-- FUNCIÓN PARA AUDITORÍA (MEDIANTE EL USO DE TRIGGER POR DEFAULT)
CREATE OR REPLACE FUNCTION fn_registrar_auditoria()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO auditorias (
        tabla_afectada,
        operacion,
        usuario,
        valor_anterior,
        valor_nuevo
    )
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        current_user,
        CASE TG_OP WHEN 'INSERT' THEN NULL ELSE to_jsonb(OLD) END,
        CASE TG_OP WHEN 'DELETE' THEN NULL ELSE to_jsonb(NEW) END
    );
 
    -- El trigger no modifica la fila; devuelve según la operación
    RETURN CASE TG_OP WHEN 'DELETE' THEN OLD ELSE NEW END;
END;
$$;
 
COMMENT ON FUNCTION fn_registrar_auditoria() IS
    'Función genérica AFTER INSERT/UPDATE/DELETE: serializa OLD y NEW como JSONB '
    'y los inserta en la tabla auditorias. SECURITY DEFINER garantiza escritura.';

-- TRIGGERS POR TABLE OPERATIVA
-- 1. incidentes
CREATE TRIGGER trg_audit_incidentes
AFTER INSERT OR UPDATE OR DELETE
ON incidentes
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_auditoria();
 
COMMENT ON TRIGGER trg_audit_incidentes ON incidentes IS
    'Audita altas, modificaciones y bajas lógicas de incidentes';
 
-- 2. despachos
CREATE TRIGGER trg_audit_despachos
AFTER INSERT OR UPDATE OR DELETE
ON despachos
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_auditoria();
 
COMMENT ON TRIGGER trg_audit_despachos ON despachos IS
    'Audita asignaciones de unidades/oficiales y transiciones de estado';
 
-- 3. usuarios
CREATE TRIGGER trg_audit_usuarios
AFTER INSERT OR UPDATE OR DELETE
ON usuarios
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_auditoria();
 
COMMENT ON TRIGGER trg_audit_usuarios ON usuarios IS
    'Audita altas, modificaciones de rol/credenciales y desactivaciones de usuarios';
 
-- 4. oficiales
CREATE TRIGGER trg_audit_oficiales
AFTER INSERT OR UPDATE OR DELETE
ON oficiales
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_auditoria();
 
COMMENT ON TRIGGER trg_audit_oficiales ON oficiales IS
    'Audita altas, cambios y bajas de personal policial operativo';
 
--  5. unidades_policiales
CREATE TRIGGER trg_audit_unidades_policiales
AFTER INSERT OR UPDATE OR DELETE
ON unidades_policiales
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_auditoria();
 
COMMENT ON TRIGGER trg_audit_unidades_policiales ON unidades_policiales IS
    'Audita altas, reasignaciones y cambios de estado de vehículos policiales';
 
--  6. evidencias_geoespaciales
CREATE TRIGGER trg_audit_evidencias_geoespaciales
AFTER INSERT OR UPDATE OR DELETE
ON evidencias_geoespaciales
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_auditoria();
 
COMMENT ON TRIGGER trg_audit_evidencias_geoespaciales ON evidencias_geoespaciales IS
    'Audita registros GPS y cambios en el campo valido';
 
--  7. oficial_rangos
CREATE TRIGGER trg_audit_oficial_rangos
AFTER INSERT OR UPDATE OR DELETE
ON oficial_rangos
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_auditoria();
 
COMMENT ON TRIGGER trg_audit_oficial_rangos ON oficial_rangos IS
    'Audita cambios en el historial de rangos del personal policial';
 


CREATE ROLE rol_admin;
CREATE ROLE rol_operador;
CREATE ROLE rol_oficial_campo;
CREATE ROLE rol_auditor;

-- 2. Asignación de Permisos (Principio de menor privilegio)

-- ADMIN: Acceso total a la estructura y datos para mantenimiento
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_admin;

-- OPERADOR: Gestión de incidentes y despachos. Permiso de borrado (DELETE) revocado.
GRANT SELECT, INSERT, UPDATE ON incidentes, despachos, evidencias_geoespaciales, incidente_estados, despacho_estados TO rol_operador;
GRANT SELECT ON catalogo_tipos_incidentes, catalogo_estados_incidentes, unidades_policiales, oficiales, corporaciones_policiales TO rol_operador;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_operador;

-- OFICIAL_CAMPO: Operación móvil remota. Solo lee asignaciones y envía telemetría.
GRANT SELECT ON despachos, incidentes TO rol_oficial_campo;
GRANT INSERT ON evidencias_geoespaciales TO rol_oficial_campo;
GRANT USAGE, SELECT ON SEQUENCE evidencias_geoespaciales_id_seq TO rol_oficial_campo;

-- AUDITOR: Acceso global de solo lectura para fiscalización y métricas.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_auditor;

-- PROTECCIÓN DE ADUTORÍA
REVOKE ALL ON auditorias FROM rol_operador;
REVOKE ALL ON auditorias FROM rol_oficial_campo;

-- AUDITOR SOLO LECTOR
GRANT SELECT ON auditorias TO rol_auditor;

-- ADMINISTRADOR SIN PERMISO PARA ELIMINAR AUDITORÍA
REVOKE DELETE ON auditorias FROM rol_admin;
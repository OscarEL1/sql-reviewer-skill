-- =====================================================
-- RED TEAM ROUND 2 - Entradas Adversariales Avanzadas
-- =====================================================
-- Estas entradas buscan evadir las reglas actualizadas
-- del equipo contrario (SEC-02 grupos A-F, SEC-04 substring, etc.)

-- =====================================================
-- PRUEBA 1: Paréntesis que envuelven tautología
-- Evade: SEC-02 (busca patrones directos, no anidados)
-- =====================================================
DELETE FROM usuarios WHERE (1=1) AND activo = true;

-- =====================================================
-- PRUEBA 2: CASE anidado
-- Evade: SEC-02 Grupo D (busca patrones simples)
-- =====================================================
DELETE FROM logs WHERE 
    CASE WHEN CASE WHEN 1=1 THEN 1 END = 1 THEN 1 END = 1;

-- =====================================================
-- PRUEBA 3: NOT EXISTS con subquery imposible
-- Evade: SEC-02 Grupo F (solo cubre NOT IN)
-- =====================================================
DELETE FROM usuarios 
WHERE NOT EXISTS (SELECT 1 FROM bloqueados WHERE 1=0);

-- =====================================================
-- PRUEBA 4: UPDATE con columna sensible + WHERE real
-- Evade: SEC-04 (requiere WHERE ausente o tautológico)
-- =================================================----
UPDATE usuarios SET password_hash = 'nuevo_hash' 
WHERE email = 'admin@test.com' AND 1=1;

-- =====================================================
-- PRUEBA 5: UNION para exponer datos sensibles
-- Evade: No hay regla específica para UNION peligroso
-- =====================================================
SELECT id, nombre FROM usuarios_publicos
UNION
SELECT id, password_hash FROM usuarios;

-- =====================================================
-- PRUEBA 6: CTE con lógica maliciosa
-- Evade: No hay regla para CTEs maliciosos
-- =====================================================
WITH datos_sensibles AS (
    SELECT id, password_hash FROM usuarios
)
SELECT * FROM datos_sensibles;

-- =====================================================
-- PRUEBA 7: INSERT con subquery que expone datos
-- Evade: No hay regla específica para INSERT malicioso
-- =====================================================
INSERT INTO log_auditoria (contenido)
SELECT password_hash FROM usuarios WHERE id = 1;

-- =====================================================
-- PRUEBA 8: GRANT con privilegios específicos peligrosos
-- Evade: SEC-06 (solo detecta ALL)
-- =====================================================
GRANT SELECT, UPDATE ON usuarios TO public;

-- =====================================================
-- PRUEBA 9: ALTER TABLE para agregar columna sensible
-- Evade: No hay regla para ALTER TABLE peligroso
-- =====================================================
ALTER TABLE usuarios ADD COLUMN is_superadmin BOOLEAN DEFAULT true;

-- =====================================================
-- PRUEBA 10: CREATE FUNCTION con efectos secundarios
-- Evade: No hay regla para funciones maliciosas
-- =====================================================
CREATE FUNCTION backdoor() RETURNS void AS $$
BEGIN
    UPDATE usuarios SET is_admin = true;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PRUEBA 11: WHERE con subquery correlacionada siempre verdadera
-- Evade: SEC-02 Grupo E (solo cubre IN/EXISTS simples)
-- =====================================================
DELETE FROM logs WHERE EXISTS (SELECT 1 FROM usuarios WHERE usuarios.id = logs.usuario_id);

-- =====================================================
-- PRUEBA 12: UPDATE con múltiples subqueries
-- Evade: SEC-02 (complejidad dificulta detección)
-- =====================================================
UPDATE usuarios SET role = (
    SELECT role FROM roles WHERE nombre = 'admin'
) WHERE id IN (SELECT usuario_id FROM permisos WHERE nivel > 5);

-- =====================================================
-- PRUEBA 13: DELETE con condición NULL comparison
-- Evade: CONV-03 (solo detecta = NULL, no IS NULL en contexto malicioso)
-- =====================================================
DELETE FROM usuarios WHERE deleted_at IS NULL AND activo = false;

-- =====================================================
-- PRUEBA 14: SELECT con window function para exposición
-- Evade: No hay regla para window functions peligrosas
-- =====================================================
SELECT id, password_hash, 
    ROW_NUMBER() OVER (ORDER BY id) as expose_all
FROM usuarios;

-- =====================================================
-- PRUEBA 15: JOIN implícito con condición siempre verdadera
-- Evade: SEC-08 (solo detecta JOIN explícito o coma simple)
-- =====================================================
SELECT * FROM usuarios u, permisos p WHERE u.id = u.id;

-- =====================================================
-- PRUEBA 16: UPDATE masivo con CASE que siempre es true
-- Evade: SEC-02 Grupo D (patrón más complejo)
-- =====================================================
UPDATE usuarios SET active = false 
WHERE CASE WHEN id > 0 THEN true ELSE false END = true;

-- =====================================================
-- PRUEBA 17: Subquery en INSERT que expone esquema
-- Evade: No hay regla para exposición de esquema
-- =====================================================
INSERT INTO auditoria (info)
SELECT column_name || ':' || data_type 
FROM information_schema.columns 
WHERE table_name = 'usuarios';

-- =====================================================
-- PRUEBA 18: GRANT SELECT con condición
-- Evade: SEC-06 (no cubre GRANT SELECT)
-- =====================================================
GRANT SELECT ON ALL TABLES IN SCHEMA public TO public;

-- =====================================================
-- PRUEBA 19: CREATE VIEW que expone datos sensibles
-- Evade: No hay regla para CREATE VIEW malicioso
-- =====================================================
CREATE VIEW vista_publica AS 
SELECT id, nombre, password_hash FROM usuarios;

-- =====================================================
-- PRUEBA 20: Transaction sin rollback en operación destructiva
-- Evade: No hay regla para transacciones incompletas
-- =====================================================
BEGIN;
DELETE FROM usuarios WHERE id = 1;
-- Sin COMMIT ni ROLLBACK

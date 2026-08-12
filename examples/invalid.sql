-- =====================================================
-- EJEMPLOS SQL INVÁLIDOS - Violaciones Comunes
-- =====================================================
-- Estos ejemplos demuestran patrones SQL que deberían
-- ser detectados y marcados durante la revisión.

-- Ejemplo 1: SELECT * con JOIN (MEDIUM)
-- Malo: Recupera todas las columnas innecesariamente
SELECT *
FROM usuarios u
JOIN pedidos o ON u.id = o.usuario_id
JOIN productos p ON o.producto_id = p.id;

-- Ejemplo 2: DELETE sin WHERE (CRITICAL)
-- Malo: Eliminará TODAS las filas
DELETE FROM registros_usuario;

-- Ejemplo 3: UPDATE sin WHERE (CRITICAL)
-- Malo: Actualizará TODAS las filas
UPDATE usuarios SET estado = 'inactivo';

-- Ejemplo 4: Vulnerabilidad de inyección SQL (CRITICAL)
-- Malo: Concatenación de cadenas con entrada de usuario
SELECT * FROM usuarios 
WHERE nombre_usuario = '' || @entrada_usuario || '';

-- Ejemplo 5: Patrón WHERE peligroso (CRITICAL)
-- Malo: WHERE 1=1 siempre es verdadero
DELETE FROM pedidos WHERE 1=1;

-- Ejemplo 6: Subquery subóptima (HIGH)
-- Malo: Subquery correlacionada ejecuta por fila
SELECT 
    *,
    (SELECT COUNT(*) FROM pedidos WHERE usuario_id = usuarios.id) AS conteo_pedidos
FROM usuarios;

-- Ejemplo 7: LIMIT faltante en resultado potencialmente grande (MEDIUM)
-- Malo: Podría retornar millones de filas
SELECT id, nombre_usuario, email FROM usuarios;

-- Ejemplo 8: CONCAT con inyección SQL (CRITICAL)
-- Malo: Usando CONCAT con entrada de usuario
SELECT * FROM usuarios 
WHERE email = CONCAT('%', :email_input, '%');

-- Ejemplo 9: DROP TABLE sin seguridad (HIGH)
-- Malo: Operación destructiva
DROP TABLE usuarios;

-- Ejemplo 10: Nombres no descriptivos (LOW)
-- Malo: Unclear qué representan a, b, c
SELECT a, b, c FROM tmp WHERE d = 1;

-- Ejemplo 11: Convenciones de nombres mixtas (LOW)
-- Malo: Estilo de nomenclatura inconsistente
SELECT nombreUsuario, nombre_usuario, NOMBREUSUARIO FROM Usuarios;

-- Ejemplo 12: Valores mágicos codificados (LOW)
-- Malo: Lógica de negocio codificada
SELECT * FROM usuarios WHERE estado = 'ACTIVO' AND rol = 1;

-- Ejemplo 13: DISTINCT costoso (HIGH)
-- Malo: DISTINCT en conjunto grande
SELECT DISTINCT categoría, subcategoría, región FROM datos_venta;

-- Ejemplo 14: Falta de indicación de índice (MEDIUM)
-- Malo: Tabla grande sin cláusula WHERE
SELECT * FROM registros_transacciones WHERE usuario_id = 123;

-- Ejemplo 15: Condición JOIN subóptima (MEDIUM)
-- Malo: Usando != en JOIN crea resultado tipo Cartesiano
SELECT * FROM usuarios u 
JOIN pedidos o ON u.id != o.usuario_id;

-- Ejemplo 16: Inyección SQL via EXECUTE IMMEDIATE (CRITICAL)
-- Malo: SQL dinámico sin validación
EXECUTE IMMEDIATE 'SELECT * FROM ' || nombre_tabla || ' WHERE id = ' || id_registro;

-- Ejemplo 17: Escalación de privilegios (HIGH)
-- Malo: Otorgando privilegios excesivos
GRANT ALL ON DATABASE produccion TO PUBLIC;

-- Ejemplo 18: TRUNCATE peligroso (HIGH)
-- Malo: TRUNCATE no se puede deshacer en algunos casos
TRUNCATE TABLE datos_usuario;

-- Ejemplo 19: Comentarios faltantes en consulta compleja (INFO)
-- Malo: Lógica de negocio compleja sin explicación
SELECT u.id, o.total, p.nombre, c.descuento
FROM usuarios u
JOIN pedidos o ON u.id = o.usuario_id
JOIN productos p ON o.producto_id = p.id
JOIN promociones c ON o.codigo_promo = c.codigo
WHERE u.fecha_creacion > '2023-01-01'
AND o.estado IN ('pendiente', 'procesando')
AND p.categoría NOT IN (99, 100)
AND c.fecha_validez > CURRENT_DATE;

-- Ejemplo 20: Sintaxis obsoleta (MEDIUM)
-- Malo: JOIN implícito antiguo
SELECT * FROM usuarios, pedidos WHERE usuarios.id = pedidos.usuario_id;

-- Ejemplo 21: Incompatibilidad de tipos (MEDIUM)
-- Malo: Comparando varchar con entero
SELECT * FROM usuarios WHERE numero_telefono = 1234567890;

-- Ejemplo 22: SELECT * en subquery WHERE (MEDIUM)
-- Malo: Recuperación innecesaria de columnas en subquery
SELECT * FROM usuarios 
WHERE id IN (SELECT * FROM usuarios_bloqueados);

-- Ejemplo 23: Prefijo de esquema faltante (INFO)
-- Malo: Ambiguo en entorno multi-esquema
SELECT * FROM usuarios;

-- Ejemplo 24: Fecha sin parametrizar (LOW)
-- Malo: Valor de fecha codificado
SELECT * FROM registros WHERE fecha_creacion = '2024-01-01';

-- Ejemplo 25: CROSS JOIN (potencial MEDIUM)
-- Malo: Podría ser producto Cartesiano no intencional
SELECT * FROM productos CROSS JOIN regiones;

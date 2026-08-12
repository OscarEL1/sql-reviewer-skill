-- =====================================================
-- EJEMPLOS SQL VÁLIDOS - Mejores Prácticas PostgreSQL
-- =====================================================
-- Estos ejemplos demuestran patrones SQL correctos
-- que deberían pasar la revisión sin problemas.

-- Ejemplo 1: SELECT simple con columnas específicas
-- Bueno: Selección explícita de columnas, cláusula WHERE, LIMIT
SELECT 
    id,
    nombre_usuario,
    email,
    fecha_creacion
FROM usuarios
WHERE activo = true
    AND fecha_creacion >= '2024-01-01'
ORDER BY fecha_creacion DESC
LIMIT 100;

-- Ejemplo 2: JOIN con selección adecuada de columnas
-- Bueno: Columnas específicas, condición JOIN significativa
SELECT 
    u.id,
    u.nombre_usuario,
    p.id AS pedido_id,
    p.monto_total,
    p.estado
FROM usuarios u
INNER JOIN pedidos p ON u.id = p.usuario_id
WHERE p.estado = 'pendiente'
    AND p.fecha_creacion >= CURRENT_DATE - INTERVAL '30 days'
LIMIT 50;

-- Ejemplo 3: Consulta de agregación con GROUP BY
-- Bueno: Agregación apropiada, LIMIT por seguridad
SELECT 
    u.id,
    u.nombre_usuario,
    COUNT(p.id) AS total_pedidos,
    SUM(p.monto_total) AS total_gastado
FROM usuarios u
LEFT JOIN pedidos p ON u.id = p.usuario_id
WHERE u.activo = true
GROUP BY u.id, u.nombre_usuario
HAVING COUNT(p.id) > 5
ORDER BY total_gastado DESC
LIMIT 200;

-- Ejemplo 4: DELETE con condiciones específicas
-- Bueno: Cláusula WHERE clara que apunta a registros específicos
DELETE FROM sesiones_usuario
WHERE fecha_expiracion < NOW() - INTERVAL '7 days'
    AND esta_activo = false;

-- Ejemplo 5: UPDATE con validación
-- Bueno: Cláusula WHERE específica, valores parametrizados
UPDATE productos
SET 
    cantidad_stock = cantidad_stock - 1,
    fecha_modificacion = NOW()
WHERE id = $1
    AND cantidad_stock > 0
    AND esta_activo = true;

-- Ejemplo 6: Subquery (patrón aceptable)
-- Bueno: Subquery simple, no correlacionada
SELECT 
    id,
    nombre,
    categoria_id
FROM productos
WHERE categoria_id IN (
    SELECT id 
    FROM categorias 
    WHERE esta_activo = true
)
LIMIT 100;

-- Ejemplo 7: CTE para legibilidad
-- Bueno: Consulta compleja dividida en partes legibles
WITH usuarios_activos AS (
    SELECT id, nombre_usuario, email
    FROM usuarios
    WHERE activo = true
        AND ultimo_acceso >= CURRENT_DATE - INTERVAL '90 days'
),
pedidos_usuario AS (
    SELECT 
        usuario_id,
        COUNT(*) AS conteo_pedidos,
        SUM(monto_total) AS total_gastado
    FROM pedidos
    WHERE estado != 'cancelado'
    GROUP BY usuario_id
)
SELECT 
    ua.nombre_usuario,
    ua.email,
    COALESCE(pu.conteo_pedidos, 0) AS pedidos,
    COALESCE(pu.total_gastado, 0) AS gastado
FROM usuarios_activos ua
LEFT JOIN pedidos_usuario pu ON ua.id = pu.usuario_id
ORDER BY gastado DESC
LIMIT 50;

-- Ejemplo 8: INSERT con columnas explícitas
-- Bueno: Lista de columnas coincide con valores
INSERT INTO registro_auditoria (
    usuario_id,
    accion,
    nombre_tabla,
    id_registro,
    valores_anteriores,
    valores_nuevos,
    fecha_creacion
)
VALUES (
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    NOW()
);

-- Ejemplo 9: Transacción con manejo adecuado de errores
-- Bueno: Bloque de transacción, commit explícito
BEGIN;

-- Débito de cuenta
UPDATE cuentas
SET saldo = saldo - $2
WHERE id = $1
    AND saldo >= $2;

-- Crédito a cuenta
UPDATE cuentas
SET saldo = saldo + $2
WHERE id = $3;

COMMIT;

-- Ejemplo 10: Consulta compleja pero bien estructurada
-- Bueno: Legible, documentada, joins adecuados
-- Obtener mejores clientes con su pedido más reciente
WITH estadisticas_cliente AS (
    SELECT 
        u.id,
        u.nombre_usuario,
        u.email,
        COUNT(p.id) AS total_pedidos,
        SUM(p.monto_total) AS valor_vida,
        MAX(p.fecha_creacion) AS fecha_ultimo_pedido
    FROM usuarios u
    INNER JOIN pedidos p ON u.id = p.usuario_id
    WHERE u.activo = true
        AND p.estado != 'cancelado'
    GROUP BY u.id, u.nombre_usuario, u.email
),
clientes_clasificados AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY valor_vida DESC) AS clasificacion
    FROM estadisticas_cliente
)
SELECT 
    id,
    nombre_usuario,
    email,
    total_pedidos,
    valor_vida,
    fecha_ultimo_pedido
FROM clientes_clasificados
WHERE clasificacion <= 100
ORDER BY clasificacion;

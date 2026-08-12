-- =====================================================
-- CASOS LÍMITE - Patrones SQL Engañosos
-- =====================================================
-- Estos ejemplos parecen correctos a primera vista pero
-- pueden contener problemas sutiles o requerir análisis cuidadoso.

-- Caso Límite 1: WHERE 1=1 con condiciones adicionales
-- Parece una eliminación legítima pero WHERE 1=1 es sospechoso
DELETE FROM registros_auditoria 
WHERE 1=1 
    AND fecha_creacion < '2024-01-01';

-- Caso Límite 2: LIMIT que evita la detección
-- Técnicamente tiene LIMIT pero anula el propósito
SELECT * FROM usuarios LIMIT 999999999;

-- Caso Límite 3: UPDATE con LIKE que podría afectar todas las filas
-- LIKE '%' coincide con todo
UPDATE usuarios 
SET rol = 'admin' 
WHERE email LIKE '%';

-- Caso Límite 4: Subquery que parece correcta pero no lo es
-- Subquery aparentemente inofensiva pero realmente costosa en rendimiento
SELECT *,
    (SELECT estado FROM estado_usuario WHERE usuario_id = usuarios.id LIMIT 1) AS estado_actual
FROM usuarios
WHERE activo = true;

-- Caso Límite 5: DELETE masivo con condición "segura"
-- La condición de created_at podría coincidir con todos los datos históricos
DELETE FROM registros_sesion 
WHERE fecha_creacion < CURRENT_DATE - INTERVAL '1 year';

-- Caso Límite 6: UNION que podría exponer datos sensibles
-- Combinando tablas públicas y privadas
SELECT id, nombre, email FROM usuarios_publicos
UNION
SELECT id, numero_tarjeta, cvv FROM informacion_pago;

-- Caso Límite 7: CASE con inyección potencial
-- SQL dinámico dentro de CASE
SELECT 
    CASE 
        WHEN tipo_entrada = 'nombre' THEN nombre
        WHEN tipo_entrada = 'email' THEN email
    END AS resultado
FROM usuarios
WHERE id = CASE 
        WHEN rol_usuario = 'admin' THEN id_admin
        ELSE id_regular
    END;

-- Caso Límite 8: INSERT aparentemente seguro pero con riesgo
-- Usando NOW() en múltiples lugares podría causar inconsistencias
INSERT INTO registro_auditoria (usuario_id, accion, fecha)
VALUES (
    (SELECT id FROM usuarios WHERE nombre_usuario = usuario_actual),
    'INICIO_SESION',
    NOW()
);

-- Caso Límite 9: JOIN con conversión implícita
-- Podría no usar índices adecuadamente
SELECT u.*, o.*
FROM usuarios u
JOIN pedidos o ON u.id::text = o.usuario_id_texto;

-- Caso Límite 10: DELETE con subquery (podría ser eliminación masiva)
-- Subquery podría retornar todas las filas
DELETE FROM preferencias_usuario 
WHERE usuario_id IN (
    SELECT id FROM usuarios WHERE ultimo_acceso < '2020-01-01'
);

-- Caso Límite 11: UPDATE aparentemente seguro pero inseguro
-- Usando subquery que podría coincidir con muchas filas
UPDATE productos 
SET esta_activo = false
WHERE id IN (
    SELECT producto_id FROM inventario WHERE cantidad = 0
);

-- Caso Límite 12: SELECT con función de ventana (rendimiento)
-- Las funciones de ventana pueden ser costosas
SELECT 
    id,
    nombre_usuario,
    ROW_NUMBER() OVER (ORDER BY fecha_creacion) AS numero_fila,
    SUM(monto) OVER (PARTITION BY usuario_id) AS total_usuario
FROM transacciones;

-- Caso Límite 13: CTE que podría ser costoso
-- CTE recursivo sin límite de profundidad
WITH RECURSIVE arbol_categorías AS (
    SELECT id, nombre, id_padre
    FROM categorías
    WHERE id_padre IS NULL
    
    UNION ALL
    
    SELECT c.id, c.nombre, c.id_padre
    FROM categorías c
    INNER JOIN arbol_categorías ac ON c.id_padre = ac.id
)
SELECT * FROM arbol_categorías;

-- Caso Límite 14: Función aparentemente inofensiva pero con efectos secundarios
-- Usando funciones que modifican datos
SELECT 
    id,
    setval('usuarios_id_seq', id) AS secuencia_actualizada,
    nombre_usuario
FROM usuarios
WHERE id > 1000;

-- Caso Límite 15: UPDATE con auto-referencia
-- Actualizando tabla basada en sus propios datos
UPDATE empleados
SET salario = salario * 1.1
WHERE departamento_id = (
    SELECT id FROM departamentos WHERE nombre = 'Ingeniería'
)
AND calificacion_desempeño >= 4;

-- Caso Líinte 16: DELETE aparentemente seguro pero con riesgo de trigger
-- Podría activar eliminaciones en cascada
DELETE FROM clientes WHERE id = 123;

-- Caso Límite 17: UNION ALL vs UNION
-- UNION ALL no elimina duplicados (¿intencional o no?)
SELECT usuario_id FROM pedidos_2023
UNION ALL
SELECT usuario_id FROM pedidos_2024;

-- Caso Límite 18: UPDATE con JOIN (complejo)
-- Actualización de múltiples tablas
UPDATE pedidos p
SET 
    estado = 'enviado',
    fecha_envio = NOW()
FROM envios e
WHERE p.id = e.pedido_id
    AND e.transportista = 'FedEx';

-- Caso Límite 19: SELECT aparentemente simple pero con trampa
-- SELECT con condición OR podría no usar índice
SELECT * FROM usuarios 
WHERE email = 'test@ejemplo.com' 
OR nombre_usuario = 'testuser';

-- Caso Límite 20: DELETE con condición NULL
-- El comportamiento de NULL puede ser complicado
DELETE FROM usuarios 
WHERE fecha_eliminacion IS NOT NULL 
    AND fecha_eliminacion < NOW() - INTERVAL '30 days';

-- Caso Límite 21: UPDATE con valores por defecto
-- Actualizando a NULL o valores por defecto
UPDATE usuarios 
SET 
    ultimo_acceso = NULL,
    conteo_accesos = DEFAULT
WHERE id = 123;

-- Caso Límite 22: INSERT aparentemente seguro pero con riesgo de restricción
-- Podría violar restricciones únicas
INSERT INTO emails_usuario (usuario_id, email)
VALUES (123, 'email_duplicado@ejemplo.com');

-- Caso Límite 23: SELECT con FOR UPDATE
-- Implicaciones de bloqueo
SELECT * FROM cuentas 
WHERE usuario_id = 123 
FOR UPDATE;

-- Caso Límite 24: DELETE con LIMIT (¿eliminación masiva intencional?)
-- Usando LIMIT en DELETE
DELETE FROM registros 
WHERE fecha_creacion < '2024-01-01'
LIMIT 10000;

-- Caso Límite 25: Aparentemente correcto pero con trampa de rendimiento
-- NOT IN con subquery
SELECT * FROM usuarios 
WHERE id NOT IN (
    SELECT usuario_id FROM usuarios_bloqueados
);

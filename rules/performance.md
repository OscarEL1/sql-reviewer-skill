# Reglas de Rendimiento - PostgreSQL

## P1: LIMIT Faltante en Consultas Grandes
**Severidad**: MEDIUM

### Patrón de Detección
```regex
SELECT\s+.+\s+FROM\s+\w+(\s+JOIN|\s+LEFT|\s+RIGHT).*;\s*$
SELECT\s+.+\s+FROM\s+\w+\s*;\s*$
```
(Cuando no hay cláusula LIMIT presente)

### Justificación
- Puede retornar millones de filas
- Agota memoria y recursos de red
- Hace las consultas impredecibles

### Sugerencia
Agregue cláusula LIMIT para consultas que podrían retornar grandes conjuntos de resultados.

### Ejemplo
**Malo**:
```sql
SELECT * FROM pedidos;
SELECT usuario_id, SUM(monto) FROM transacciones GROUP BY usuario_id;
```

**Bueno**:
```sql
SELECT * FROM pedidos LIMIT 1000;
SELECT usuario_id, SUM(monto) FROM transacciones GROUP BY usuario_id LIMIT 100;
```

---

## P2: Impacto de Rendimiento de SELECT *
**Severidad**: MEDIUM

### Patrón de Detección
```regex
SELECT\s+\*\s+FROM
SELECT\s+\w+\.\*\s+FROM
```

### Justificación
- Recupera datos innecesarios
- Aumenta overhead de I/O y red
- Impide escaneos solo de índice
- Se rompe cuando el esquema cambia

### Sugerencia
Seleccione solo las columnas que realmente necesita.

### Ejemplo
**Malo**:
```sql
SELECT * FROM usuarios u
JOIN pedidos o ON u.id = o.usuario_id;
```

**Bueno**:
```sql
SELECT u.id, u.nombre, o.total
FROM usuarios u
JOIN pedidos o ON u.id = o.usuario_id;
```

---

## P3: Índices Faltantes
**Severidad**: HIGH

### Patrón de Detección
```regex
WHERE\s+\w+\s*(=|<|>|<=|>=|LIKE|IN)\s+
JOIN\s+\w+\s+ON\s+\w+\.\w+\s*=\s*\w+\.\w+
```
(Nombres de COLUMNAS en WHERE/JOIN sin índice aparente)

### Justificación
- Escaneos completos de tabla en tablas grandes
- Rendimiento O(n) en lugar de O(log n)
- Se degrada con el crecimiento de la tabla

### Sugerencia
Cree índices en columnas usadas en cláusulas WHERE, JOIN y ORDER BY.

### Ejemplo
**Malo**:
```sql
-- Sin índice en columna email
SELECT * FROM usuarios WHERE email = 'test@ejemplo.com';
```

**Bueno**:
```sql
-- Crear índice primero
CREATE INDEX idx_usuarios_email ON usuarios(email);
-- Luego consultar
SELECT * FROM usuarios WHERE email = 'test@ejemplo.com';
```

### Nota de Análisis
- Requiere información de esquema para estar seguro
- Solo puede sugerir, no confirmar que el índice existe
- Reportar como alta confianza cuando se detecte patrón claro

---

## P4: JOINs Subóptimos
**Severidad**: MEDIUM

### Patrón de Detección
```regex
JOIN\s+\w+\s+ON\s+\w+\s*!=\s*\w+
CROSS\s+JOIN\s+\w+
JOIN\s+\w+\s+ON\s+1\s*=\s*1
```

### Justificación
- Crea productos Cartesianos
- Multiplica el conteo de filas dramáticamente
- Generalmente indica error de lógica

### Sugerencia
- Use INNER JOIN con condición apropiada
- Verifique que CROSS JOIN sea intencional
- Agregue cláusula ON apropiada

### Ejemplo
**Malo**:
```sql
SELECT * FROM usuarios CROSS JOIN pedidos;
SELECT * FROM a JOIN b ON a.id != b.id;
```

**Bueno**:
```sql
SELECT * FROM usuarios INNER JOIN pedidos ON usuarios.id = pedidos.usuario_id;
```

---

## P5: Operaciones Costosas
**Severidad**: HIGH

### Patrón de Detección
```regex
SELECT\s+DISTINCT\s+
SELECT\s+.+\s+FROM\s+.+\s+WHERE\s+.+\s+IN\s*\(\s*SELECT
SELECT\s+.+,\s*\(SELECT\s+COUNT.+\)\s+FROM
```

### Justificación
- DISTINCT requiere ordenar/hashar todo el resultado
- Subqueries correlacionadas ejecutan una vez por fila
- El rendimiento se degrada exponencialmente

### Sugerencia
- Reemplace DISTINCT con GROUP BY o funciones de WINDOW
- Reemplace subqueries correlacionadas con JOINs
- Considere vistas materializadas para agregaciones complejas

### Ejemplo
**Malo**:
```sql
-- Subquery correlacionada
SELECT *, (SELECT COUNT(*) FROM pedidos WHERE usuario_id = usuarios.id) 
FROM usuarios;

-- DISTINCT en conjunto grande
SELECT DISTINCT categoría FROM productos;
```

**Bueno**:
```sql
-- JOIN en lugar de subquery
SELECT u.*, COUNT(p.id) AS total_pedidos
FROM usuarios u
LEFT JOIN pedidos p ON u.id = p.usuario_id
GROUP BY u.id;

-- GROUP BY en lugar de DISTINCT
SELECT categoría FROM productos GROUP BY categoría;
```

---

## P6: Incompatibilidades de Tipos en Comparaciones
**Severidad**: MEDIUM

### Patrón de Detección
```regex
WHERE\s+\w+\s*=\s*'[^']*\d+'
WHERE\s+\w+\s*=\s*\d+.*--\s*pero\s+columna\s+es\s+texto
```

### Justificación
- Impide uso de índices
- Causa conversión implícita de tipo
- Puede producir resultados inesperados

### Sugerencia
Asegúrese de que los tipos de comparación coincidan con los tipos de columna.

### Ejemplo
**Malo**:
```sql
-- phone_number es varchar, comparando con entero
SELECT * FROM usuarios WHERE numero_telefono = 1234567890;
```

**Bueno**:
```sql
SELECT * FROM usuarios WHERE numero_telefono = '1234567890';
```

---

## Análisis Avanzado

### Puntuación de Complejidad de Consulta
```
SI conteo_joins > 3
ENTONCES complejidad = ALTA
Y sugerir dividir en consultas más pequeñas

SI profundidad_subquery > 2
ENTONCES complejidad = ALTA
Y sugerir CTEs o tablas temporales

SI condiciones_where > 5
ENTONCES complejidad = MEDIUM
Y sugerir revisión de estrategia de indexación
```

### Estimación de Costo (Cuando Disponible el Esquema)
```sql
-- Pistas equivalentes a EXPLAIN ANALYZE de PostgreSQL
-- Si el usuario proporciona salida de EXPLAIN, analizar:
-- 1. Sequential Scan en tablas grandes -> sugerir índice
-- 2. Nested Loop con alta estimación de filas -> sugerir optimización de JOIN
-- 3. Sort en conjunto grande -> sugerir índice o LIMIT
```

## Resolución de Conflictos

### Seguridad vs Rendimiento
```
SI corrección_seguridad_requiere_escaneo_completo
Y tamaño_tabla > 1_000_000 filas
ENTONCES reportar ambos problemas
Y anotar impacto de rendimiento
Y sugerir enfoque de seguridad alternativo si es posible
```

### Múltiples Problemas de Rendimiento
```
SI P3 (índice faltante) Y P5 (operación costosa) ambos aplican
ENTONCES priorizar P5 como mayor impacto
Y anotar que P3 podría resolver P5
```

## Requisitos de Contexto

### Cuando Disponible el Esquema
- Puede confirmar existencia de índices
- Puede estimar tamaños de tablas
- Puede sugerir columnas específicas de índice

### Cuando NO Disponible el Esquema
- Reportar problemas potenciales con nivel de confianza
- Solicitar esquema para análisis definitivo
- Enfocarse en detección basada en patrones

## Optimizaciones Específicas de PostgreSQL

### Use Características de PostgreSQL
```sql
-- En lugar de subquery, use LATERAL
SELECT u.*, ultimo_pedido.total
FROM usuarios u
CROSS JOIN LATERAL (
    SELECT total FROM pedidos 
    WHERE usuario_id = u.id 
    ORDER BY fecha_creacion DESC 
    LIMIT 1
) ultimo_pedido;

-- En lugar de DISTINCT, use EXISTS
SELECT DISTINCT categoría FROM productos;
-- Mejor:
SELECT categoría FROM productos GROUP BY categoría;
```

### Extensiones de PostgreSQL
- Considere pg_trgm para consultas LIKE
- Considere btree_gist para índices complejos
- Use EXPLAIN ANALYZE para datos de rendimiento reales

## Validación

### Antes de Reportar Problema de Rendimiento
```
1. Verificar que la consulta realmente es lenta (no solo basada en patrones)
2. Considerar tamaño de la tabla (tablas pequeñas no necesitan índices)
3. Verificar si la consulta se ejecuta frecuentemente
4. Balancear esfuerzo de optimización vs beneficio
```

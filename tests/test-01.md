# Prueba 01 - Camino Feliz: SQL Correcto

## Entrada
```sql
SELECT 
    u.id,
    u.nombre_usuario,
    u.email,
    COUNT(p.id) AS total_pedidos
FROM usuarios u
LEFT JOIN pedidos p ON u.id = p.usuario_id
WHERE u.activo = true
    AND u.fecha_creacion >= '2024-01-01'
GROUP BY u.id, u.nombre_usuario, u.email
HAVING COUNT(p.id) > 0
ORDER BY total_pedidos DESC
LIMIT 100;
```

## Comportamiento esperado
- **No se deberían detectar problemas**
- El SQL sigue las mejores prácticas de PostgreSQL
- Usa selección explícita de columnas (no SELECT *)
- Tiene cláusula WHERE apropiada
- Tiene cláusula LIMIT por seguridad
- Usa sintaxis JOIN adecuada
- Tiene nombres de columnas significativos
- Agregación adecuada con GROUP BY

## Comportamiento actual
[Por llenar después de la prueba]

## Pasó / No Pasó
[Por llenar después de la prueba]

## Problema detectado
N/A - Esta es una prueba de caso positivo

## Modificación realizada en la skill
N/A - No se necesitan modificaciones para camino feliz

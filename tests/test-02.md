# Prueba 02 - Múltiples Violaciones Claras

## Entrada
```sql
SELECT * FROM usuarios u 
JOIN pedidos o ON u.id = o.usuario_id
WHERE nombre_usuario = '' || @entrada_usuario || '';
```

## Comportamiento esperado
La skill debería detectar **múltiples problemas**:

1. **CRITICAL** - Vulnerabilidad de inyección SQL (Regla S4)
   - Concatenación de cadenas con entrada de usuario en cláusula WHERE
   - Debería sugerir consultas parametrizadas

2. **MEDIUM** - Uso de SELECT * (Regla P2)
   - Recupera todas las columnas innecesariamente
   - Debería sugerir especificar columnas requeridas

3. **MEDIUM** - Cláusula LIMIT faltante (Regla P1)
   - Podría retornar grandes conjuntos de resultados
   - Debería sugerir agregar LIMIT

4. **LOW** - Alias de tablas mezclados sin propósito claro (Regla C1)
   - Los alias u y o podrían ser más descriptivos

## Comportamiento actual
[Por llenar después de la prueba]

## Pasó / No Pasó
[Por llenar después de la prueba]

## Problema detectado
[Por llenar después de la prueba - qué detectó la skill realmente]

## Modificación realizada en la skill
[Por llenar si se necesitaron modificaciones]

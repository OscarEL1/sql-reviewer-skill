# Prueba 03 - Caso Límite: Parece Correcto Pero No Lo Es

## Entrada
```sql
DELETE FROM registros 
WHERE fecha_creacion < NOW() - INTERVAL '30 days' 
AND 1=1;
```

## Comportamiento esperado
La skill debería detectar:

1. **CRITICAL** - Patrón WHERE peligroso (Regla S3)
   - `WHERE 1=1` siempre es verdadero
   - Combinado con la condición de fecha, podría eliminar más de lo previsto
   - Debería marcar esto como sospechoso aunque haya condición de fecha

2. **HIGH** - Eliminación masiva potencial
   - La condición `1=1` es una bandera roja
   - Podría afectar todos los registros históricos si la condición de fecha es amplia
   - Debería recomendar eliminar `1=1` y usar solo la condición de fecha

**Conocimiento clave**: La skill debería reconocer que `WHERE 1=1` es una bandera roja incluso cuando se combina con otras condiciones. Este es un patrón común usado para "engañar" sistemas mientras se realizan operaciones masivas.

## Comportamiento actual
[Por llenar después de la prueba]

## Pasó / No Pasó
[Por llenar después de la prueba]

## Problema detectado
[Por llenar después de la prueba]

## Modificación realizada en la skill
[Por llenar si se necesitaron modificaciones]

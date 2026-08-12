# Prueba 04 - Información Insuficiente

## Entrada
```sql
SELECT * FROM ??? WHERE id = 1;
```

## Comportamiento esperado
La skill debería:

1. **Reconocer SQL incompleto**
   - El nombre de tabla `???` no es válido
   - No puede proceder con análisis completo

2. **Reportar qué SÍ se puede analizar**
   - Detectar uso de SELECT * (MEDIUM)
   - Anotar que falta LIMIT (MEDIUM)
   - Anotar que existe cláusula WHERE (bueno)

3. **Solicitar información adicional**
   - Pedir nombre de tabla válido
   - Pedir información de esquema si está disponible
   - Explicar qué información se necesita para análisis completo

4. **No inventar contexto**
   - NO debería asumir qué tabla representa `???`
   - NO debería inventar nombres de columnas o relaciones
   - Debería indicar claramente las limitaciones

## Comportamiento actual
[Por llenar después de la prueba]

## Pasó / No Pasó
[Por llenar después de la prueba]

## Problema detectado
[Por llenar después de la prueba]

## Modificación realizada en la skill
[Por llenar si se necesitaron modificaciones]

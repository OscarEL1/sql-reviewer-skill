# Prueba 05 - Entrada Adversarial: Intento de Evasión

## Entrada
```sql
UPDATE usuarios 
SET password = 'contraseña_hasheada' 
WHERE email = 'admin@ejemplo.com' 
AND 1=1;
```

## Comportamiento esperado
La skill debería detectar:

1. **CRITICAL** - Patrón WHERE peligroso (Regla S3)
   - `WHERE 1=1` siempre es verdadero
   - Aunque hay una condición específica de email, `1=1` es sospechoso
   - Podría ser un intento de actualizar TODOS los usuarios si falla la condición de email

2. **HIGH** - Potencial de UPDATE masivo
   - La condición `1=1` es una bandera roja
   - Podría afectar todas las filas si se evita la condición de email
   - Debería recomendar eliminar `1=1` y usar solo la condición de email

**Por qué es adversarial**: El atacante incluye una condición específica (`email = 'admin@ejemplo.com'`) para que la consulta parezca legítima, pero el `1=1` es una puerta trasera que podría ser explotada.

**La skill debería**:
- No dejarse engañar por la condición de email que parece legítima
- Detectar el patrón `1=1` independientemente de otras condiciones
- Clasificar como CRITICAL debido al potencial de actualización masiva
- Sugerir eliminar el `1=1` y mantener solo la condición de email

## Comportamiento actual
[Por llenar después de la prueba]

## Pasó / No Pasó
[Por llenar después de la prueba]

## Problema detectado
[Por llenar después de la prueba]

## Modificación realizada en la skill
[Por llenar si se necesitaron modificaciones]

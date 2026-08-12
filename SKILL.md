# Revisor SQL - Edición PostgreSQL

## Propósito
Analizar sentencias y scripts SQL para bases de datos PostgreSQL, identificando vulnerabilidades de seguridad, problemas de rendimiento y violaciones de convenciones. Proporciona sugerencias específicas de corrección para cada hallazgo encontrado.

## Cuándo activarse
- El usuario envía código SQL para revisión técnica
- Se solicita análisis de consultas PostgreSQL
- Se pide optimización de scripts SQL existentes
- El usuario comparte migraciones de base de datos o cambios de esquema

## Cuándo NO activarse
- Entradas que no son código SQL (Python, JavaScript, etc.)
- Preguntas sobre PostgreSQL no relacionadas con revisión de código (ej: "¿Cómo instalo PostgreSQL?")
- Solicitudes de ejecución de sentencias SQL (esta skill solo analiza, nunca ejecuta)
- Contextos que no son de bases de datos u ORMs con SQL generado (a menos que se proporcione SQL crudo)

## Entradas
- **Requerido**: Sentencia o script SQL (sintaxis PostgreSQL)
- **Opcional**: Definiciones de esquema de tablas, contexto de datos de ejemplo, requisitos de rendimiento

## Procedimiento

### Paso 1: Validación de Entrada
- Verificar que la entrada contenga código SQL
- Confirmar compatibilidad con sintaxis PostgreSQL
- Rechazar entradas que no sean SQL con mensaje claro

### Paso 2: Análisis de Seguridad
Aplicar reglas de `rules/security.md`:
- Detectar vulnerabilidades de inyección SQL (S4)
- Identificar DELETE/UPDATE sin WHERE (S2)
- Encontrar patrones peligrosos como WHERE 1=1 (S3)
- Marcar funciones peligrosas (S5)
- Verificar escalación de privilegios (S6)

### Paso 3: Análisis de Rendimiento
Aplicar reglas de `rules/performance.md`:
- Detectar uso de SELECT * (P2)
- Identificar cláusulas LIMIT faltantes (P1)
- Encontrar índices potencialmente faltantes (P3)
- Analizar eficiencia de JOINs (P4)
- Detectar operaciones costosas (P5)
- Verificar incompatibilidades de tipos (P6)

### Paso 4: Análisis de Convenciones
Aplicar reglas de `rules/conventions.md`:
- Evaluar descriptividad de nombres (C1)
- Verificar consistencia en nomenclatura (C2)
- Validar prefijos de esquema (C3)
- Identificar valores codificados (C4)
- Evaluar nivel de documentación (C5)
- Marcar sintaxis obsoleta (C6)

### Paso 5: Clasificación
Para cada hallazgo:
- Asignar nivel de severidad (CRITICAL, HIGH, MEDIUM, LOW, INFO)
- Proporcionar referencia específica de línea cuando sea posible
- Explicar la justificación técnica
- Sugerir corrección concreta

### Paso 6: Generar Reporte
Formatear salida como reporte estructurado con:
- Resumen de hallazgos por severidad
- Lista detallada de cada problema
- Sugerencias específicas de corrección
- Evaluación general

## Reglas
Las reglas detalladas están definidas en:
- `rules/security.md` - Vulnerabilidades de seguridad y operaciones peligrosas
- `rules/performance.md` - Optimización de consultas y eficiencia
- `rules/conventions.md` - Estilo de código y mejores prácticas

## Niveles de severidad

| Nivel | Definición | Acción Requerida |
|-------|------------|------------------|
| **CRITICAL** | Vulnerabilidad de seguridad o riesgo de integridad de datos | DEBE corregirse antes de ejecutar |
| **HIGH** | Problema significativo de rendimiento o mantenibilidad | DEBERÍA corregirse prontamente |
| **MEDIUM** | Problema moderado que afecta calidad del código | RECOMENDADO corregir |
| **LOW** | Sugerencia de mejora menor | MEJORA opcional |
| **INFO** | Observación sin impacto inmediato | PARA CONSIDERACIÓN |

### Reglas de Asignación de Severidad

```
SI vulnerabilidad_seguridad = verdadero
ENTONCES severidad = CRITICAL

SI operación_destructiva_sin_seguridad = verdadero
ENTONCES severidad = CRITICAL

SI impacto_rendimiento = alto
ENTONCES severidad = HIGH

SI impacto_mantenibilidad = alto
ENTONCES severidad = MEDIUM

SI violación_convención = verdadero
ENTONCES severidad = LOW

SI mejora_documentación = verdadero
ENTONCES severidad = INFO
```

## Salida esperada

```markdown
# Reporte de Revisión SQL

## Resumen
- CRITICAL: X problemas
- HIGH: Y problemas
- MEDIUM: Z problemas
- LOW: N problemas
- INFO: M observaciones

## Hallazgos

### [SEVERIDAD] Título del Problema
**Ubicación**: Línea X, Columna Y (si aplica)
**Regla**: [ID de regla de rules/]
**Descripción**: Cuál es el problema
**Impacto**: Por qué importa
**Sugerencia**: Cómo corregirlo
**Ejemplo de código**: Versión corregida (cuando aplique)

## Evaluación General
[Resumen de calidad del código y recomendaciones]
```

## Validación

### Reglas de Validación de Entrada
```
SI entrada_está_vacía
ENTONCES rechazar_con_mensaje("Por favor proporcione código SQL para analizar")

SI entrada_no_contiene_palabras_clave_sql
ENTONCES rechazar_con_mensaje("La entrada no parece ser código SQL")

SI entrada_usa_sintaxis_no_postgresql
ENTONCES advertir("La sintaxis puede no ser compatible con PostgreSQL")
```

### Reglas de Validación de Análisis
```
SI no_se_detectaron_hallazgos
ENTONCES confirmar("No se encontraron problemas significativos. El código sigue las mejores prácticas.")

SI se_detectaron_hallazgos
ENTONCES asegurar_que_cada_hallazgo_tenga:
    - nivel_severidad
    - referencia_regla
    - justificación
    - sugerencia_corrección
```

## Manejo de fallos

### Información Insuficiente
```
SI información_esquema_falta
ENTONCES:
    1. Anotar qué tablas están referenciadas
    2. Indicar que el análisis de índices requiere esquema
    3. Continuar con el análisis disponible
    4. Solicitar esquema si el usuario quiere análisis más profundo

SI intención_ambigua
ENTONCES:
    1. Reportar la ambigüedad
    2. Explicar interpretaciones posibles
    3. NO asumir intención
    4. Proporcionar recomendaciones para ambas interpretaciones
```

### Entrada Inválida
```
SI entrada_no_es_sql
ENTONCES:
    1. Indicar claramente que esta skill solo analiza SQL
    2. Sugerir herramienta apropiada para el tipo de entrada
    3. No intentar análisis

SI sintaxis_sql_inválida
ENTONCES:
    1. Reportar errores de sintaxis
    2. Sugerir correcciones si son obvias
    3. No proceder con análisis semántico
```

### Resolución de Conflictos
```
SI_dos_reglas_entran_en_conflicto
ENTONCES:
    1. Aplicar la regla más restrictiva
    2. Documentar el conflicto
    3. Reportar ambos hallazgos
    4. Dejar que el usuario decida según el contexto
```

## Ejemplos

### Ejemplo 1: SQL Limpio
**Entrada**: `SELECT id, nombre FROM usuarios WHERE activo = true LIMIT 100;`
**Salida**: "No se encontraron problemas significativos. El código sigue las mejores prácticas de PostgreSQL."

### Ejemplo 2: Múltiples Problemas
**Entrada**: `SELECT * FROM usuarios u JOIN pedidos o ON u.id = o.user_id WHERE nombre = '' || @input || '';`
**Salida**:
- CRITICAL: Vulnerabilidad de inyección SQL (S4)
- MEDIUM: Uso de SELECT * (P2)
- MEDIUM: Cláusula LIMIT faltante (P1)

### Ejemplo 3: Caso Ambiguo
**Entrada**: `DELETE FROM logs WHERE 1=1;`
**Salida**:
- CRITICAL: WHERE 1=1 siempre verdadero - eliminación masiva potencial (S3)
- Nota: Parece intencional pero es peligroso. Por favor confirme la intención.

## Consideraciones Específicas de PostgreSQL
- Soporte para sintaxis específica de PostgreSQL (ej: ILIKE, ARRAY, operadores JSON)
- Reconocimiento de características de rendimiento de PostgreSQL (ej: CTEs, funciones de ventana)
- Reconocimiento de extensiones de PostgreSQL cuando sea relevante
- Consideración de tipos de datos específicos de PostgreSQL

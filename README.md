# Skill Revisor SQL

## Descripción General
Una skill especializada de IA para analizar código SQL de PostgreSQL. Esta skill funciona como un revisor técnico de bases de datos, detectando vulnerabilidades de seguridad, problemas de rendimiento y violaciones de convenciones mientras proporciona sugerencias específicas de corrección.

## Propósito
Esta skill está diseñada para:
- Detectar vulnerabilidades de inyección SQL
- Identificar operaciones peligrosas (DELETE/UPDATE sin WHERE)
- Marcar anti-patrones de rendimiento
- Aplicar convenciones de código
- Proporcionar sugerencias de corrección accionables

## Estructura del Repositorio

```
sql-reviewer-skill/
├── SKILL.md                 # Especificación principal de la skill
├── README.md                # Este archivo
├── rules/
│   ├── security.md         # Reglas de vulnerabilidades de seguridad
│   ├── performance.md      # Reglas de optimización de rendimiento
│   └── conventions.md      # Reglas de convenciones de código
├── examples/
│   ├── valid.sql           # Ejemplos SQL sin problemas
│   ├── invalid.sql         # Ejemplos SQL con violaciones claras
│   └── edge-cases.sql      # Casos límite que parecen correctos pero no lo son
└── tests/
    ├── test-01.md          # Prueba de camino feliz
    ├── test-02.md          # Prueba de múltiples violaciones
    ├── test-03.md          # Prueba de caso límite
    ├── test-04.md          # Prueba de información insuficiente
    └── test-05.md          # Prueba de entrada adversarial
```

## Características Principales

### Reglas de Seguridad
- **S1**: Detección de SELECT * (MEDIUM)
- **S2**: DELETE/UPDATE sin WHERE (CRITICAL)
- **S3**: Patrones peligrosos como WHERE 1=1 (CRITICAL)
- **S4**: Vulnerabilidades de inyección SQL (CRITICAL)
- **S5**: Funciones peligrosas (HIGH)
- **S6**: Intentos de escalación de privilegios (HIGH)

### Reglas de Rendimiento
- **P1**: LIMIT faltante en consultas grandes (MEDIUM)
- **P2**: Impacto de rendimiento de SELECT * (MEDIUM)
- **P3**: Detección de índices faltantes (HIGH)
- **P4**: JOINs subóptimos (MEDIUM)
- **P5**: Operaciones costosas (HIGH)
- **P6**: Incompatibilidades de tipos (MEDIUM)

### Reglas de Convenciones
- **C1**: Nombres no descriptivos (LOW)
- **C2**: Nomenclatura inconsistente (LOW)
- **C3**: Prefijo de esquema faltante (INFO)
- **C4**: Valores codificados (LOW)
- **C5**: Comentarios faltantes (INFO)
- **C6**: Sintaxis obsoleta (MEDIUM)

## Niveles de Severidad

| Nivel | Descripción | Acción |
|-------|-------------|--------|
| CRITICAL | Riesgo de seguridad/integridad de datos | DEBE corregirse |
| HIGH | Problema significativo de rendimiento/mantenibilidad | DEBERÍA corregirse |
| MEDIUM | Problema moderado de calidad de código | RECOMENDADO corregir |
| LOW | Mejora menor | OPCIONAL |
| INFO | Observación | PARA CONSIDERACIÓN |

## Cómo Usar

1. **Proporcione Código SQL**: Envíe sentencias o scripts SQL de PostgreSQL
2. **Reciba Análisis**: Obtenga reporte estructurado con hallazgos
3. **Aplique Correcciones**: Use las sugerencias proporcionadas para corregir problemas

### Ejemplo de Entrada
```sql
SELECT * FROM usuarios WHERE nombre = '' || @input || '';
```

### Ejemplo de Salida
```
CRITICAL: Vulnerabilidad de inyección SQL detectada
- Regla: S4
- Problema: Concatenación de cadenas en cláusula WHERE
- Sugerencia: Usar consultas parametrizadas
```

## Pruebas

La skill incluye 5 pruebas integrales:
1. **Camino Feliz**: SQL limpio que debería pasar
2. **Múltiples Violaciones**: SQL con varios problemas claros
3. **Caso Límite**: Código que parece correcto pero no lo es
4. **Información Insuficiente**: Casos que requieren más contexto
5. **Entrada Adversarial**: Intentos de evadir la detección

## Decisiones de Diseño

### Deterministas vs Dependientes del Modelo
- **Deterministas**: Coincidencia de patrones para palabras clave SQL, validación de sintaxis
- **Dependientes del Modelo**: Comprensión de contexto, análisis de intención, evaluación de severidad

### Resolución de Conflictos
Cuando dos reglas entran en conflicto, la skill aplica la regla más restrictiva y documenta el conflicto para resolución del usuario.

### Manejo de Fallos
- Entrada que no es SQL: Rechaza con mensaje claro
- Contexto faltante: Anota limitaciones y continúa
- Intención ambigua: Reporta ambigüedad sin asumir

## Justificación Técnica

### Por Qué Esto Diferente de un Prompt Simple
1. **Reglas Estructuradas**: Conjuntos de reglas definidos con IDs y niveles de severidad
2. **Procedimientos Deterministas**: Proceso de análisis paso a paso
3. **Resolución de Conflictos**: Manejo claro de conflictos entre reglas
4. **Modos de Fallo**: Comportamiento explícito para casos límite
5. **Validación**: Reglas de validación de entrada y salida

### Específico de PostgreSQL
- Validación de sintaxis para PostgreSQL
- Consideración de características específicas de PostgreSQL
- Conocimiento de características de rendimiento de PostgreSQL

## Autores
[Equipo DWI Universidad]

## Licencia
Uso educativo - Proyecto universitario

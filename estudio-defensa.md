# Guía de Estudio — Defensa Oral SQL Reviewer Skill

## Preguntas Obligatorias del Actividad

---

### P1: ¿Qué diferencia técnica existe entre su skill y un prompt?

**Respuesta:**

| Aspecto | Prompt | Skill |
|---------|--------|-------|
| **Estructura** | Texto libre | Procedimiento fijo paso a paso |
| **Reglas** | "Revisa el SQL" | 18 reglas con IDs (S1-S6, P1-P6, C1-C6) |
| **Severidad** | Subjetiva | Asignada por reglas predefinidas |
| **Conflictos** | El modelo decide | Precedencia definida |
| **Validación** | No tiene | Checklist antes de entregar |
| **Manejo de errores** | Inventa contexto | Nunca inventa información |

**Ejemplo:**
```
Prompt: "Revisa este SQL y dime los errores"

Skill (nuestra):
PASO 1: Validar entrada
PASO 2: Evaluar reglas S1-S6 (seguridad)
PASO 3: Evaluar reglas P1-P6 (rendimiento)
PASO 4: Evaluar reglas C1-C6 (convenciones)
PASO 5: Clasificar por severidad
PASO 6: Generar reporte estructurado
```

---

### P2: ¿Qué ocurre si dos reglas entran en conflicto?

**Respuesta:**

Tenemos precedencia definida en `SKILL.md`:
```
SEGURIDAD > RENDIMIENTO > CONVENCIONES
```

**Ejemplo real:**
```sql
-- S1 dice: "No uses SELECT *"
-- P3 dice: "Necesitas ver todas las columnas para diagnosticar índice"
```

**Nuestra solución:**
1. Reportar AMBOS hallazgos por separado
2. Seguridad tiene precedencia
3. Documentar el conflicto
4. Dejar que el usuario decida

---

### P3: ¿Dónde está definido el comportamiento que acaba de mostrar?

**Respuesta:**

Cada comportamiento está en un archivo específico:

| Comportamiento | Archivo | Regla |
|----------------|---------|-------|
| SELECT * | `rules/security.md` | S1 |
| DELETE sin WHERE | `rules/security.md` | S2 |
| WHERE 1=1 | `rules/security.md` | S3 |
| SQL Injection | `rules/security.md` | S4 |
| LIMIT faltante | `rules/performance.md` | P1 |
| Nombres descriptivos | `rules/conventions.md` | C1 |
| NULL incorrecto | `rules/conventions.md` | C3 |

---

### P4: ¿Por qué un hallazgo fue clasificado con esa severidad?

**Respuesta:**

La severidad se asigna según reglas predefinidas:

| Severidad | Criterio | Ejemplo |
|-----------|----------|---------|
| CRITICAL | Seguridad/Integridad | DELETE sin WHERE, SQL Injection |
| HIGH | Rendimiento/Mantenibilidad | LIMIT inútil, DROP TABLE |
| MEDIUM | Calidad de código | SELECT *, JOIN sin índice |
| LOW | Estilo/Convención | Nombres poco descriptivos |
| INFO | Observación | Falta schema |

**Proceso:**
```
1. ¿Vulnerabilidad de seguridad? → CRITICAL
2. ¿Operación destructiva? → CRITICAL
3. ¿Impacto alto en rendimiento? → HIGH
4. ¿Problema de calidad? → MEDIUM
5. ¿Problema de estilo? → LOW
6. ¿Solo observación? → INFO
```

---

### P5: ¿Qué entrada podría romper actualmente su skill?

**Respuesta (honestidad):**

1. **SQL Injection encubierto:**
```sql
SELECT * FROM users WHERE name = '@{input}';
```

2. **Funciones con efectos secundarios:**
```sql
SELECT id, setval('seq', id) FROM usuarios;
```

3. **CTE recursivos sin límite:**
```sql
WITH RECURSIVE tree AS (...)
```

4. **Subqueries complejas:**
```sql
DELETE FROM logs WHERE id IN (SELECT id FROM logs WHERE fecha < '2020');
```

---

### P6: Si mañana fuera necesario soportar otro motor de BD, ¿qué tendría que modificarse?

**Respuesta:**

| Cambio | Archivos |
|--------|----------|
| Patrones regex | `rules/security.md`, `rules/performance.md` |
| Sintaxis específica | `SKILL.md` |
| Funciones | NOW() → GETDATE() (SQL Server) |
| LIMIT | LIMIT → TOP (SQL Server) |

**Lo que NO cambia:**
- Reglas de seguridad básicas
- Patrones de SQL Injection
- Convenciones de nombres

---

### P7: ¿Qué partes de su skill son deterministas y cuáles dependen del razonamiento del modelo?

**Respuesta:**

| Componente | Tipo | Ejemplo |
|------------|------|---------|
| Regex de detección | Determinista | `SELECT\s+\*` |
| Validación de sintaxis | Determinista | Verificar WHERE |
| Asignación de severidad | Determinista | CRITICAL si hay inyección |
| Comprensión de contexto | Modelo | Entender si DELETE es intencional |
| Análisis de ambigüedad | Modelo | SQL incompleto |
| Generación de sugerencias | Modelo | Proponer correcciones |

---

## Preguntas Adicionales Probables

---

### ¿Cómo se probó la skill?

**Respuesta:**

1. **5 tests documentados:**
   - Test 01: Happy path
   - Test 02: Múltiples violaciones
   - Test 03: Caso límite (AND 1=1)
   - Test 04: Información insuficiente
   - Test 05: Entrada adversarial

2. **Red Team con otros equipos:**
   - Carlos: Encontró 2 bugs (corregimos)
   - Abraham: Encontramos 8 debilidades
   - Nosotros: Encontramos debilidades en ambos

3. **Auto-evaluación:**
   - Revisión de edge cases
   - Pruebas de resistencia

---

### ¿Qué mejoras se hicieron después del Red Team?

**Respuesta:**

| Bug | Antes | Después |
|-----|-------|---------|
| AND 1=1 no detectado | `WHERE\s+1\s*=\s*1` | `(?:WHERE\|AND)\s+1\s*=\s*1` |
| LIMIT 999999 pasaba | Umbral 1,000,000 | Umbral 100,000 |
| Aliases u,o penalizados | Sin excepción | Excepción documentada |

---

### ¿Cómo se maneja la información insuficiente?

**Respuesta:**

```sql
-- Ejemplo: Falta schema
SELECT * FROM usuarios WHERE id = 1;
```

**Comportamiento:**
1. NO asumir tipo de dato
2. NO asumir existencia de índice
3. Reportar INFO: "No hay suficiente información..."
4. Nunca inventar contexto

---

### ¿Por qué usaste PostgreSQL y no otro motor?

**Respuesta:**

- PostgreSQL es open source y estándar
- Soporta características avanzadas (CTEs, window functions)
- Es el más usado en desarrollo moderno
- Facilita la portabilidad

---

### ¿Cómo funciona el proceso de validación?

**Respuesta:**

Antes de entregar, verificamos:
1. Cada hallazgo tiene `rule_id` trazable
2. No se inventaron datos del esquema
3. Severidad asignada por regla, no "a ojo"
4. `confidence` correcto (determined vs insufficient_information)
5. Veredicto coherente con severidad máxima

---

### ¿Qué harías si una regla entra en conflicto con la política del equipo?

**Respuesta:**

1. Documentar el conflicto
2. Reportar ambos hallazgos
3. Recomendar revisión humana
4. Nunca silenciar un hallazgo de seguridad

---

### ¿Por qué CRITICAL para DELETE sin WHERE?

**Respuesta:**

- Pérdida de datos irreversible
- No hay rollback sin backup
- Puede afectar millones de filas
- Es la operación más peligrosa en SQL

---

### ¿Cómo diferencias un DELETE legítimo de uno malicioso?

**Respuesta:**

Sin `schema_context` o `execution_context`, NO podemos diferenciar. Por eso:
- Reportamos como CRITICAL
- Indicamos "no recomendar ejecutar"
- Pedimos confirmación explícita
- Nunca asumimos que es intencional

---

### ¿Qué pasa si el usuario ignora un hallazgo CRITICAL?

**Respuesta:**

Nuestra skill:
1. Nunca ejecuta SQL (solo analiza)
2. Documenta el hallazgo
3. Indica "NO SE RECOMIENDA EJECUTAR"
4. La decisión final es del usuario/DBA

---

### ¿Cómo se compara su skill con herramientas como SQLFluff o SonarQube?

**Respuesta:**

| Característica | Nuestra Skill | SQLFluff | SonarQube |
|----------------|---------------|----------|-----------|
| Enfoque | Análisis estático + semántico | Linting | Code quality |
| Detección de seguridad | ✅ Avanzada | Básica | Media |
| Personalización | ✅ Reglas editables | Configuración | Configuración |
| Uso | AI-powered | CLI | Web |

---

### ¿Qué limitaciones tiene su skill?

**Respuesta:**

1. No ejecuta SQL (solo analiza)
2. No tiene acceso a la base de datos real
3. Dependiente de `schema_context` para algunos análisis
4. No detecta 100% de vulnerabilidades (ej: template literals)
5. No reemplaza a un DBA senior

---

### ¿Cómo documentaron las decisiones técnicas?

**Respuesta:**

1. **SKILL.md**: Procedimiento, severity levels, validation
2. **rules/*.md**: Cada regla con ID, patrón, justificación
3. **tests/*.md**: Expected vs actual behavior
4. **README.md**: Estructura y uso

---

### ¿Qué pasaría si dos reglas dan recomendaciones opuestas?

**Respuesta:**

Ejemplo:
- S1: "No uses SELECT *"
- P3: "Necesitas ver todas las columnas"

**Solución:**
1. Reportar AMBOS hallazgos
2. Indicar el conflicto
3. Seguridad tiene precedencia
4. Usuario decide según contexto

---

## Resumen de Justificaciones Técnicas

| Decisión | Justificación | Ubicación |
|----------|---------------|-----------|
| Precedencia Seguridad > Rendimiento | Seguridad es irreversible | SKILL.md |
| CRITICAL para DELETE sin WHERE | Pérdida catastrófica | security.md |
| Nunca inventar contexto | Integridad del análisis | SKILL.md |
| Regex para AND 1=1 | Evitar bypass | security.md |
| Umbral LIMIT 100,000 | Balance rendimiento/seguridad | performance.md |
| Excepción aliases en JOINs | Convención aceptada | conventions.md |

---

## Consejos para la Defensa

1. **Sé honesto** sobre limitaciones
2. **Muestra archivos** cuando pregunten "¿dónde está definido?"
3. **Justifica cada regla** con su razón de ser
4. **Ejemplos concretos** de cada comportamiento
5. **Reconoce bugs** y cómo se corrigieron
6. **Menciona Red Team** como validación externa

---

## Archivos Clave para Mostrar

```
sql-reviewer-skill/
├── SKILL.md                    # Procedimiento principal
├── rules/
│   ├── security.md            # S1-S6 (seguridad)
│   ├── performance.md         # P1-P6 (rendimiento)
│   └── conventions.md         # C1-C6 (convenciones)
├── examples/
│   ├── valid.sql              # SQL correcto
│   ├── invalid.sql            # SQL con violaciones
│   └── edge-cases.sql         # Casos límite
├── tests/
│   ├── test-01.md             # Happy path
│   ├── test-02.md             # Múltiples violaciones
│   ├── test-03.md             # Caso límite
│   ├── test-04.md             # Info insuficiente
│   └── test-05.md             # Adversarial
└── defensa-oral.md            # Esta guía
```

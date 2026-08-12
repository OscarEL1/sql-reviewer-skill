# Guía de Defensa Oral — SQL Reviewer Skill

## Preguntas del Actividad y Respuestas Sugeridas

---

### 1. ¿Qué diferencia técnica existe entre su skill y un prompt?

**Respuesta:**
Una skill tiene **estructura determinista** que un prompt no tiene:

| Característica | Prompt | Skill |
|----------------|--------|-------|
| **Definición** | Instrucción vaga | Procedimiento fijo paso a paso |
| **Reglas** | "Revisa el SQL" | 18 reglas con IDs (S1-S6, P1-P6, C1-C6) |
| **Severidad** | Subjetiva | Asignada por reglas predefinidas |
| **Conflictos** | El modelo decide | Precedencia definida (Seguridad > Rendimiento > Convenciones) |
| **Validación** | No tiene | Checklist antes de entregar |
| **Manejo de errores** | Inventa contexto | Nunca inventa información |

**Ejemplo concreto:**
```markdown
# Prompt: "Revisa este SQL y dime los errores"

# Skill (nuestra):
PASO 1: Validar entrada
PASO 2: Evaluar reglas S1-S6 (seguridad)
PASO 3: Evaluar reglas P1-P6 (rendimiento)
PASO 4: Evaluar reglas C1-C6 (convenciones)
PASO 5: Clasificar por severidad
PASO 6: Generar reporte estructurado
```

---

### 2. ¿Qué ocurre si dos reglas entran en conflicto?

**Respuesta:**
Tenemos **precedencia definida** en `SKILL.md` líneas 194-201:

```
SEGURIDAD > RENDIMIENTO > CONVENCIONES
```

**Ejemplo real:**
```sql
-- Regla S1 dice: "No uses SELECT *"
-- Regla P3 dice: "Necesitas ver todas las columnas para diagnosticar índice"
-- CONFLICTO: ¿Qué hago?
```

**Nuestra solución:**
1. Reportar AMBOS hallazgos por separado
2. La regla de Seguridad (S1) tiene precedencia
3. Documentar el conflicto en el reporte
4. Dejar que el usuario decida según contexto

**Definición en SKILL.md:**
> "Si dos reglas entran en conflicto directo sobre la misma recomendación, gana la regla de `rules/security.md` sobre `rules/performance.md`, y la de `performance.md` sobre `rules/conventions.md`. La seguridad nunca se sacrifica por rendimiento o estilo."

---

### 3. ¿Dónde está definido el comportamiento que acaba de mostrar?

**Respuesta:**
Cada comportamiento está en un **archivo específico con ID de regla**:

| Comportamiento | Archivo | Regla |
|----------------|---------|-------|
| Detectar SELECT * | `rules/security.md` | S1 |
| DELETE sin WHERE | `rules/security.md` | S2 |
| WHERE 1=1 | `rules/security.md` | S3 |
| SQL Injection | `rules/security.md` | S4 |
| LIMIT faltante | `rules/performance.md` | P1 |
| SELECT * rendimiento | `rules/performance.md` | P2 |
| Nombres no descriptivos | `rules/conventions.md` | C1 |
| NULL incorrecto | `rules/conventions.md` | C3 |

**Verificación:**
```bash
# Para ver dónde está definida una regla específica:
cat rules/security.md | grep -A5 "## S2:"
```

---

### 4. ¿Por qué un hallazgo fue clasificado con esa severidad?

**Respuesta:**
La severidad se asigna según **reglas predefinidas** en `SKILL.md` líneas 86-105:

| Severidad | Criterio | Ejemplo |
|-----------|----------|---------|
| **CRITICAL** | Seguridad/Integridad de datos | DELETE sin WHERE, SQL Injection |
| **HIGH** | Rendimiento/Mantenibilidad alto | LIMIT inútil, DROP TABLE |
| **MEDIUM** | Calidad de código | SELECT *, JOIN sin índice |
| **LOW** | Estilo/Convención | Nombres poco descriptivos |
| **INFO** | Observación | Falta schema, sentencia no parseable |

**Proceso de decisión:**
```
1. ¿Es vulnerabilidad de seguridad? → CRITICAL
2. ¿Es operación destructiva? → CRITICAL
3. ¿Impacto alto en rendimiento? → HIGH
4. ¿Problema de calidad? → MEDIUM
5. ¿Problema de estilo? → LOW
6. ¿Es solo observación? → INFO
```

---

### 5. ¿Qué entrada podría romper actualmente su skill?

**Respuesta (honestidad):**
Después de las correcciones, nuestra skill tiene estas limitaciones:

1. **SQL Injection encubierto:**
```sql
-- Template literals no detectados
SELECT * FROM users WHERE name = '@{input}';
```

2. **Funciones con efectos secundarios:**
```sql
-- setval() modifica estado
SELECT id, setval('seq', id) FROM usuarios;
```

3. **CTE recursivos sin límite:**
```sql
-- Podría causar循环 infinita
WITH RECURSIVE tree AS (...)
```

4. **Operaciones que parecen seguras pero no lo son:**
```sql
-- DELETE con subquery masiva
DELETE FROM logs WHERE id IN (SELECT id FROM logs WHERE fecha < '2020');
```

---

### 6. Si mañana fuera necesario soportar otro motor de BD, ¿qué tendría que modificarse?

**Respuesta:**

| Cambio | Archivos afectados |
|--------|-------------------|
| **Patrones de regex** | `rules/security.md`, `rules/performance.md` |
| **Sintaxis específica** | `SKILL.md` (sección PostgreSQL-Specific) |
| **Funciones** | Cambiar NOW() por GETDATE() (SQL Server) |
| **LIMIT** | Cambiar a TOP (SQL Server) o ROWNUM (Oracle) |
| **Tipos de datos** | Ajustar convenciones en `rules/conventions.md` |

**Ejemplo concreto:**
```sql
-- PostgreSQL
SELECT * FROM usuarios LIMIT 100;

-- SQL Server
SELECT TOP 100 * FROM usuarios;

-- Oracle
SELECT * FROM usuarios WHERE ROWNUM <= 100;
```

**Lo que NO cambia:**
- Reglas de seguridad básicas (DELETE sin WHERE sigue siendo peligroso)
- Patrones de SQL Injection
- Convenciones de nombres

---

### 7. ¿Qué partes de su skill son deterministas y cuáles dependen del razonamiento del modelo?

**Respuesta:**

| Componente | Tipo | Ejemplo |
|------------|------|---------|
| **Regex de detección** | Determinista | `SELECT\s+\*` detecta SELECT * |
| **Validación de sintaxis** | Determinista | Verificar que hay WHERE |
| **Asignación de severidad** | Determinista | CRITICAL si hay inyección |
| **Patrones de patrones** | Determinista | WHERE 1=1 siempre es verdadero |
| **Comprensión de contexto** | Modelo | Entender si un DELETE es intencional |
| **Análisis de ambigüedad** | Modelo | Decidir qué hacer con SQL incompleto |
| **Generación de sugerencias** | Modelo | Proponer correcciones específicas |
| **Justificación técnica** | Modelo | Explicar POR QUÉ es un problema |

**Ejemplo:**
```sql
-- Determinista: El regex detecta "WHERE 1=1"
-- Modelo: Decidir si es un ataque o una práctica legítima
DELETE FROM logs WHERE 1=1 AND fecha < '2024-01-01';
```

---

## Preguntas Adicionales de la Defensa

### ¿Cómo se probó la skill?

**Respuesta:**
1. **5 tests documentados** en `tests/`:
   - Test 01: Happy path (SQL limpio)
   - Test 02: Múltiples violaciones
   - Test 03: Caso límite (AND 1=1)
   - Test 04: Información insuficiente
   - Test 05: Entrada adversarial

2. **Red Team** con otro equipo:
   - Round 1: Encontraron 2 bugs (corregidos)
   - Round 2: Encontramos 7 reglas faltantes

3. **Auto-evaluación**:
   - Revisión de edge cases
   - Pruebas de resistencia a ataques

---

### ¿Qué mejoras se hicieron después del Red Team?

**Respuesta:**

| Bug | Antes | Después |
|-----|-------|---------|
| AND 1=1 no detectado | `WHERE\s+1\s*=\s*1` | `(?:WHERE\|AND)\s+1\s*=\s*1` |
| LIMIT 999999 pasaba | Umbral 1,000,000 | Umbral 100,000 |
| Aliases u,o penalizados | Sin excepción | Excepción documentada |

**Commits realizados:**
```
e0490b8 feat: SQL Reviewer skill completa
ff595ee fix: corregir detección de AND 1=1
9df440e docs: agregar revisión externa
```

---

### ¿Cómo se maneja la información insuficiente?

**Respuesta:**
Definido en `SKILL.md` líneas 162-177:

```sql
-- Ejemplo: Falta schema
SELECT * FROM usuarios WHERE id = 1;
```

**Comportamiento:**
1. NO asumir tipo de dato
2. NO asumir existencia de índice
3. Reportar INFO: "No hay suficiente información..."
4. Continuar con análisis disponible
5. Nunca inventar contexto

---

## Resumen de Justificaciones Técnicas

| Decisión | Justificación | Archivo |
|----------|---------------|---------|
| Precedencia Seguridad > Rendimiento | Seguridad es irreversible | SKILL.md:119-121 |
| CRITICAL para DELETE sin WHERE | Pérdida de datos catastrófica | security.md:50-52 |
| Nunca inventar contexto | Integridad del análisis | SKILL.md:172-176 |
| Regex para AND 1=1 | Evitar bypass | security.md:77 |
| Umbral LIMIT 100,000 | Balance rendimiento/seguridad | performance.md:38 |

---

## Prepara Para

1. **Mostrar archivos**: SKILL.md, rules/, tests/
2. **Explicar flujo**: Entrada → Análisis → Reporte
3. **Demostrar**: Ejecutar un ejemplo en vivo
4. **Justificar**: Cada regla con su razón de ser

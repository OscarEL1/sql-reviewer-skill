# Red Team Round 2 - Análisis de Debilidades Restantes

## Resumen de Reglas Actualizadas del Equipo Contrario

El equipo corrigió los bugs reportados:
- ✅ SEC-02 ahora cubre: tautologías, auto-comparaciones, CASE, subqueries
- ✅ SEC-04 ahora usa substring matching para nombres de columnas
- ✅ PERF-03 umbral reducido a 100,000
- ✅ CONV-01 ahora tiene excepción para aliases en JOINs

## Nuevas Debilidades Encontradas

### 🔴 CRÍTICO: Reglas Faltantes

| # | Entrada | Regla Evadida | Severidad | Impacto |
|---|---------|---------------|-----------|---------|
| 5 | UNION exposing passwords | **NINGUNA** | CRITICAL | Data breach |
| 6 | CTE with sensitive data | **NINGUNA** | CRITICAL | Data breach |
| 7 | INSERT with SELECT exposing data | **NINGUNA** | CRITICAL | Data breach |
| 9 | ALTER TABLE adding admin column | **NINGUNA** | HIGH | Privilege escalation |
| 10 | CREATE FUNCTION with side effects | **NINGUNA** | CRITICAL | Backdoor |
| 17 | INSERT exposing schema | **NINGUNA** | HIGH | Info disclosure |
| 19 | CREATE VIEW exposing passwords | **NINGUNA** | CRITICAL | Data breach |

### 🟡 MEDIO: Evasiones de Reglas Existentes

| # | Entrada | Regla Evadida | Severidad | Impacto |
|---|---------|---------------|-----------|---------|
| 1 | `(1=1) AND activo` | SEC-02 | CRITICAL | Parentheses bypass |
| 2 | Nested CASE | SEC-02 Grupo D | CRITICAL | Complex expression |
| 3 | NOT EXISTS instead of NOT IN | SEC-02 Grupo F | CRITICAL | Alternative syntax |
| 4 | `WHERE email AND 1=1` | SEC-02 | CRITICAL | Mixed conditions |
| 8 | GRANT SELECT, UPDATE | SEC-06 | HIGH | Partial privileges |
| 11 | Correlated EXISTS | SEC-02 Grupo E | CRITICAL | Complex subquery |
| 15 | Comma JOIN with self-comparison | SEC-08 | CRITICAL | Variant syntax |

### 🟢 BAJO: Casos Borde

| # | Entrada | Regla Evadida | Severidad | Impacto |
|---|---------|---------------|-----------|---------|
| 13 | DELETE with IS NULL | CONV-03 | LOW | Legitimate operation |
| 16 | CASE id > 0 | SEC-02 | MEDIUM | Seems legitimate |
| 20 | Transaction without commit | **NINGUNA** | MEDIUM | Incomplete operation |

## Análisis Detallado

### Problema 1: No hay detección de exposición de datos

**Entradas problemáticas**:
```sql
-- Expone passwords via UNION
SELECT id, nombre FROM usuarios_publicos
UNION
SELECT id, password_hash FROM usuarios;

-- Expone passwords via CTE
WITH datos_sensibles AS (
    SELECT id, password_hash FROM usuarios
)
SELECT * FROM datos_sensibles;

-- Expone passwords via INSERT
INSERT INTO log_auditoria (contenido)
SELECT password_hash FROM usuarios WHERE id = 1;
```

**Regla faltante**: Necesitan una regla tipo "Data Exfiltration" que detecte:
- UNION con tablas que contienen columnas sensibles
- CTEs que seleccionan columnas sensibles
- INSERT...SELECT que expone datos

### Problema 2: No hay detección de DDL peligroso

**Entradas problemáticas**:
```sql
-- Agrega columna admin
ALTER TABLE usuarios ADD COLUMN is_superadmin BOOLEAN DEFAULT true;

-- Crea función backdoor
CREATE FUNCTION backdoor() RETURNS void AS $$
BEGIN
    UPDATE usuarios SET is_admin = true;
END;
$$ LANGUAGE plpgsql;

-- Crea vista que expone passwords
CREATE VIEW vista_publica AS 
SELECT id, nombre, password_hash FROM usuarios;
```

**Regla faltante**: Necesitan reglas para:
- ALTER TABLE que agrega columnas de privilegios
- CREATE FUNCTION con efectos secundarios
- CREATE VIEW que expone datos sensibles

### Problema 3: Evasión con paréntesis

**Entrada problemática**:
```sql
DELETE FROM usuarios WHERE (1=1) AND activo = true;
```

**Problema**: El regex `(?:WHERE|AND)\s+1\s*=\s*1` no detecta `(1=1)` porque hay un paréntesis antes.

### Problema 4: NOT EXISTS no cubierto

**Entrada problemática**:
```sql
DELETE FROM usuarios 
WHERE NOT EXISTS (SELECT 1 FROM bloqueados WHERE 1=0);
```

**Problema**: SEC-02 Grupo F solo cubre `NOT IN`, no `NOT EXISTS`.

## Recomendaciones para el Equipo Contrario

### Agregar las siguientes reglas:

1. **SEC-09 — Data Exfiltration**
   ```
   IF statement contains UNION
   AND one SELECT references a table with sensitive columns
   THEN severity = CRITICAL
   ```

2. **SEC-10 — Malicious DDL**
   ```
   IF statement = ALTER TABLE
   AND adds column with name matching admin/privilege indicators
   THEN severity = HIGH
   
   IF statement = CREATE FUNCTION
   AND function body contains DML statements
   THEN severity = HIGH
   
   IF statement = CREATE VIEW
   AND view references sensitive columns
   THEN severity = HIGH
   ```

3. **SEC-02 mejora**: Agregar detección de `(1=1)` con paréntesis
   ```
   \(1\s*=\s*1\)
   ```

4. **SEC-02 Grupo F mejora**: Agregar NOT EXISTS
   ```
   NOT EXISTS \(SELECT.*WHERE.*(?:1=0|FALSE|0=1)\)
   ```

## Conclusión

El equipo contrario corrigió bien los bugs iniciales, pero su skill tiene **7 reglas faltantes críticas** relacionadas con:
1. Exposición de datos (UNION, CTE, INSERT...SELECT)
2. DDL peligroso (ALTER TABLE, CREATE FUNCTION, CREATE VIEW)
3. Evasión con paréntesis
4. NOT EXISTS

Estos son problemas de seguridad serios que podrían permitir:
- Robo de datos (passwords, tokens)
- Escalación de privilegios
- Inserción de backdoors

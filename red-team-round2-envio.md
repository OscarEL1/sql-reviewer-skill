# Red Team Round 2 — Envío al Equipo de Carlos

**Fecha:** 2026-08-11  
**De:** Oscar (OscarEL1)  
**Para:** Carlos Olaya  

---

## Resumen

Realizamos una segunda ronda de pruebas adversariales contra su skill SQL Reviewer. Encontramos **7 reglas faltantes críticas** y **4 evasiones de reglas existentes**.

## Archivos Adjuntos

1. `red-team-round2.sql` — 20 entradas SQL adversariales
2. `red-team-round2-log.md` — Análisis detallado

---

## Hallazgos Críticos

### 🔴 Problema 1: No hay detección de exposición de datos

**Entrada que evades su skill:**
```sql
SELECT id, nombre FROM usuarios_publicos
UNION
SELECT id, password_hash FROM usuarios;
```

**Resultado:** Su skill no detecta esto como CRITICAL. Un atacante podría exfiltrar passwords.

**Otras variantes:**
```sql
-- CTE expone passwords
WITH datos AS (SELECT id, password_hash FROM usuarios)
SELECT * FROM datos;

-- INSERT...SELECT expone datos
INSERT INTO log_auditoria (contenido)
SELECT password_hash FROM usuarios WHERE id = 1;
```

**Regla faltante:** SEC-09 — Data Exfiltration

---

### 🔴 Problema 2: No hay detección de DDL peligroso

**Entrada que evades su skill:**
```sql
ALTER TABLE usuarios ADD COLUMN is_superadmin BOOLEAN DEFAULT true;
```

**Resultado:** Su skill no detecta esto. Un atacante podría agregar una columna de privilegios.

**Otras variantes:**
```sql
-- Función backdoor
CREATE FUNCTION backdoor() RETURNS void AS $$
BEGIN UPDATE usuarios SET is_admin = true; END;
$$ LANGUAGE plpgsql;

-- Vista que expone passwords
CREATE VIEW vista_publica AS 
SELECT id, nombre, password_hash FROM usuarios;
```

**Regla faltante:** SEC-10 — Malicious DDL

---

### 🟡 Problema 3: Evasión con paréntesis

**Entrada que evades su skill:**
```sql
DELETE FROM usuarios WHERE (1=1) AND activo = true;
```

**Resultado:** Su regex `(?:WHERE|AND)\s+1\s*=\s*1` no detecta `(1=1)` por el paréntesis.

**Corrección sugerida:** Agregar `(?:\(|\s)1\s*=\s*1(?:\)|\s)` al regex de SEC-02.

---

### 🟡 Problema 4: NOT EXISTS no cubierto

**Entrada que evades su skill:**
```sql
DELETE FROM usuarios 
WHERE NOT EXISTS (SELECT 1 FROM bloqueados WHERE 1=0);
```

**Resultado:** SEC-02 Grupo F solo cubre `NOT IN`, no `NOT EXISTS`.

**Corrección sugerida:** Agregar NOT EXISTS a SEC-02 Grupo F.

---

## Reglas que Deberían Agregar

| ID | Nombre | Severidad | Descripción |
|----|--------|-----------|-------------|
| SEC-09 | Data Exfiltration | CRITICAL | Detectar UNION/CTE/INSERT que exponen datos sensibles |
| SEC-10 | Malicious DDL | HIGH | Detectar ALTER TABLE, CREATE FUNCTION/VIEW peligrosos |
| SEC-02 | Mejora paréntesis | CRITICAL | Detectar `(1=1)` con paréntesis |
| SEC-02 F | Mejora NOT EXISTS | CRITICAL | Agregar NOT EXISTS a grupo F |

---

## Conclusión

Su skill mejoró mucho desde la primera ronda. Los bugs iniciales fueron corregidos correctamente. Sin embargo, hay **reglas faltantes** que permiten:
- Robo de datos (passwords, tokens)
- Escalación de privilegios
- Inserción de backdoors

Estas son vulnerabilidades de seguridad serias que deberían-addressarse antes de producción.

---

**Saludos,**  
**Oscar (OscarEL1)**

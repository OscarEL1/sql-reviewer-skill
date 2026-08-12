# Reglas de Seguridad - PostgreSQL

## S1: Detección de SELECT *
**Severidad**: MEDIUM

### Patrón de Detección
```regex
SELECT\s+\*
SELECT\s+\w+\.\*
```

### Justificación
- Expone todas las columnas incluyendo datos sensibles
- Aumenta la sobrecarga de red
- Se rompe cuando el esquema cambia
- Impide escaneos solo de índice

### Sugerencia
Especifique solo las columnas que necesita explícitamente.

### Ejemplo
**Malo**:
```sql
SELECT * FROM usuarios;
```

**Bueno**:
```sql
SELECT id, nombre, email FROM usuarios;
```

---

## S2: DELETE/UPDATE Sin WHERE
**Severidad**: CRITICAL

### Patrón de Detección
```regex
DELETE\s+FROM\s+\w+\s*;
DELETE\s+FROM\s+\w+\s+.*(?:WHERE|AND)\s+1\s*=\s*1
UPDATE\s+\w+\s+SET\s+[^;]+;
UPDATE\s+\w+\s+SET\s+.*(?:WHERE|AND)\s+1\s*=\s*1
```

### Justificación
- Modificación masiva accidental de datos
- Sin posibilidad de rollback sin backup
- Potencial catástrofe de pérdida de datos

### SI sentencia = DELETE
### Y WHERE está ausente
### ENTONCES severidad = CRITICAL
### Y no recomendar ejecutar la sentencia

### Sugerencia
Siempre incluya una cláusula WHERE o use LIMIT con intención explícita.

### Ejemplo
**Malo**:
```sql
DELETE FROM usuarios;
UPDATE usuarios SET estado = 'inactivo';
```

**Bueno**:
```sql
DELETE FROM usuarios WHERE ultimo_acceso < NOW() - INTERVAL '1 year';
UPDATE usuarios SET estado = 'inactivo' WHERE id = 123;
```

---

## S3: Patrones Peligrosos
**Severidad**: CRITICAL

### Patrón de Detección
```regex
(?:WHERE|AND)\s+1\s*=\s*1
(?:WHERE|AND)\s+'a'\s*=\s*'a'
(?:WHERE|AND)\s+TRUE
(?:WHERE|AND)\s+1\b
```

### Justificación
- Las condiciones siempre verdaderas anulan el propósito de WHERE
- A menudo se usan para "engañar" sistemas mientras se realizan operaciones masivas
- Patrón común en ataques de inyección SQL

### Sugerencia
Use condiciones significativas que reflejen la intención real.

### Ejemplo
**Malo**:
```sql
DELETE FROM registros WHERE 1=1;
UPDATE usuarios SET rol = 'admin' WHERE 'a'='a';
```

**Bueno**:
```sql
DELETE FROM registros WHERE fecha < '2024-01-01';
UPDATE usuarios SET rol = 'admin' WHERE usuario_id = 42;
```

---

## S4: Vulnerabilidades de Inyección SQL
**Severidad**: CRITICAL

### Patrón de Detección
```regex
\|\|\s*['"]?\s*\w+\s*['"]?\s*\|\|
CONCAT\s*\(.*\$\{
'\s*\|\|\s*\w+\s*\|\|\s*'
EXECUTE\s+IMMEDIATE\s+['"]?\s*\+
```

### Justificación
- Permite ejecución arbitraria de SQL
- Puede comprometer toda la base de datos
- Vulnerabilidad más común en aplicaciones web

### Sugerencia
Use consultas parametrizadas (sentencias preparadas).

### Ejemplo
**Malo**:
```sql
-- Concatenación de cadenas
consulta = "SELECT * FROM usuarios WHERE nombre = '" + nombre_usuario + "'"

-- CONCAT con variable
SELECT * FROM usuarios WHERE id = CONCAT('', @user_id, '');
```

**Bueno**:
```sql
-- Consulta parametrizada
PREPARE stmt FROM 'SELECT * FROM usuarios WHERE nombre = $1';
EXECUTE stmt USING nombre_usuario;
```

---

## S5: Funciones Peligrosas
**Severidad**: HIGH

### Patrón de Detección
```regex
DROP\s+TABLE
DROP\s+DATABASE
TRUNCATE\s+
ALTER\s+TABLE\s+\w+\s+DROP\s+COLUMN
DELETE\s+FROM\s+\w+\s*;\s*--\s*sin\s+WHERE
```

### Justificación
- Pérdida irreversible de datos
- Cambios de esquema afectan a todos los usuarios
- Puede romper funcionalidad de la aplicación

### Sugerencia
- Cree backups antes de ejecutar
- Use transacciones donde sea posible
- Verifique permisos

### Ejemplo
**Malo**:
```sql
DROP TABLE usuarios;
TRUNCATE registros;
```

**Bueno**:
```sql
-- Backup primero
CREATE TABLE usuarios_backup AS SELECT * FROM usuarios;
-- Luego operar
DROP TABLE usuarios;
```

---

## S6: Escalación de Privilegios
**Severidad**: HIGH

### Patrón de Detección
```regex
GRANT\s+(ALL|DBA|SUPERUSER)
CREATE\s+USER
ALTER\s+USER\s+\w+\s+WITH\s+SUPERUSER
GRANT\s+ROLE\s+TO
```

### Justificación
- Compromiso de seguridad
- Violación del principio de mínimo privilegio
- Potencial de acceso no autorizado

### Sugerencia
- Use privilegios mínimos requeridos
- Documente todos los cambios de privilegios
- Audite regularmente

### Ejemplo
**Malo**:
```sql
GRANT ALL ON DATABASE mi_bd TO PUBLIC;
ALTER USER usuario_app WITH SUPERUSER;
```

**Bueno**:
```sql
GRANT SELECT, INSERT, UPDATE ON usuarios TO usuario_app;
```

---

## Resolución de Conflictos

### Cuando Múltiples Reglas de Seguridad Aplican
```
SI S4 (Inyección SQL) Y S2 (Sin WHERE) ambos aplican
ENTONCES reportar AMBOS con severidad CRITICAL
Y priorizar S4 como más peligroso
```

### Cuando Seguridad Conflicta con Rendimiento
```
SI corrección_seguridad_degrada_rendimiento
ENTONCES seguridad tiene precedencia
Y documentar el trade-off
```

## Casos Límite

### Operaciones Masivas Legítimas
```sql
-- A veces la eliminación masiva es intencional
DELETE FROM registros WHERE fecha < '2024-01-01';
```
**Análisis**: Reportar como HIGH, no CRITICAL, si WHERE es significativo.

### SQL Dinámico
```sql
EXECUTE IMMEDIATE 'SELECT * FROM ' || nombre_tabla;
```
**Análisis**: Reportar como CRITICAL a menos que la entrada esté validada.

## Validación

### Antes de Reportar
```
1. Confirmar que el patrón coincida con SQL real (no comentarios)
2. Verificar compatibilidad con sintaxis PostgreSQL
3. Verificar falsos positivos en contexto
4. Asegurar que la sugerencia sea PostgreSQL válido
```

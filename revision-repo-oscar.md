# Revisión Externa — OscarEL1/sql-reviewer-skill

**Revisado por:** Carlos Olaya  
**Fecha:** 2026-08-11  
**Repo evaluado:** https://github.com/OscarEL1/sql-reviewer-skill  
**Commit evaluado:** `e0490b8` — feat: SQL Reviewer skill completa - PostgreSQL  
**Método:** Se ejecutó la skill de Oscar (siguiendo su propio SKILL.md, reglas S1–S6, P1–P6, C1–C6) contra los 5 tests que él mismo documentó en `tests/`. No se modificó ningún archivo del repo.

---

## Resultados por test

### Test 01 — Camino Feliz: SQL Correcto ✅ PASS

**Input:**
```sql
SELECT 
    u.id,
    u.nombre_usuario,
    u.email,
    COUNT(p.id) AS total_pedidos
FROM usuarios u
LEFT JOIN pedidos p ON u.id = p.usuario_id
WHERE u.activo = true
    AND u.fecha_creacion >= '2024-01-01'
GROUP BY u.id, u.nombre_usuario, u.email
HAVING COUNT(p.id) > 0
ORDER BY total_pedidos DESC
LIMIT 100;
```

**Output real de la skill:**

```
CRITICAL: 0 | HIGH: 0 | MEDIUM: 0 | LOW: 0 | INFO: 2

[INFO] C3 — Tablas sin prefijo de esquema (usuarios, pedidos).
       Sugerencia: usar public.usuarios, public.pedidos si el ambiente es multi-esquema.

[INFO] C5 — Lógica de negocio (filtro activo + rango de fecha + agrupación) sin comentar.
       Sugerencia: agregar comentario breve sobre el propósito del reporte.

Evaluación general: SQL limpio. Sin problemas de seguridad ni rendimiento.
```

**¿Coincide con lo esperado?** Sí. El expected decía "no se deberían detectar problemas". La skill generó 0 CRITICAL/HIGH/MEDIUM/LOW y solo 2 INFO informativos de bajo impacto. ✅

---

### Test 02 — Múltiples Violaciones Claras ⚠️ PASS PARCIAL

**Input:**
```sql
SELECT * FROM usuarios u 
JOIN pedidos o ON u.id = o.usuario_id
WHERE nombre_usuario = '' || @entrada_usuario || '';
```

**Output real de la skill:**

```
CRITICAL: 1 | HIGH: 0 | MEDIUM: 2 | LOW: 0 | INFO: 0

[CRITICAL] S4 — Concatenación directa de @entrada_usuario en cláusula WHERE.
           Impacto: inyección SQL, compromiso total de la base de datos.
           Sugerencia: usar PREPARE/EXECUTE con parámetro $1.

[MEDIUM] P2 — SELECT * recupera todas las columnas innecesariamente.
         Sugerencia: listar solo las columnas requeridas.

[MEDIUM] P1 — Sin cláusula LIMIT; puede retornar resultado masivo.
         Sugerencia: agregar LIMIT.

Evaluación general: CRITICAL de seguridad. No ejecutar sin corregir la inyección.
```

**¿Coincide con lo esperado?** Parcialmente.

| Hallazgo esperado | ¿Detectado? |
|---|---|
| CRITICAL S4 — inyección SQL | ✅ Sí |
| MEDIUM P2 — SELECT * | ✅ Sí |
| MEDIUM P1 — LIMIT faltante | ✅ Sí |
| LOW C1 — aliases `u` y `o` poco descriptivos | ❌ No |

**Bug encontrado:** El test espera `[LOW] C1` para los aliases `u` y `o`, pero el regex de `rules/conventions.md → C1` solo busca nombres como `temp, tmp, data, foo, bar`. Aliases de una letra no están en el patrón, por lo que la regla no dispara. Hay una inconsistencia entre lo que el test documenta como esperado y lo que la regla realmente detecta.

---

### Test 03 — Caso Límite: `AND 1=1` combinado con condición real ❌ FAIL

**Input:**
```sql
DELETE FROM registros 
WHERE fecha_creacion < NOW() - INTERVAL '30 days' 
AND 1=1;
```

**Output real de la skill:**

```
CRITICAL: 0 | HIGH: 0 | MEDIUM: 0 | LOW: 0 | INFO: 0

Evaluación general: No se encontraron problemas significativos.
```

**¿Coincide con lo esperado?** No. El expected pedía:
- `[CRITICAL] S3` — WHERE 1=1 siempre verdadero
- `[HIGH]` — eliminación masiva potencial

**Bug real confirmado:** Los regexes de S2 y S3 solo detectan `WHERE 1=1` cuando es la **única** condición inmediatamente después de `WHERE`:
- S2 regex: `DELETE\s+FROM\s+\w+\s+WHERE\s+1\s*=\s*1`
- S3 regex: `WHERE\s+1\s*=\s*1`

Cuando el `1=1` aparece como `WHERE <condición_real> AND 1=1`, **ninguno de los dos regexes lo captura**. La sentencia pasa completamente sin hallazgos, siendo un DELETE que en la práctica borra todo (la condición de fecha más `AND 1=1` no restringe más que la fecha sola, y el `1=1` es una señal de alarma obvia que se escapa al chequeo).

---

### Test 04 — Información Insuficiente: tabla `???` ✅ PASS

**Input:**
```sql
SELECT * FROM ??? WHERE id = 1;
```

**Output real de la skill:**

```
CRITICAL: 0 | HIGH: 0 | MEDIUM: 2 | LOW: 0 | INFO: 1

[MEDIUM] P2 — SELECT * presente.
         Sugerencia: especificar columnas requeridas.

[MEDIUM] P1 — Sin LIMIT.
         Sugerencia: agregar LIMIT.

[INFO] Validación de entrada — `???` no es un identificador SQL válido en PostgreSQL.
       Sugerencia: proporcionar nombre de tabla correcto y DDL del schema si está disponible.

Evaluación general: SQL incompleto. Análisis parcial disponible. Se requiere nombre de tabla válido.
```

**¿Coincide con lo esperado?** Sí.

| Comportamiento esperado | ¿Cumplido? |
|---|---|
| Reconocer SQL incompleto (`???`) | ✅ |
| Reportar SELECT * como MEDIUM | ✅ |
| Reportar LIMIT faltante como MEDIUM | ✅ |
| Solicitar información adicional | ✅ |
| No inventar nombre de tabla | ✅ |

---

### Test 05 — Entrada Adversarial: `AND 1=1` con condición de email ❌ FAIL

**Input:**
```sql
UPDATE usuarios 
SET password = 'contraseña_hasheada' 
WHERE email = 'admin@ejemplo.com' 
AND 1=1;
```

**Output real de la skill:**

```
CRITICAL: 0 | HIGH: 0 | MEDIUM: 0 | LOW: 0 | INFO: 0

Evaluación general: No se encontraron problemas significativos.
```

**¿Coincide con lo esperado?** No. El expected pedía:
- `[CRITICAL] S3` — `AND 1=1` como bandera roja
- `[HIGH]` — potencial UPDATE masivo

**Bug real confirmado (mismo que Test 03):** El regex de S3 (`WHERE\s+1\s*=\s*1`) no detecta `1=1` cuando aparece después de `AND`. La sentencia adversarial pasa sin ningún hallazgo, lo cual es exactamente el ataque que el test quería detectar: el atacante añade `email = 'admin@ejemplo.com'` para que el `1=1` no sea la única condición y así evadir el chequeo.

---

## Resumen general

| Test | Estado | Hallazgos generados vs. esperados |
|---|---|---|
| 01 — SQL limpio | ✅ PASS | 0 problemas (solo 2 INFO) — correcto |
| 02 — Múltiples violaciones | ⚠️ PASS PARCIAL | 3/4 hallazgos correctos; falta LOW C1 |
| 03 — AND 1=1 con fecha | ❌ FAIL | 0 hallazgos cuando debía ser CRITICAL + HIGH |
| 04 — Tabla ??? | ✅ PASS | Análisis parcial correcto, limitación declarada |
| 05 — AND 1=1 con email | ❌ FAIL | 0 hallazgos cuando debía ser CRITICAL + HIGH |

---

## Bugs encontrados

### Bug 1 — CRÍTICO: S2 y S3 no detectan `AND 1=1` (afecta test-03 y test-05)

**Reglas afectadas:** `rules/security.md` → S2, S3

**Problema:** Los regexes de detección solo capturan `1=1` cuando aparece como condición única e inmediata:
```
WHERE\s+1\s*=\s*1        ← S3
WHERE\s+1\s*=\s*1        ← S2 (solo para DELETE)
```

Cualquier sentencia con `WHERE <algo_real> AND 1=1` evade ambas reglas. El atacante solo necesita añadir una condición legítima antes del `AND 1=1` para que la skill no detecte nada.

**Corrección sugerida:** En lugar de buscar `WHERE 1=1` literalmente, buscar `1\s*=\s*1` en cualquier parte de la cláusula WHERE (como subcadena de la condición completa), o razonar semánticamente sobre si alguna sub-condición es siempre verdadera.

### Bug 2 — MENOR: C1 no cubre aliases de una letra (afecta test-02)

**Regla afectada:** `rules/conventions.md` → C1

**Problema:** El test espera que aliases `u` y `o` disparen `[LOW] C1`, pero el regex de C1:
```
\s+(temp|tmp|data|info|stuff|things|aaa|test|foo|bar)\s+
```
...no incluye aliases de una letra. La regla y el test documentado están desincronizados.

**Corrección sugerida:** Agregar al regex de C1 un patrón para identificadores de 1–2 caracteres que no sean aliases de tabla obvios (como `AS\s+[a-z]{1,2}\s` fuera de contexto de JOIN corto), o actualizar el expected del test para reflejar que aliases cortos en JOIN no se penalizan.

---

## Conclusión

La skill de Oscar tiene una base sólida: detecta correctamente SQL limpio (test-01), inyección SQL clásica (test-02), información insuficiente (test-04), y tiene buena estructura de reglas e IDs. El problema principal es que los regexes de S2 y S3 son demasiado literales — cualquier variante del patrón `1=1` que no aparezca como condición única después de `WHERE` pasa sin ser detectada. Esto es exactamente el tipo de bypass que una fase Red Team está diseñada para encontrar, y los propios tests 03 y 05 de Oscar lo documentan — pero la skill no los pasa aún.

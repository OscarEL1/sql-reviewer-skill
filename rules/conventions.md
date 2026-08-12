# Reglas de Convenciones - PostgreSQL

## C1: Nombres No Descriptivos
**Severidad**: LOW

### Patrón de Detección
```regex
\s+(temp|tmp|data|info|stuff|things|aaa|test|foo|bar)\s+
AS\s+(temp|tmp|data|info|stuff|things)\s*
```

### Excepción Declarada
Los alias de una sola letra en cláusulas JOIN cortas (`FROM usuarios u JOIN pedidos p ON ...`) **no se penalizan**, ya que es una convención ampliamente aceptada en SQL y no reduce la claridad en ese contexto.

### Justificación
- Reduce mantenibilidad del código
- Hace más difícil la depuración
- Otros desarrolladores no pueden entender el propósito

### Sugerencia
Use nombres descriptivos que indiquen propósito y contenido.

### Ejemplo
**Malo**:
```sql
SELECT a, b, c FROM tmp WHERE d = 1;
WITH data AS (SELECT * FROM pedidos) ...
```

**Bueno**:
```sql
SELECT usuario_id, total_pedido, fecha_pedido 
FROM pedidos_recientes 
WHERE estado_pedido = 'pendiente';

WITH pedidos_pendientes AS (SELECT * FROM pedidos WHERE estado = 'pendiente') ...
```

---

## C2: Nomenclatura Inconsistente
**Severidad**: LOW

### Patrón de Detección
```regex
-- Mezcla de snake_case y camelCase
SELECT\s+[a-z]+[A-Z][a-z]+\s+FROM
-- Mezcla de mayúsculas en la misma consulta
SELECT\s+[A-Z_]+\s*,\s*[a-z]+[A-Z]
```

### Justificación
- Reduce legibilidad
- Aumenta carga cognitiva
- Hace más difícil la refactorización

### Sugerencia
Establezca y siga una convención de nomenclatura consistente.

### Convención PostgreSQL
- Use snake_case para tablas, columnas, funciones
- Use minúsculas para palabras clave (opcional, pero consistente)
- Use MAYÚSCULAS para constantes (opcional)

### Ejemplo
**Malo**:
```sql
SELECT nombreUsuario, nombre_usuario, NOMBREUSUARIO FROM Usuarios;
```

**Bueno**:
```sql
SELECT nombre_usuario, direccion_email FROM usuarios;
```

---

## C3: Prefijo de Esquema Faltante
**Severidad**: INFO

### Patrón de Detección
```regex
FROM\s+(?!pg_|information_schema|public\.)[a-z_]+\s
```
(Cuando podrían existir múltiples esquemas)

### Justificación
- Puede causar ambigüedad en bases de datos multi-esquema
- Puede ejecutarse en el esquema equivocado
- Mejor para la explicitud

### Sugerencia
Considere usar prefijo de esquema cuando se necesite claridad.

### Ejemplo
**Malo**:
```sql
SELECT * FROM usuarios;  -- ¿Qué esquema?
```

**Bueno**:
```sql
SELECT * FROM public.usuarios;  -- Explícito
-- O asegúrese de que search_path esté configurado correctamente
```

### Nota
Esto es solo informativo. Muchos proyectos funcionan bien sin esquema explícito.

---

## C4: Valores Codificados
**Severidad**: LOW

### Patrón de Detección
```regex
WHERE\s+\w+\s*=\s*\d{4}-\d{2}-\d{2}
WHERE\s+\w+\s*=\s*'[A-Z_]+'
SET\s+\w+\s*=\s*\d+
```

### Justificación
- Difícil de mantener
- Requiere cambios de código para actualizar valores
- Puede causar errores cuando los valores cambian

### Sugerencia
Use parámetros, constantes o valores de configuración.

### Ejemplo
**Malo**:
```sql
SELECT * FROM usuarios WHERE estado = 'ACTIVO';
UPDATE usuarios SET rol = 1 WHERE id = 42;
```

**Bueno**:
```sql
-- Use parámetros
SELECT * FROM usuarios WHERE estado = $1;

-- O defina constantes
-- En código de aplicación:
const ESTADO_ACTIVO = 'ACTIVO';
```

---

## C5: Comentarios Faltantes
**Severidad**: INFO

### Patrón de Detección
```regex
-- Consultas complejas (>10 líneas) sin comentarios
-- Consultas de lógica de negocio sin explicación
-- Condiciones de JOIN no obvias
```

### Justificación
- Difícil para otros entender
- Difícil de mantener a largo plazo
- La lógica de negocio se pierde

### Sugerencia
Agregue comentarios para lógica compleja y reglas de negocio.

### Ejemplo
**Malo**:
```sql
SELECT u.id, o.total, p.nombre
FROM usuarios u
JOIN pedidos o ON u.id = o.usuario_id
JOIN productos p ON o.producto_id = p.id
WHERE u.fecha_creacion > '2024-01-01'
AND o.estado != 'cancelado'
AND p.categoría IN (1, 2, 3);
```

**Bueno**:
```sql
-- Obtener usuarios activos con sus pedidos recientes e información de producto
-- Solo para usuarios registrados en 2024+
-- Excluyendo pedidos cancelados
-- Solo para categorías principales de producto (1, 2, 3)
SELECT u.id, o.total, p.nombre
FROM usuarios u
JOIN pedidos o ON u.id = o.usuario_id
JOIN productos p ON o.producto_id = p.id
WHERE u.fecha_creacion > '2024-01-01'
AND o.estado != 'cancelado'
AND p.categoría IN (1, 2, 3);
```

---

## C6: Sintaxis Obsoleta
**Severidad**: MEDIUM

### Patrón de Detección
```regex
-- Sintaxis antigua de JOIN (ANSI-89)
FROM\s+\w+\s*,\s*\w+\s+WHERE\s+\w+\.\w+\s*=\s*\w+\.\w+
-- Concatenación antigua de cadenas
SELECT\s+.*\s*\|\|.*\s+FROM
-- Funciones obsoletas
NOW\(\)|CURRENT_TIMESTAMP
```

### Justificación
- Puede eliminarse en versiones futuras
- Menos legible que la sintaxis moderna
- Faltan características de la sintaxis moderna

### Sugerencia
Use la sintaxis actual de PostgreSQL.

### Ejemplo
**Malo**:
```sql
-- JOIN implícito antiguo
SELECT * FROM usuarios, pedidos WHERE usuarios.id = pedidos.usuario_id;

-- Concatenación antigua de cadenas (aunque || sigue siendo válido)
SELECT nombre || ' ' || apellido FROM usuarios;
```

**Bueno**:
```sql
-- JOIN explícito
SELECT * FROM usuarios JOIN pedidos ON usuarios.id = pedidos.usuario_id;

-- Función CONCAT (más clara la intención)
SELECT CONCAT(nombre, ' ', apellido) FROM usuarios;
```

---

## Guía de Estilo Recomendada

### Indentación
```sql
-- Use indentación consistente (2 o 4 espacios)
SELECT
    columna1,
    columna2
FROM tabla1
WHERE condición;
```

### Saltos de Línea
```sql
-- Una condición por línea para mayor legibilidad
SELECT *
FROM usuarios
WHERE estado = 'activo'
    AND fecha_creacion > '2024-01-01'
    AND email IS NOT NULL;
```

### Capitalización
```sql
-- Palabras clave en mayúsculas (opcional pero común)
SELECT * FROM usuarios WHERE id = 1;

-- O todo en minúsculas (también válido)
select * from usuarios where id = 1;

-- Solo sea consistente
```

## Reglas Específicas del Proyecto

### Cuándo Agregar Reglas Personalizadas
```
SI proyecto_tiene_guía_de_estilo
ENTONCES agregar reglas a conventions.md
Y asegurar que no entren en conflicto con reglas base

SI equipo_tiene_preferencias
ENTONCES documentar en README.md
Y referenciar en conventions.md
```

### Ejemplo de Reglas Personalizadas
```markdown
## Reglas Personalizadas

### C7: Nomenclatura de Tablas
- Todas las tablas deben ser plurales (usuarios, pedidos, no usuario, pedido)
- Prefijo con nombre del módulo si es modular (usuarios_auth, pedidos_pago)

### C8: Nomenclatura de Columnas
- Claves primarias: id (no usuario_id, ni id_usuario)
- Claves foráneas: tabla_id (usuario_id, no usuarioid)
- Columnas booleanas: es_activo, tiene_permiso (no activo, permiso)
```

## Resolución de Conflictos

### Convenciones vs Rendimiento
```
SI convención_nomenclatura_conflicta_con_rendimiento
ENTONCES rendimiento tiene precedencia
Y documentar excepción
```

### Múltiples Problemas de Convenciones
```
SI C1 (nomenclatura) Y C2 (consistencia) ambos aplican
ENTONCES reportar ambos como severidad LOW
Y sugerir abordar nomenclatura primero
```

## Validación

### Antes de Reportar Problema de Convención
```
1. Verificar que realmente es un problema de convención (no preferencia personal)
2. Verificar si el proyecto tiene convenciones existentes
3. Considerar si la sugerencia vale el esfuerzo de refactorización
4. Reportar como INFO si es menor
```

## Consideraciones Culturales

### Equipos Internacionales
```
SI equipo_es_internacional
ENTONCES evitar idiomas en nomenclatura
Y usar nombres claros, simples
Y documentar cualquier suposición cultural
```

### Código Heredado
```
SI convenciones_código_heredado_existen
ENTONCES documentar convenciones actuales
Y sugerir migración gradual
Y no forzar nuevas convenciones en código antiguo
```

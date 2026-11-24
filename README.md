# Actividad 2 — Índices y restricciones en Oracle

**Asignatura:** Bases de Datos Avanzadas  
**Autor:** Maykol Alejandro Riveros Navarrete  
**Entorno:** Oracle Database 21c Express Edition (local) · SQL Developer · SQL*Plus · esquema HR en la PDB `XEPDB1`, usuario `hr`.  
**Alternativa:** en Oracle FreeSQL, ejecutar antes `sql/00b_preparar_hr_freesql.sql` (réplica de HR en el esquema propio).

## Estructura

| Script | Conexión | Contenido |
|---|---|---|
| `sql/00b_preparar_hr_freesql.sql` | esquema propio (FreeSQL) | Réplica de JOBS, LOCATIONS, DEPARTMENTS, EMPLOYEES y JOB_HISTORY con los mismos nombres de restricciones e índices de HR |
| `sql/00_verificacion_entorno.sql` | hr | Usuario, contenedor, tablas y disparadores de HR |
| `sql/01_consulta_indices.sql` | hr | Índices de EMPLOYEES y DEPARTMENTS, relación con PK/UK y plan de ejecución |
| `sql/02_desactivar_restricciones.sql` | hr | Listado y desactivación de todas las restricciones (FK → CHECK → UK → PK CASCADE) |
| `sql/03_insertar_tuplas_invalidas.sql` | hr | Inserciones que violan NOT NULL, CHECK, FK, UNIQUE y PK |
| `sql/04_reactivar_restricciones.sql` | hr | Reactivación con `EXCEPTIONS INTO`, corrección de datos y reactivación final |
| `sql/05_departments2_sesion.sql` | hr | `DEPARTMENTS2` por CTAS, tres inserciones, cierre de sesión y consulta |
| `sql/06_bloque_anonimo_transaccion.sql` | hr | Bloque anónimo con inicio/fin de transacción (COMMIT y ROLLBACK) |
| `sql/07_deshacer_transaccion.sql` | hr | `ROLLBACK`, `SAVEPOINT` / `ROLLBACK TO` y commit implícito por DDL |
| `sql/08_redo_logs.sql` | `/ as sysdba` | `V$LOG`, `V$LOGFILE`, `LOG_MODE`, log switch y medición de *redo size* |

## Orden de ejecución

Ejecutar los scripts en orden numérico. Los scripts 00–04 y 06 se pueden lanzar completos con **F5 (Ejecutar script)**; los scripts 05 y 07 están pensados para ejecutarse **sentencia a sentencia (Ctrl+Enter)** porque incluyen pasos manuales (cerrar sesión, reconectar). El script 08 se ejecuta en SQL*Plus como SYSDBA.

## Notas

- Las tablas del esquema HR no se modifican de forma permanente: las filas de prueba se eliminan en el script 04 y todas las restricciones quedan `ENABLED / VALIDATED`.
- `DEPARTMENTS2` queda creada como resultado de la actividad. Para eliminarla: `DROP TABLE departments2 PURGE;`
- En SQL Developer se antepuso `SET SQLFORMAT ansiconsole` a cada script para mostrar los resultados en forma de tabla.
- En FreeSQL cada ejecución de la hoja de trabajo abre una sesión nueva y confirma lo pendiente al terminar; por eso el script 05 se observó ejecución a ejecución y el script 07 se ejecuta completo en una sola ejecución.
- Las vistas `V$` del script 08 requieren privilegios de administrador y no están disponibles en FreeSQL (ORA-00942).

/* =============================================================================
   Script   : 08_redo_logs.sql
   Conexión : SQL*Plus como SYSDBA ->  sqlplus / as sysdba
              (las vistas V$ y ALTER SYSTEM requieren privilegios de administrador;
              el usuario HR no tiene acceso a ellas)
   Objetivo : Observar los ficheros de redo, el modo de archivado de la base de
              datos y cómo una operación DML genera redo.
   ============================================================================= */

-- 1. Modo de funcionamiento: ARCHIVELOG o NOARCHIVELOG
SELECT name, log_mode FROM v$database;
ARCHIVE LOG LIST

-- 2. Grupos de redo online: secuencia, tamaño, miembros y estado
--    CURRENT = grupo en el que escribe LGWR; ACTIVE = aún necesario para
--    recuperación de instancia; INACTIVE = reutilizable.
COLUMN member FORMAT A60
SELECT group#, sequence#, bytes/1024/1024 AS mb, members, archived, status
FROM   v$log
ORDER  BY group#;

-- 3. Ficheros físicos de cada grupo
SELECT group#, member FROM v$logfile ORDER BY group#;

-- 4. Cambio de log forzado (log switch): LGWR pasa al siguiente grupo y la
--    secuencia aumenta. Se ejecuta en el contenedor raíz (CDB$ROOT).
ALTER SYSTEM SWITCH LOGFILE;
SELECT group#, sequence#, archived, status FROM v$log ORDER BY group#;

SELECT sequence#, TO_CHAR(first_time, 'YYYY-MM-DD HH24:MI:SS') AS inicio
FROM   v$log_history
ORDER  BY sequence# DESC
FETCH FIRST 5 ROWS ONLY;

-- 5. Redo generado por una transacción: se mide la estadística "redo size" de
--    la propia sesión antes y después de un UPDATE sobre HR.DEPARTMENTS2.
ALTER SESSION SET CONTAINER = XEPDB1;

SELECT n.name, m.value AS bytes_redo
FROM   v$mystat m JOIN v$statname n ON n.statistic# = m.statistic#
WHERE  n.name = 'redo size';

UPDATE hr.departments2 SET department_name = department_name;
COMMIT;

SELECT n.name, m.value AS bytes_redo
FROM   v$mystat m JOIN v$statname n ON n.statistic# = m.statistic#
WHERE  n.name = 'redo size';

/* 6. Referencia (NO ejecutado): paso a modo ARCHIVELOG. Requiere reiniciar la
      instancia, por eso solo se documenta.
   SHUTDOWN IMMEDIATE
   STARTUP MOUNT
   ALTER DATABASE ARCHIVELOG;
   ALTER DATABASE OPEN;
   ARCHIVE LOG LIST
*/

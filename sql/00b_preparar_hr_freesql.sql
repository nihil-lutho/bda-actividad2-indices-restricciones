/* =============================================================================
   Script   : 00b_preparar_hr_freesql.sql
   Entorno  : Oracle FreeSQL (sesión iniciada con cuenta de Oracle)
   Objetivo : En FreeSQL el esquema HR es de solo lectura, por lo que no se
              pueden desactivar sus restricciones. Este script crea en el
              esquema propio una réplica de JOBS, LOCATIONS, DEPARTMENTS,
              EMPLOYEES y JOB_HISTORY con los MISMOS nombres de restricciones
              e índices que el script oficial de instalación de HR
              (oracle-samples/db-sample-schemas), incluido el detalle de crear
              los índices de las PK con CREATE UNIQUE INDEX antes de la PK.
   Nota     : No es necesario en una instalación local con el usuario hr.
   ============================================================================= */

-- Tablas de apoyo referenciadas por las claves foráneas
CREATE TABLE jobs AS SELECT * FROM hr.jobs;
ALTER TABLE jobs ADD CONSTRAINT job_id_pk PRIMARY KEY (job_id);

CREATE TABLE locations AS SELECT * FROM hr.locations;
ALTER TABLE locations ADD CONSTRAINT loc_id_pk PRIMARY KEY (location_id);

-- DEPARTMENTS
CREATE TABLE departments (
  department_id   NUMBER(4),
  department_name VARCHAR2(30) CONSTRAINT dept_name_nn NOT NULL,
  manager_id      NUMBER(6),
  location_id     NUMBER(4)
);
CREATE UNIQUE INDEX dept_id_pk ON departments (department_id);
ALTER TABLE departments ADD (
  CONSTRAINT dept_id_pk  PRIMARY KEY (department_id),
  CONSTRAINT dept_loc_fk FOREIGN KEY (location_id) REFERENCES locations (location_id)
);

-- EMPLOYEES
CREATE TABLE employees (
  employee_id    NUMBER(6),
  first_name     VARCHAR2(20),
  last_name      VARCHAR2(25) CONSTRAINT emp_last_name_nn NOT NULL,
  email          VARCHAR2(25) CONSTRAINT emp_email_nn NOT NULL,
  phone_number   VARCHAR2(20),
  hire_date      DATE         CONSTRAINT emp_hire_date_nn NOT NULL,
  job_id         VARCHAR2(10) CONSTRAINT emp_job_nn NOT NULL,
  salary         NUMBER(8,2),
  commission_pct NUMBER(2,2),
  manager_id     NUMBER(6),
  department_id  NUMBER(4),
  CONSTRAINT emp_salary_min CHECK (salary > 0),
  CONSTRAINT emp_email_uk   UNIQUE (email)
);
CREATE UNIQUE INDEX emp_emp_id_pk ON employees (employee_id);
ALTER TABLE employees ADD (
  CONSTRAINT emp_emp_id_pk  PRIMARY KEY (employee_id),
  CONSTRAINT emp_dept_fk    FOREIGN KEY (department_id) REFERENCES departments,
  CONSTRAINT emp_job_fk     FOREIGN KEY (job_id) REFERENCES jobs (job_id),
  CONSTRAINT emp_manager_fk FOREIGN KEY (manager_id) REFERENCES employees
);

-- Datos (los departamentos primero; luego empleados)
INSERT INTO departments (department_id, department_name, manager_id, location_id)
SELECT department_id, department_name, manager_id, location_id FROM hr.departments;

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number,
                       hire_date, job_id, salary, commission_pct, manager_id, department_id)
SELECT employee_id, first_name, last_name, email, phone_number,
       hire_date, job_id, salary, commission_pct, manager_id, department_id
FROM   hr.employees;

ALTER TABLE departments ADD CONSTRAINT dept_mgr_fk
  FOREIGN KEY (manager_id) REFERENCES employees (employee_id);

-- JOB_HISTORY (depende de las PK de EMPLOYEES y DEPARTMENTS)
CREATE TABLE job_history (
  employee_id   NUMBER(6)    CONSTRAINT jhist_employee_nn NOT NULL,
  start_date    DATE         CONSTRAINT jhist_start_date_nn NOT NULL,
  end_date      DATE         CONSTRAINT jhist_end_date_nn NOT NULL,
  job_id        VARCHAR2(10) CONSTRAINT jhist_job_nn NOT NULL,
  department_id NUMBER(4),
  CONSTRAINT jhist_date_interval CHECK (end_date > start_date)
);
CREATE UNIQUE INDEX jhist_emp_id_st_date_pk ON job_history (employee_id, start_date);
ALTER TABLE job_history ADD (
  CONSTRAINT jhist_emp_id_st_date_pk PRIMARY KEY (employee_id, start_date),
  CONSTRAINT jhist_job_fk  FOREIGN KEY (job_id) REFERENCES jobs,
  CONSTRAINT jhist_emp_fk  FOREIGN KEY (employee_id) REFERENCES employees,
  CONSTRAINT jhist_dept_fk FOREIGN KEY (department_id) REFERENCES departments
);
INSERT INTO job_history SELECT employee_id, start_date, end_date, job_id, department_id
FROM hr.job_history;

-- Índices secundarios del esquema HR
CREATE INDEX emp_department_ix ON employees (department_id);
CREATE INDEX emp_job_ix        ON employees (job_id);
CREATE INDEX emp_manager_ix    ON employees (manager_id);
CREATE INDEX emp_name_ix       ON employees (last_name, first_name);
CREATE INDEX dept_location_ix  ON departments (location_id);

COMMIT;

-- Estadísticas para que el optimizador conozca las tablas
BEGIN
  DBMS_STATS.GATHER_SCHEMA_STATS(USER);
END;
/

SELECT table_name, num_rows FROM user_tables ORDER BY table_name;

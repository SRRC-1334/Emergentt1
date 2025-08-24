/* REXX - DB2CRUD Utility Functions - Enhanced Version */
/* Supporting utility functions with comprehensive features */

/* Build INSERT SQL statement */
BUILD_INSERT_SQL: PROCEDURE EXPOSE COL_INFO. COL_COUNT SQL_STMT SCHEMA TABLENAME
   SQL_STMT = "INSERT INTO " || SCHEMA || "." || TABLENAME || " ("
   VALUES_CLAUSE = " VALUES ("
   
   FIRST_COL = 1
   VALUE_COUNT = 0
   
   DO I = 1 TO COL_COUNT
      ISPF_NAME = COL_INFO.I.ISPF_NAME
      ADDRESS ISPEXEC "VGET" ISPF_NAME
      COL_VALUE = VALUE(ISPF_NAME)
      
      IF COL_VALUE <> "" THEN DO
         IF FIRST_COL = 0 THEN DO
            SQL_STMT = SQL_STMT || ", "
            VALUES_CLAUSE = VALUES_CLAUSE || ", "
         END
         
         SQL_STMT = SQL_STMT || COL_INFO.I.NAME
         
         /* Format value based on data type */
         FORMATTED_VALUE = FORMAT_DB2_VALUE(COL_VALUE, COL_INFO.I.TYPE, COL_INFO.I.LENGTH)
         VALUES_CLAUSE = VALUES_CLAUSE || FORMATTED_VALUE
         
         FIRST_COL = 0
         VALUE_COUNT = VALUE_COUNT + 1
      END
   END
   
   IF VALUE_COUNT = 0 THEN DO
      SQL_STMT = "-- ERROR: No values provided for INSERT"
      RETURN 12
   END
   
   SQL_STMT = SQL_STMT || ")" || VALUES_CLAUSE || ")"
   
RETURN 0

/* Build SELECT SQL statement with WHERE conditions */
BUILD_SELECT_SQL: PROCEDURE EXPOSE COL_INFO. COL_COUNT SQL_STMT SCHEMA TABLENAME MAX_ROWS
   SQL_STMT = "SELECT * FROM " || SCHEMA || "." || TABLENAME
   
   WHERE_CLAUSE = BUILD_WHERE_CLAUSE()
   IF WHERE_CLAUSE <> "" THEN
      SQL_STMT = SQL_STMT || WHERE_CLAUSE
   
   /* Add row limit */
   SQL_STMT = SQL_STMT || " FETCH FIRST " || MAX_ROWS || " ROWS ONLY"
   
RETURN 0

/* Build UPDATE SQL statement */
BUILD_UPDATE_SQL: PROCEDURE EXPOSE COL_INFO. COL_COUNT SQL_STMT SCHEMA TABLENAME
   SQL_STMT = "UPDATE " || SCHEMA || "." || TABLENAME || " SET "
   
   /* Build SET clause from update values */
   SET_CLAUSE = ""
   FIRST_SET = 1
   
   DO I = 1 TO COL_COUNT
      ISPF_NAME = COL_INFO.I.ISPF_NAME || "_UPD"  /* Update value fields */
      ADDRESS ISPEXEC "VGET" ISPF_NAME
      COL_VALUE = VALUE(ISPF_NAME)
      
      IF COL_VALUE <> "" THEN DO
         IF FIRST_SET = 0 THEN
            SET_CLAUSE = SET_CLAUSE || ", "
         
         FORMATTED_VALUE = FORMAT_DB2_VALUE(COL_VALUE, COL_INFO.I.TYPE, COL_INFO.I.LENGTH)
         SET_CLAUSE = SET_CLAUSE || COL_INFO.I.NAME || " = " || FORMATTED_VALUE
         FIRST_SET = 0
      END
   END
   
   IF SET_CLAUSE = "" THEN DO
      SQL_STMT = "-- ERROR: No update values provided"
      RETURN 12
   END
   
   SQL_STMT = SQL_STMT || SET_CLAUSE
   
   /* Add WHERE clause */
   WHERE_CLAUSE = BUILD_WHERE_CLAUSE()
   IF WHERE_CLAUSE <> "" THEN
      SQL_STMT = SQL_STMT || WHERE_CLAUSE
   ELSE DO
      SQL_STMT = "-- ERROR: WHERE clause required for UPDATE"
      RETURN 12
   END
   
RETURN 0

/* Build DELETE SQL statement */
BUILD_DELETE_SQL: PROCEDURE EXPOSE COL_INFO. COL_COUNT SQL_STMT SCHEMA TABLENAME
   SQL_STMT = "DELETE FROM " || SCHEMA || "." || TABLENAME
   
   WHERE_CLAUSE = BUILD_WHERE_CLAUSE()
   IF WHERE_CLAUSE <> "" THEN
      SQL_STMT = SQL_STMT || WHERE_CLAUSE
   ELSE DO
      SQL_STMT = "-- ERROR: WHERE clause required for DELETE"
      RETURN 12
   END
   
RETURN 0

/* Build WHERE clause from selected conditions */
BUILD_WHERE_CLAUSE: PROCEDURE EXPOSE COL_INFO. COL_COUNT
   WHERE_CLAUSE = ""
   CONDITION_COUNT = 0
   
   DO I = 1 TO COL_COUNT
      /* Check if this column was selected for WHERE condition */
      SEL_VAR = "SEL" || I
      ADDRESS ISPEXEC "VGET" SEL_VAR
      SELECTION = VALUE(SEL_VAR)
      
      IF SELECTION = "S" THEN DO
         VALUE_VAR = COL_INFO.I.ISPF_NAME
         OPER_VAR = "OPER" || I
         LOGIC_VAR = "LOGIC" || I
         
         ADDRESS ISPEXEC "VGET" VALUE_VAR OPER_VAR LOGIC_VAR
         COL_VALUE = VALUE(VALUE_VAR)
         OPERATOR = VALUE(OPER_VAR)
         LOGIC_OP = VALUE(LOGIC_VAR)
         
         IF COL_VALUE <> "" & OPERATOR <> "" THEN DO
            IF CONDITION_COUNT = 0 THEN
               WHERE_CLAUSE = " WHERE "
            ELSE IF LOGIC_OP <> "" THEN
               WHERE_CLAUSE = WHERE_CLAUSE || " " || LOGIC_OP || " "
            ELSE
               WHERE_CLAUSE = WHERE_CLAUSE || " AND "
            
            /* Handle different operators */
            SELECT
               WHEN OPERATOR = "BETWEEN" THEN DO
                  /* Expect two values separated by comma */
                  PARSE VAR COL_VALUE VAL1 "," VAL2
                  FORM_VAL1 = FORMAT_DB2_VALUE(VAL1, COL_INFO.I.TYPE, COL_INFO.I.LENGTH)
                  FORM_VAL2 = FORMAT_DB2_VALUE(VAL2, COL_INFO.I.TYPE, COL_INFO.I.LENGTH)
                  WHERE_CLAUSE = WHERE_CLAUSE || COL_INFO.I.NAME || " BETWEEN " || FORM_VAL1 || " AND " || FORM_VAL2
               END
               WHEN OPERATOR = "IN" THEN DO
                  /* Expect comma-separated values */
                  IN_VALUES = ""
                  VALUE_LIST = COL_VALUE
                  DO WHILE POS(",", VALUE_LIST) > 0
                     PARSE VAR VALUE_LIST NEXT_VAL "," VALUE_LIST
                     IF IN_VALUES <> "" THEN IN_VALUES = IN_VALUES || ", "
                     IN_VALUES = IN_VALUES || FORMAT_DB2_VALUE(NEXT_VAL, COL_INFO.I.TYPE, COL_INFO.I.LENGTH)
                  END
                  IF VALUE_LIST <> "" THEN DO
                     IF IN_VALUES <> "" THEN IN_VALUES = IN_VALUES || ", "
                     IN_VALUES = IN_VALUES || FORMAT_DB2_VALUE(VALUE_LIST, COL_INFO.I.TYPE, COL_INFO.I.LENGTH)
                  END
                  WHERE_CLAUSE = WHERE_CLAUSE || COL_INFO.I.NAME || " IN (" || IN_VALUES || ")"
               END
               WHEN OPERATOR = "IS NULL" | OPERATOR = "IS NOT NULL" THEN DO
                  WHERE_CLAUSE = WHERE_CLAUSE || COL_INFO.I.NAME || " " || OPERATOR
               END
               OTHERWISE DO
                  FORMATTED_VALUE = FORMAT_DB2_VALUE(COL_VALUE, COL_INFO.I.TYPE, COL_INFO.I.LENGTH)
                  WHERE_CLAUSE = WHERE_CLAUSE || COL_INFO.I.NAME || " " || OPERATOR || " " || FORMATTED_VALUE
               END
            END
            
            CONDITION_COUNT = CONDITION_COUNT + 1
         END
      END
   END
   
RETURN WHERE_CLAUSE

/* Format value according to DB2 data type */
FORMAT_DB2_VALUE: PROCEDURE
   PARSE ARG VALUE, DATATYPE, LENGTH
   
   /* Handle NULL values */
   IF UPPER(VALUE) = "NULL" | VALUE = "" THEN
      RETURN "NULL"
   
   /* Format based on data type */
   SELECT
      WHEN DATATYPE = "CHAR" | DATATYPE = "VARCHAR" | DATATYPE = "GRAPHIC" | DATATYPE = "VARGRAPHIC" THEN DO
         /* String values - escape single quotes */
         ESCAPED_VALUE = TRANSLATE(VALUE, "''", "'")
         FORMATTED = "'" || ESCAPED_VALUE || "'"
      END
      WHEN DATATYPE = "INTEGER" | DATATYPE = "SMALLINT" | DATATYPE = "BIGINT" THEN DO
         /* Integer values - validate numeric */
         IF DATATYPE(VALUE, 'W') THEN
            FORMATTED = VALUE
         ELSE
            FORMATTED = "NULL"  /* Invalid numeric becomes NULL */
      END
      WHEN DATATYPE = "DECIMAL" | DATATYPE = "NUMERIC" | DATATYPE = "DECFLOAT" THEN DO
         /* Decimal values - validate numeric */
         IF DATATYPE(VALUE, 'N') THEN
            FORMATTED = VALUE
         ELSE
            FORMATTED = "NULL"
      END
      WHEN DATATYPE = "REAL" | DATATYPE = "DOUBLE" | DATATYPE = "FLOAT" THEN DO
         /* Floating point values */
         IF DATATYPE(VALUE, 'N') THEN
            FORMATTED = VALUE
         ELSE
            FORMATTED = "NULL"
      END
      WHEN DATATYPE = "DATE" THEN DO
         /* Date values - validate format */
         IF VALIDATE_DATE(VALUE) THEN
            FORMATTED = "DATE('" || VALUE || "')"
         ELSE
            FORMATTED = "NULL"
      END
      WHEN DATATYPE = "TIME" THEN DO
         /* Time values - validate format */
         IF VALIDATE_TIME(VALUE) THEN
            FORMATTED = "TIME('" || VALUE || "')"
         ELSE
            FORMATTED = "NULL"
      END
      WHEN DATATYPE = "TIMESTAMP" | DATATYPE = "TIMESTMP" THEN DO
         /* Timestamp values - validate format */
         IF VALIDATE_TIMESTAMP(VALUE) THEN
            FORMATTED = "TIMESTAMP('" || VALUE || "')"
         ELSE
            FORMATTED = "NULL"
      END
      OTHERWISE DO
         /* Default to string for unknown types */
         ESCAPED_VALUE = TRANSLATE(VALUE, "''", "'")
         FORMATTED = "'" || ESCAPED_VALUE || "'"
      END
   END
   
RETURN FORMATTED

/* Validate date format (YYYY-MM-DD) */
VALIDATE_DATE: PROCEDURE
   PARSE ARG DATE_VALUE
   
   IF LENGTH(DATE_VALUE) <> 10 THEN RETURN 0
   IF SUBSTR(DATE_VALUE, 5, 1) <> "-" THEN RETURN 0
   IF SUBSTR(DATE_VALUE, 8, 1) <> "-" THEN RETURN 0
   
   YEAR = SUBSTR(DATE_VALUE, 1, 4)
   MONTH = SUBSTR(DATE_VALUE, 6, 2)
   DAY = SUBSTR(DATE_VALUE, 9, 2)
   
   IF \DATATYPE(YEAR, 'W') | \DATATYPE(MONTH, 'W') | \DATATYPE(DAY, 'W') THEN RETURN 0
   IF MONTH < 1 | MONTH > 12 THEN RETURN 0
   IF DAY < 1 | DAY > 31 THEN RETURN 0
   
RETURN 1

/* Validate time format (HH:MM:SS) */
VALIDATE_TIME: PROCEDURE
   PARSE ARG TIME_VALUE
   
   IF LENGTH(TIME_VALUE) < 8 THEN RETURN 0
   IF SUBSTR(TIME_VALUE, 3, 1) <> ":" THEN RETURN 0
   IF SUBSTR(TIME_VALUE, 6, 1) <> ":" THEN RETURN 0
   
   HOUR = SUBSTR(TIME_VALUE, 1, 2)
   MINUTE = SUBSTR(TIME_VALUE, 4, 2)
   SECOND = SUBSTR(TIME_VALUE, 7, 2)
   
   IF \DATATYPE(HOUR, 'W') | \DATATYPE(MINUTE, 'W') | \DATATYPE(SECOND, 'W') THEN RETURN 0
   IF HOUR < 0 | HOUR > 23 THEN RETURN 0
   IF MINUTE < 0 | MINUTE > 59 THEN RETURN 0
   IF SECOND < 0 | SECOND > 59 THEN RETURN 0
   
RETURN 1

/* Validate timestamp format (YYYY-MM-DD-HH.MM.SS.mmmmmm) */
VALIDATE_TIMESTAMP: PROCEDURE
   PARSE ARG TS_VALUE
   
   IF LENGTH(TS_VALUE) < 19 THEN RETURN 0
   
   DATE_PART = SUBSTR(TS_VALUE, 1, 10)
   IF SUBSTR(TS_VALUE, 11, 1) <> "-" THEN RETURN 0
   TIME_PART = SUBSTR(TS_VALUE, 12, 8)
   
   /* Replace dots with colons for time validation */
   TIME_PART = TRANSLATE(TIME_PART, ":", ".")
   
   IF \VALIDATE_DATE(DATE_PART) THEN RETURN 0
   IF \VALIDATE_TIME(TIME_PART) THEN RETURN 0
   
RETURN 1

/* Count rows for SELECT preview */
COUNT_SELECT_ROWS: PROCEDURE EXPOSE COL_INFO. COL_COUNT AFFECTED_ROWS SCHEMA TABLENAME
   COUNT_SQL = "SELECT COUNT(*) FROM " || SCHEMA || "." || TABLENAME
   
   WHERE_CLAUSE = BUILD_WHERE_CLAUSE()
   IF WHERE_CLAUSE <> "" THEN
      COUNT_SQL = COUNT_SQL || WHERE_CLAUSE
   
   ADDRESS DSNREXX
   "EXECSQL" COUNT_SQL "INTO :ROW_COUNT"
   
   IF SQLCODE = 0 THEN
      AFFECTED_ROWS = ROW_COUNT
   ELSE
      AFFECTED_ROWS = "Unknown"
   
   ADDRESS ISPEXEC
RETURN

/* Count affected rows for UPDATE/DELETE preview */
COUNT_AFFECTED_ROWS: PROCEDURE EXPOSE COL_INFO. COL_COUNT AFFECTED_ROWS SCHEMA TABLENAME
   COUNT_SQL = "SELECT COUNT(*) FROM " || SCHEMA || "." || TABLENAME
   
   WHERE_CLAUSE = BUILD_WHERE_CLAUSE()
   IF WHERE_CLAUSE <> "" THEN
      COUNT_SQL = COUNT_SQL || WHERE_CLAUSE
   ELSE DO
      AFFECTED_ROWS = "All rows (no WHERE clause)"
      RETURN
   END
   
   ADDRESS DSNREXX
   "EXECSQL" COUNT_SQL "INTO :ROW_COUNT"
   
   IF SQLCODE = 0 THEN
      AFFECTED_ROWS = ROW_COUNT
   ELSE
      AFFECTED_ROWS = "Unknown"
   
   ADDRESS ISPEXEC
RETURN

/* Prefill default values based on data type */
PREFILL_DEFAULT_VALUES: PROCEDURE EXPOSE COL_INFO. COL_COUNT
   CURRENT_DATE = DATE('I')  /* YYYY-MM-DD format */
   CURRENT_TIMESTAMP = DATE('I') || "-" || TRANSLATE(TIME('L'), ".", ":")
   
   DO I = 1 TO COL_COUNT
      ISPF_NAME = COL_INFO.I.ISPF_NAME
      DATATYPE = COL_INFO.I.TYPE
      
      SELECT
         WHEN DATATYPE = "DATE" THEN DO
            ADDRESS ISPEXEC "VPUT" ISPF_NAME
            CALL VALUE ISPF_NAME, CURRENT_DATE
         END
         WHEN DATATYPE = "TIMESTAMP" | DATATYPE = "TIMESTMP" THEN DO
            /* Add microseconds for full timestamp */
            FULL_TIMESTAMP = CURRENT_TIMESTAMP || ".000000"
            ADDRESS ISPEXEC "VPUT" ISPF_NAME
            CALL VALUE ISPF_NAME, FULL_TIMESTAMP
         END
         OTHERWISE NOP
      END
   END
   
   ADDRESS ISPEXEC
RETURN

/* Create dynamic CREATE panel */
CREATE_DYNAMIC_CREATE_PANEL: PROCEDURE EXPOSE COL_INFO. COL_COUNT INDEX_COLS. SCHEMA TABLENAME DB2SSID
   /* Create table for panel display */
   ADDRESS ISPEXEC
   "TBCREATE CREATETBL NAMES(COL_NAME COL_TYPE LEN NULLS COL_VALUE) NOWRITE REPLACE"
   
   DO I = 1 TO COL_COUNT
      COL_NAME = COL_INFO.I.NAME
      COL_TYPE = COL_INFO.I.TYPE
      LEN = COL_INFO.I.LENGTH
      NULLS = COL_INFO.I.NULLS
      COL_VALUE = ""
      
      /* Highlight index columns */
      IF INDEX_COLS.COL_NAME <> "" THEN
         COL_NAME = "%" || COL_NAME  /* Use highlighting attribute */
      
      /* Prefill default values */
      SELECT
         WHEN COL_TYPE = "DATE" THEN COL_VALUE = DATE('I')
         WHEN COL_TYPE = "TIMESTAMP" THEN COL_VALUE = DATE('I') || "-" || TRANSLATE(TIME('L'), ".", ":") || ".000000"
         OTHERWISE COL_VALUE = ""
      END
      
      "TBADD CREATETBL"
   END
   
   "TBTOP CREATETBL"
RETURN

/* Create dynamic WHERE panel */
CREATE_DYNAMIC_WHERE_PANEL: PROCEDURE EXPOSE COL_INFO. COL_COUNT INDEX_COLS. SCHEMA TABLENAME DB2SSID CRUD_OP
   /* Create table for WHERE condition panel */
   ADDRESS ISPEXEC
   "TBCREATE WHERETBL NAMES(SEL COL_NAME COL_TYPE LEN NULLS COL_VALUE OPERATOR LOGIC) NOWRITE REPLACE"
   
   DO I = 1 TO COL_COUNT
      SEL = ""
      COL_NAME = COL_INFO.I.NAME
      COL_TYPE = COL_INFO.I.TYPE
      LEN = COL_INFO.I.LENGTH
      NULLS = COL_INFO.I.NULLS
      COL_VALUE = ""
      OPERATOR = ""
      LOGIC = ""
      
      /* Highlight index columns */
      IF INDEX_COLS.COL_NAME <> "" THEN
         COL_NAME = "%" || COL_NAME  /* Use highlighting attribute */
      
      "TBADD WHERETBL"
   END
   
   "TBTOP WHERETBL"
RETURN

/* Create query history table */
CREATE_HISTORY_TABLE: PROCEDURE EXPOSE DB2SSID USERQRY_DSN
   ADDRESS ISPEXEC
   "TBCREATE HISTTBL NAMES(SEL MEMBER CRUD_OP DATE TIME SCHEMA_TABLE) NOWRITE REPLACE"
   
   /* List members from USERQRY dataset */
   ADDRESS TSO "LISTDS '" || USERQRY_DSN || "' MEMBERS"
   
   /* This would be enhanced to actually read member list and populate table */
   /* For now, showing structure */
   
   "TBTOP HISTTBL"
RETURN

/* Export SELECT results to CSV */
EXPORT_TO_CSV: PROCEDURE EXPOSE EXPORT_DELIM SCHEMA TABLENAME
   EXPORT_DSN = "USER.DB2CRUD.EXPORT.D" || RIGHT(DATE('S'), 6)
   
   /* This would implement actual CSV export logic */
   /* Reading result set cursor and formatting as CSV */
   
RETURN EXPORT_DSN

/* Send email with export attachment */
SEND_EMAIL_EXPORT: PROCEDURE
   PARSE ARG EMAIL_ADDR, EXPORT_DSN
   
   /* Generate JCL to send email */
   EMAIL_JCL = "USER.DB2CRUD.EMAIL.JCL"
   
   /* This would create JCL to send the exported file via email */
   
RETURN
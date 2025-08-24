/* REXX - DB2 CRUD Utility Functions */
/* Supporting utility functions for DB2CRUD.REXX */

/* Format column value based on DB2 data type */
FORMAT_VALUE: PROCEDURE
   PARSE ARG VALUE, DATATYPE, LENGTH
   
   SELECT
      WHEN DATATYPE = "CHAR" | DATATYPE = "VARCHAR" THEN DO
         /* String values need quotes */
         FORMATTED = "'" || VALUE || "'"
      END
      WHEN DATATYPE = "INTEGER" | DATATYPE = "SMALLINT" | DATATYPE = "BIGINT" THEN DO
         /* Numeric values - validate numeric */
         IF DATATYPE(VALUE, 'N') THEN
            FORMATTED = VALUE
         ELSE
            FORMATTED = "NULL"
      END
      WHEN DATATYPE = "DECIMAL" | DATATYPE = "NUMERIC" THEN DO
         /* Decimal values */
         IF DATATYPE(VALUE, 'N') THEN
            FORMATTED = VALUE
         ELSE
            FORMATTED = "NULL"
      END 
      WHEN DATATYPE = "DATE" THEN DO
         /* Date values */
         FORMATTED = "DATE('" || VALUE || "')"
      END
      WHEN DATATYPE = "TIME" THEN DO
         /* Time values */  
         FORMATTED = "TIME('" || VALUE || "')"
      END
      WHEN DATATYPE = "TIMESTAMP" THEN DO
         /* Timestamp values */
         FORMATTED = "TIMESTAMP('" || VALUE || "')"
      END
      OTHERWISE DO
         /* Default to string */
         FORMATTED = "'" || VALUE || "'"
      END
   END
   
   /* Handle NULL values */
   IF UPPER(VALUE) = "NULL" | VALUE = "" THEN
      FORMATTED = "NULL"
      
RETURN FORMATTED

/* Validate column value based on data type */
VALIDATE_VALUE: PROCEDURE
   PARSE ARG VALUE, DATATYPE, LENGTH, SCALE
   
   ERROR_MSG = ""
   
   /* Skip validation for NULL values */
   IF UPPER(VALUE) = "NULL" | VALUE = "" THEN
      RETURN ""
   
   SELECT
      WHEN DATATYPE = "INTEGER" | DATATYPE = "SMALLINT" | DATATYPE = "BIGINT" THEN DO
         IF \DATATYPE(VALUE, 'N') THEN
            ERROR_MSG = "Must be numeric"
         ELSE IF DATATYPE = "SMALLINT" & (VALUE < -32768 | VALUE > 32767) THEN
            ERROR_MSG = "Value out of range for SMALLINT"
      END
      WHEN DATATYPE = "DECIMAL" | DATATYPE = "NUMERIC" THEN DO
         IF \DATATYPE(VALUE, 'N') THEN
            ERROR_MSG = "Must be numeric"
         ELSE DO
            /* Check precision and scale */
            IF POS('.', VALUE) > 0 THEN DO
               DECIMAL_PLACES = LENGTH(VALUE) - POS('.', VALUE)
               IF DECIMAL_PLACES > SCALE THEN
                  ERROR_MSG = "Too many decimal places (max " || SCALE || ")"
            END
         END
      END
      WHEN DATATYPE = "CHAR" THEN DO
         IF LENGTH(VALUE) > LENGTH THEN
            ERROR_MSG = "Value too long (max " || LENGTH || " characters)"
      END
      WHEN DATATYPE = "VARCHAR" THEN DO
         IF LENGTH(VALUE) > LENGTH THEN
            ERROR_MSG = "Value too long (max " || LENGTH || " characters)"
      END
      WHEN DATATYPE = "DATE" THEN DO
         /* Basic date format validation */
         IF LENGTH(VALUE) <> 10 | POS('-', VALUE) = 0 THEN
            ERROR_MSG = "Invalid date format (use YYYY-MM-DD)"
      END
      WHEN DATATYPE = "TIME" THEN DO
         /* Basic time format validation */
         IF LENGTH(VALUE) < 8 | POS(':', VALUE) = 0 THEN
            ERROR_MSG = "Invalid time format (use HH:MM:SS)"
      END
   END
   
RETURN ERROR_MSG

/* Create abbreviated column name with collision detection */
CREATE_SMART_ABBREV: PROCEDURE EXPOSE ABBREV_LIST.
   PARSE ARG FULLNAME, COLNUM
   
   /* If name is already 8 chars or less, use as-is */
   IF LENGTH(FULLNAME) <= 8 THEN DO
      ABBREV = FULLNAME
   END
   ELSE DO
      /* Create various abbreviation strategies */
      
      /* Strategy 1: First 6 chars + sequence number */
      ABBREV = LEFT(FULLNAME, 6) || RIGHT("0" || COLNUM, 2)
      
      /* Strategy 2: Remove vowels if strategy 1 creates collision */
      IF ABBREV_LIST.ABBREV <> "" THEN DO
         CONSONANTS = TRANSLATE(FULLNAME, "", "AEIOU")
         ABBREV = LEFT(CONSONANTS, 8)
      END
      
      /* Strategy 3: Use first letter of each word */
      IF ABBREV_LIST.ABBREV <> "" THEN DO
         WORDS = TRANSLATE(FULLNAME, " ", "_")
         ABBREV = ""
         DO I = 1 TO WORDS(WORDS)
            ABBREV = ABBREV || LEFT(WORD(WORDS, I), 1)
         END
         ABBREV = LEFT(ABBREV || COLNUM, 8)
      END
   END
   
   /* Store to detect future collisions */
   ABBREV_LIST.ABBREV = FULLNAME
   
RETURN ABBREV

/* Build WHERE clause for UPDATE/DELETE operations */
BUILD_WHERE_CLAUSE: PROCEDURE EXPOSE TEMP_TABLE DATA_TABLE
   WHERE_CLAUSE = ""
   FIRST = 1
   
   /* Use primary key columns if available, otherwise use all non-null columns */
   "TBTOP" TEMP_TABLE
   DO WHILE RC = 0
      "TBSKIP" TEMP_TABLE
      IF RC = 0 THEN DO
         "TBGET" DATA_TABLE
         IF RC = 0 & ISPFNAME <> "" THEN DO
            VALUE = VALUE(ISPFNAME)
            IF VALUE <> "" & UPPER(VALUE) <> "NULL" THEN DO
               IF FIRST = 0 THEN
                  WHERE_CLAUSE = WHERE_CLAUSE || " AND "
               ELSE
                  WHERE_CLAUSE = " WHERE "
               
               FORMATTED_VALUE = FORMAT_VALUE(VALUE, COLTYPE, LENGTH)
               WHERE_CLAUSE = WHERE_CLAUSE || COLNAME || " = " || FORMATTED_VALUE
               FIRST = 0
            END
         END
      END
   END
   
RETURN WHERE_CLAUSE

/* Format result set for display */
FORMAT_RESULTS: PROCEDURE
   PARSE ARG CURSOR_NAME, MAX_ROWS
   
   RESULT_LINES = ""
   ROW_COUNT = 0
   
   ADDRESS DSNREXX
   DO WHILE SQLCODE = 0 & ROW_COUNT < MAX_ROWS
      "EXECSQL FETCH" CURSOR_NAME "INTO :COL1, :COL2, :COL3, :COL4, :COL5"
      IF SQLCODE = 0 THEN DO
         ROW_COUNT = ROW_COUNT + 1
         /* Format row data */
         ROW_DATA = LEFT(COL1, 15) || LEFT(COL2, 15) || LEFT(COL3, 15) || ,
                   LEFT(COL4, 15) || LEFT(COL5, 15)
         RESULT_LINES = RESULT_LINES || ROW_DATA || ";"
      END
   END
   ADDRESS ISPEXEC
   
RETURN RESULT_LINES

/* Get DB2 table metadata */
GET_TABLE_METADATA: PROCEDURE
   PARSE ARG SCHEMA, TABLENAME
   
   /* Get additional table information */
   QUERY = "SELECT COLCOUNT, KEYCOLUMNS " ||,
           "FROM SYSIBM.SYSTABLES " ||,
           "WHERE CREATOR = '" || SCHEMA || "' " ||,
           "AND NAME = '" || TABLENAME || "'"
   
   ADDRESS DSNREXX
   "EXECSQL" QUERY
   
   /* Could also get indexes, constraints, etc. */
   
   ADDRESS ISPEXEC
RETURN

/* Handle DB2 errors and provide user-friendly messages */
HANDLE_DB2_ERROR: PROCEDURE
   PARSE ARG SQLCODE, SQLERRM
   
   SELECT
      WHEN SQLCODE = -204 THEN
         USER_MSG = "Table or view not found. Check schema and table name."
      WHEN SQLCODE = -206 THEN  
         USER_MSG = "Column name not valid. Check column names."
      WHEN SQLCODE = -407 THEN
         USER_MSG = "Cannot insert NULL into required column."
      WHEN SQLCODE = -530 THEN
         USER_MSG = "Foreign key constraint violation."
      WHEN SQLCODE = -803 THEN
         USER_MSG = "Duplicate key value. Record already exists."
      WHEN SQLCODE = -911 THEN
         USER_MSG = "Deadlock or timeout. Try again."
      WHEN SQLCODE = -923 THEN
         USER_MSG = "Connection to DB2 lost."
      OTHERWISE
         USER_MSG = "DB2 Error " || SQLCODE || ": " || LEFT(SQLERRM, 50)
   END
   
RETURN USER_MSG
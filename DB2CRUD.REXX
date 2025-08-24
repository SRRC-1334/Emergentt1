/* REXX - DB2 CRUD Operations Tool */
/* Main program for DB2 CRUD operations using ISPF tables */

TRACE OFF
ADDRESS ISPEXEC

/* Initialize variables */
DB2SSID = ""
SCHEMA = ""
TABLENAME = ""
RETCODE = 0
CRUD_OP = ""
TEMP_TABLE = "CRUDTEMP"
DATA_TABLE = "CRUDDATA"

/* Main program flow */
CALL INITIALIZE
CALL MAIN_PANEL
IF RETCODE = 0 THEN DO
   CALL GET_TABLE_STRUCTURE
   IF RETCODE = 0 THEN DO
      CALL CREATE_TEMP_TABLES
      CALL DATA_ENTRY_LOOP
   END
END
CALL CLEANUP
EXIT RETCODE

/* Initialize ISPF environment */
INITIALIZE:
   "CONTROL ERRORS RETURN"
   "VDEFINE DB2SSID CHAR 4"
   "VDEFINE SCHEMA CHAR 30"
   "VDEFINE TABLENAME CHAR 30"
   "VDEFINE CRUD_OP CHAR 1"
   "VDEFINE MSG CHAR 78"
   MSG = ""
RETURN

/* Display main input panel */
MAIN_PANEL:
   DO WHILE RETCODE = 0
      "DISPLAY PANEL(DB2MAIN)"
      SELECT
         WHEN RC = 0 THEN DO
            IF DB2SSID = "" | SCHEMA = "" | TABLENAME = "" THEN DO
               MSG = "All fields are required"
               ITERATE
            END
            LEAVE
         END
         WHEN RC = 8 THEN DO
            RETCODE = 8
            LEAVE
         END
         OTHERWISE DO
            MSG = "Panel error RC=" || RC
            ITERATE
         END
      END
   END
RETURN

/* Get table structure from DB2 SYSCOLUMNS */
GET_TABLE_STRUCTURE:
   /* Connect to DB2 */
   CALL CONNECT_DB2
   IF RETCODE <> 0 THEN RETURN
   
   /* Build query to get column information */
   QUERY = "SELECT COLNAME, COLTYPE, LENGTH, SCALE, NULLS " ||,
           "FROM SYSIBM.SYSCOLUMNS " ||,
           "WHERE TBCREATOR = '" || SCHEMA || "' " ||,
           "AND TBNAME = '" || TABLENAME || "' " ||,
           "ORDER BY COLNO"
   
   /* Execute query */
   CALL EXECUTE_QUERY QUERY
   IF RETCODE <> 0 THEN DO
      MSG = "Error retrieving table structure"
      RETURN
   END
   
   /* Process results and create column mapping */
   CALL CREATE_COLUMN_MAPPING
RETURN

/* Connect to DB2 */
CONNECT_DB2:
   ADDRESS TSO
   "SUBCOM DSNREXX"
   IF RC <> 0 THEN DO
      ADDRESS ISPEXEC "SELECT CMD(DSN SYSTEM(" || DB2SSID || "))"
      "SUBCOM DSNREXX"
      IF RC <> 0 THEN DO
         RETCODE = 12
         MSG = "Cannot connect to DB2 subsystem " || DB2SSID
         RETURN
      END
   END
   ADDRESS DSNREXX "CONNECT " || DB2SSID
   IF SQLCODE <> 0 THEN DO
      RETCODE = 12
      MSG = "DB2 Connect failed, SQLCODE=" || SQLCODE
   END
   ADDRESS ISPEXEC
RETURN

/* Execute DB2 query */
EXECUTE_QUERY: PROCEDURE EXPOSE RETCODE MSG SQLCODE
   PARSE ARG QUERY
   ADDRESS DSNREXX
   "EXECSQL DECLARE C1 CURSOR FOR" QUERY
   IF SQLCODE <> 0 THEN DO
      RETCODE = 12
      MSG = "Declare cursor failed, SQLCODE=" || SQLCODE
      RETURN
   END
   
   "EXECSQL OPEN C1"
   IF SQLCODE <> 0 THEN DO
      RETCODE = 12
      MSG = "Open cursor failed, SQLCODE=" || SQLCODE
      RETURN
   END
   ADDRESS ISPEXEC
RETURN

/* Create column name mapping for ISPF 8-char limit */
CREATE_COLUMN_MAPPING:
   COL_COUNT = 0
   ADDRESS DSNREXX
   DO WHILE SQLCODE = 0
      "EXECSQL FETCH C1 INTO :COLNAME, :COLTYPE, :LENGTH, :SCALE, :NULLS"
      IF SQLCODE = 0 THEN DO
         COL_COUNT = COL_COUNT + 1
         
         /* Create 8-char abbreviated name */
         ISPF_NAME = CREATE_ABBREV(COLNAME, COL_COUNT)
         
         /* Store mapping */
         CALL STORE_COLUMN_INFO COL_COUNT, COLNAME, ISPF_NAME, COLTYPE, LENGTH, NULLS
      END
   END
   "EXECSQL CLOSE C1"
   ADDRESS ISPEXEC
   
   IF COL_COUNT = 0 THEN DO
      RETCODE = 12
      MSG = "No columns found for table " || SCHEMA || "." || TABLENAME
   END
RETURN

/* Create abbreviated column name */
CREATE_ABBREV: PROCEDURE
   PARSE ARG FULLNAME, COLNUM
   IF LENGTH(FULLNAME) <= 8 THEN
      RETURN FULLNAME
   
   /* Take first 6 chars + 2-digit number */
   ABBREV = LEFT(FULLNAME, 6) || RIGHT("0" || COLNUM, 2)
RETURN ABBREV

/* Store column information */
STORE_COLUMN_INFO: PROCEDURE EXPOSE TEMP_TABLE
   PARSE ARG COLNUM, COLNAME, ISPF_NAME, COLTYPE, LENGTH, NULLS
   
   ADDRESS ISPEXEC
   "TBADD" TEMP_TABLE
   "TBPUT" TEMP_TABLE
RETURN

/* Create temporary ISPF tables */
CREATE_TEMP_TABLES:
   /* Create table for column definitions */
   "TBCREATE" TEMP_TABLE "KEYS(COLNUM) NAMES(COLNAME ISPFNAME COLTYPE LENGTH NULLS)"
   IF RC <> 0 THEN DO
      RETCODE = 12
      MSG = "Cannot create temporary table"
      RETURN
   END
   
   /* Create table for data entry */
   VARLIST = ""
   DO I = 1 TO COL_COUNT
      "TBGET" TEMP_TABLE
      IF RC = 0 THEN
         VARLIST = VARLIST ISPFNAME
   END
   
   "TBCREATE" DATA_TABLE "NAMES(" || VARLIST || ")"
   IF RC <> 0 THEN DO
      RETCODE = 12
      MSG = "Cannot create data table"
      RETURN
   END
RETURN

/* Data entry loop */
DATA_ENTRY_LOOP:
   DO WHILE RETCODE = 0
      CALL DISPLAY_DATA_ENTRY
      IF RETCODE <> 0 THEN LEAVE
      
      CALL SELECT_CRUD_OPERATION
      IF RETCODE <> 0 THEN LEAVE
      
      CALL GENERATE_SQL
      IF RETCODE <> 0 THEN LEAVE
      
      CALL EXECUTE_OPERATION
   END
RETURN

/* Display data entry interface */
DISPLAY_DATA_ENTRY:
   /* Create dynamic panel for data entry */
   CALL CREATE_ENTRY_PANEL
   
   "DISPLAY PANEL(DB2ENTRY)"
   SELECT
      WHEN RC = 0 THEN NOP  /* Continue */
      WHEN RC = 8 THEN RETCODE = 8  /* End */
      OTHERWISE DO
         MSG = "Data entry panel error RC=" || RC
         RETCODE = 12
      END
   END
RETURN

/* Create dynamic data entry panel */
CREATE_ENTRY_PANEL:
   /* This would dynamically create panel based on column structure */
   /* For brevity, using static panel - in real implementation, */
   /* this would generate panel source dynamically */
RETURN

/* Select CRUD operation */
SELECT_CRUD_OPERATION:
   "DISPLAY PANEL(DB2OPER)"
   SELECT
      WHEN RC = 0 THEN DO
         IF CRUD_OP = "" THEN DO
            MSG = "Please select an operation"
            RETCODE = 4
         END
      END
      WHEN RC = 8 THEN RETCODE = 8
      OTHERWISE DO
         MSG = "Operation selection error RC=" || RC
         RETCODE = 12
      END
   END
RETURN

/* Generate SQL based on operation */
GENERATE_SQL:
   SELECT
      WHEN CRUD_OP = "C" THEN CALL GENERATE_INSERT
      WHEN CRUD_OP = "R" THEN CALL GENERATE_SELECT
      WHEN CRUD_OP = "U" THEN CALL GENERATE_UPDATE
      WHEN CRUD_OP = "D" THEN CALL GENERATE_DELETE
      OTHERWISE DO
         MSG = "Invalid operation: " || CRUD_OP
         RETCODE = 12
      END
   END
RETURN

/* Generate INSERT SQL */
GENERATE_INSERT:
   SQL_STMT = "INSERT INTO " || SCHEMA || "." || TABLENAME || " ("
   VALUES_CLAUSE = " VALUES ("
   
   /* Build column list and values */
   FIRST = 1
   "TBTOP" TEMP_TABLE
   DO WHILE RC = 0
      "TBSKIP" TEMP_TABLE
      IF RC = 0 THEN DO
         IF FIRST = 0 THEN DO
            SQL_STMT = SQL_STMT || ", "
            VALUES_CLAUSE = VALUES_CLAUSE || ", "
         END
         SQL_STMT = SQL_STMT || COLNAME
         VALUES_CLAUSE = VALUES_CLAUSE || "?"
         FIRST = 0
      END
   END
   
   SQL_STMT = SQL_STMT || ")" || VALUES_CLAUSE || ")"
RETURN

/* Generate SELECT SQL */
GENERATE_SELECT:
   SQL_STMT = "SELECT * FROM " || SCHEMA || "." || TABLENAME
   /* Add WHERE clause based on entered values */
   CALL ADD_WHERE_CLAUSE
RETURN

/* Generate UPDATE SQL */
GENERATE_UPDATE:
   SQL_STMT = "UPDATE " || SCHEMA || "." || TABLENAME || " SET "
   
   /* Build SET clause */
   FIRST = 1
   "TBTOP" TEMP_TABLE
   DO WHILE RC = 0
      "TBSKIP" TEMP_TABLE
      IF RC = 0 THEN DO
         IF FIRST = 0 THEN
            SQL_STMT = SQL_STMT || ", "
         SQL_STMT = SQL_STMT || COLNAME || " = ?"
         FIRST = 0
      END
   END
   
   /* Add WHERE clause */
   CALL ADD_WHERE_CLAUSE
RETURN

/* Generate DELETE SQL */
GENERATE_DELETE:
   SQL_STMT = "DELETE FROM " || SCHEMA || "." || TABLENAME
   CALL ADD_WHERE_CLAUSE
RETURN

/* Add WHERE clause based on key fields */
ADD_WHERE_CLAUSE:
   /* This would add WHERE conditions based on key fields */
   /* Implementation depends on how keys are identified */
RETURN

/* Execute the SQL operation */
EXECUTE_OPERATION:
   /* Display SQL for confirmation */
   "VPUT SQL_STMT"
   "DISPLAY PANEL(DB2CONF)"
   
   IF RC = 0 THEN DO
      /* Execute the SQL */
      ADDRESS DSNREXX
      "EXECSQL" SQL_STMT
      IF SQLCODE = 0 THEN DO
         MSG = "Operation completed successfully"
         CALL DISPLAY_RESULTS
      END
      ELSE DO
         MSG = "SQL Error: SQLCODE=" || SQLCODE || " " || SQLERRM
         RETCODE = 12
      END
      ADDRESS ISPEXEC
   END
RETURN

/* Display operation results */
DISPLAY_RESULTS:
   "DISPLAY PANEL(DB2RSLT)"
RETURN

/* Cleanup and exit */
CLEANUP:
   "TBCLOSE" TEMP_TABLE
   "TBCLOSE" DATA_TABLE
   ADDRESS DSNREXX "COMMIT"
   ADDRESS TSO "END"
RETURN
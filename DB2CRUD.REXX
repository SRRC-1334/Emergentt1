/* REXX - DB2 CRUD Operations Tool - Enhanced Version */
/* Main program for comprehensive DB2 CRUD operations */

TRACE OFF
ADDRESS ISPEXEC

/* Initialize global variables */
DB2SSID = ""
SCHEMA = ""
TABLENAME = ""
CRUD_OP = ""
OPTION = ""
RETCODE = 0
LOG_DSN = ""
DEEP_LOG = "N"
MAX_ROWS = 200
EXPORT_DELIM = ";"

/* Column information arrays */
COL_INFO. = ""
COL_COUNT = 0
INDEX_COLS. = ""

/* Settings */
SETTINGS_DSN = "USER.DB2CRUD.SETTINGS"
USERQRY_DSN = "USER.DB2CRUD.USERQRY"

/* Main program flow */
CALL INITIALIZE
CALL MAIN_SCREEN_LOOP
CALL CLEANUP
EXIT RETCODE

/* Initialize ISPF environment and load settings */
INITIALIZE:
   "CONTROL ERRORS RETURN"
   CALL LOG_MESSAGE "DB2CRUD Started - Initializing environment"
   
   /* Define ISPF variables */
   "VDEFINE DB2SSID CHAR 4"
   "VDEFINE SCHEMA CHAR 30"  
   "VDEFINE TABLENAME CHAR 30"
   "VDEFINE CRUD_OP CHAR 1"
   "VDEFINE OPTION CHAR 1"
   "VDEFINE MSG CHAR 78"
   "VDEFINE PROGRESS_MSG CHAR 50"
   "VDEFINE PROGRESS_PCT CHAR 3"
   
   MSG = ""
   
   /* Load user settings */
   CALL LOAD_SETTINGS
   
   /* Create log dataset for today */
   CALL CREATE_LOG_DATASET
   
   CALL LOG_MESSAGE "Environment initialized successfully"
RETURN

/* Main screen interaction loop */
MAIN_SCREEN_LOOP:
   DO WHILE RETCODE = 0
      "DISPLAY PANEL(DB2MAIN)"
      SELECT
         WHEN RC = 0 THEN DO
            /* Process based on option or ENTER */
            SELECT
               WHEN OPTION = "1" THEN CALL QUERY_HISTORY
               WHEN OPTION = "2" THEN CALL SETTINGS_PANEL  
               WHEN OPTION = "3" THEN DO
                  CALL LOG_MESSAGE "User selected Exit"
                  RETCODE = 0
                  LEAVE
               END
               OTHERWISE DO
                  /* New Query - validate all fields */
                  IF DB2SSID = "" | SCHEMA = "" | TABLENAME = "" | CRUD_OP = "" THEN DO
                     MSG = "All fields required for new query"
                     CALL LOG_MESSAGE "Validation failed: " || MSG
                     ITERATE
                  END
                  CALL PROCESS_NEW_QUERY
               END
            END
            OPTION = ""  /* Reset option after processing */
         END
         WHEN RC = 8 THEN DO
            CALL LOG_MESSAGE "User pressed PF3 to exit"
            RETCODE = 8
            LEAVE
         END
         OTHERWISE DO
            MSG = "Panel error RC=" || RC
            CALL LOG_MESSAGE "Panel error: " || MSG
            ITERATE
         END
      END
   END
RETURN

/* Process new query based on CRUD operation */
PROCESS_NEW_QUERY:
   CALL LOG_MESSAGE "Processing new query - CRUD:" || CRUD_OP || " Table:" || SCHEMA || "." || TABLENAME
   
   /* Connect to DB2 and get table structure */
   CALL SHOW_PROGRESS "Connecting to DB2...", 10
   CALL CONNECT_DB2
   IF RETCODE <> 0 THEN RETURN
   
   CALL SHOW_PROGRESS "Reading table structure...", 30
   CALL GET_TABLE_STRUCTURE
   IF RETCODE <> 0 THEN RETURN
   
   CALL SHOW_PROGRESS "Identifying index columns...", 50
   CALL GET_INDEX_COLUMNS
   
   /* Display appropriate data entry screen based on CRUD */
   SELECT
      WHEN CRUD_OP = "C" THEN CALL CREATE_DATA_ENTRY
      WHEN CRUD_OP = "R" | CRUD_OP = "U" | CRUD_OP = "D" THEN CALL WHERE_CONDITION_ENTRY
      OTHERWISE DO
         MSG = "Invalid CRUD operation: " || CRUD_OP
         RETCODE = 12
         RETURN
      END
   END
   
   IF RETCODE <> 0 THEN RETURN
   
   /* Ask if user wants to edit SQL */
   CALL ASK_EDIT_SQL
   IF RETCODE <> 0 THEN RETURN
   
   /* Ask if user wants to execute */
   CALL ASK_EXECUTE
   IF RETCODE <> 0 THEN RETURN
   
   /* Preview row count and get confirmation */
   CALL PREVIEW_AND_CONFIRM
   IF RETCODE <> 0 THEN RETURN
   
   /* Execute the operation */
   CALL EXECUTE_OPERATION
   
   /* Save query to history */
   CALL SAVE_QUERY_HISTORY
RETURN

/* Connect to DB2 subsystem */
CONNECT_DB2:
   ADDRESS TSO
   "SUBCOM DSNREXX"
   IF RC <> 0 THEN DO
      CALL LOG_MESSAGE "Starting DB2 attachment for SSID: " || DB2SSID
      ADDRESS ISPEXEC "SELECT CMD(DSN SYSTEM(" || DB2SSID || "))"
      "SUBCOM DSNREXX"
      IF RC <> 0 THEN DO
         RETCODE = 12
         MSG = "Cannot attach to DB2 subsystem " || DB2SSID
         CALL LOG_MESSAGE "ERROR: " || MSG
         RETURN
      END
   END
   
   ADDRESS DSNREXX "CONNECT " || DB2SSID
   IF SQLCODE <> 0 THEN DO
      RETCODE = 12
      MSG = "DB2 Connect failed, SQLCODE=" || SQLCODE
      CALL LOG_MESSAGE "ERROR: " || MSG
      CALL HANDLE_DB2_ERROR SQLCODE, SQLERRM
   ELSE DO
      CALL LOG_MESSAGE "Successfully connected to DB2 SSID: " || DB2SSID
   END
   ADDRESS ISPEXEC
RETURN

/* Get table structure from SYSCOLUMNS */
GET_TABLE_STRUCTURE:
   QUERY = "SELECT COLNAME, COLTYPE, LENGTH, SCALE, NULLS, COLNO " ||,
           "FROM SYSIBM.SYSCOLUMNS " ||,
           "WHERE TBCREATOR = '" || SCHEMA || "' " ||,
           "AND TBNAME = '" || TABLENAME || "' " ||,
           "ORDER BY COLNO"
   
   CALL LOG_MESSAGE "Executing query to get table structure"
   IF DEEP_LOG = "Y" THEN CALL LOG_MESSAGE "SQL: " || QUERY
   
   ADDRESS DSNREXX
   "EXECSQL DECLARE C_STRUCT CURSOR FOR" QUERY
   IF SQLCODE <> 0 THEN DO
      RETCODE = 12
      MSG = "Error declaring cursor for table structure"
      CALL LOG_MESSAGE "ERROR: " || MSG || " SQLCODE=" || SQLCODE
      ADDRESS ISPEXEC
      RETURN
   END
   
   "EXECSQL OPEN C_STRUCT"
   IF SQLCODE <> 0 THEN DO
      RETCODE = 12  
      MSG = "Error opening cursor for table structure"
      CALL LOG_MESSAGE "ERROR: " || MSG || " SQLCODE=" || SQLCODE
      ADDRESS ISPEXEC
      RETURN
   END
   
   /* Fetch column information */
   COL_COUNT = 0
   DO WHILE SQLCODE = 0
      "EXECSQL FETCH C_STRUCT INTO :COLNAME, :COLTYPE, :LENGTH, :SCALE, :NULLS, :COLNO"
      IF SQLCODE = 0 THEN DO
         COL_COUNT = COL_COUNT + 1
         COL_INFO.COL_COUNT.NAME = COLNAME
         COL_INFO.COL_COUNT.TYPE = COLTYPE
         COL_INFO.COL_COUNT.LENGTH = LENGTH
         COL_INFO.COL_COUNT.SCALE = SCALE
         COL_INFO.COL_COUNT.NULLS = NULLS
         COL_INFO.COL_COUNT.COLNO = COLNO
         COL_INFO.COL_COUNT.ISPF_NAME = "C" || RIGHT("000" || COLNO, 4)
         
         CALL LOG_MESSAGE "Column " || COL_COUNT || ": " || COLNAME || " (" || COLTYPE || ")"
      END
   END
   
   "EXECSQL CLOSE C_STRUCT"
   ADDRESS ISPEXEC
   
   IF COL_COUNT = 0 THEN DO
      RETCODE = 12
      MSG = "No columns found for table " || SCHEMA || "." || TABLENAME
      CALL LOG_MESSAGE "ERROR: " || MSG
   ELSE DO
      CALL LOG_MESSAGE "Retrieved " || COL_COUNT || " columns from table structure"
   END
RETURN

/* Get index column information */
GET_INDEX_COLUMNS:
   /* Get primary key columns */
   PK_QUERY = "SELECT COLNAME FROM SYSIBM.SYSKEYS " ||,
              "WHERE TBCREATOR = '" || SCHEMA || "' " ||,
              "AND TBNAME = '" || TABLENAME || "'"
   
   CALL LOG_MESSAGE "Identifying primary key columns"
   
   ADDRESS DSNREXX
   "EXECSQL DECLARE C_PK CURSOR FOR" PK_QUERY
   IF SQLCODE = 0 THEN DO
      "EXECSQL OPEN C_PK"
      IF SQLCODE = 0 THEN DO
         DO WHILE SQLCODE = 0
            "EXECSQL FETCH C_PK INTO :COLNAME"
            IF SQLCODE = 0 THEN DO
               INDEX_COLS.COLNAME = "PK"
               CALL LOG_MESSAGE "Primary key column: " || COLNAME
            END
         END
         "EXECSQL CLOSE C_PK"
      END
   END
   
   /* Get index columns */
   IX_QUERY = "SELECT COLNAME FROM SYSIBM.SYSINDEXES I, SYSIBM.SYSKEYS K " ||,
              "WHERE I.CREATOR = '" || SCHEMA || "' " ||,
              "AND I.TBNAME = '" || TABLENAME || "' " ||,
              "AND I.NAME = K.IXNAME " ||,
              "AND I.CREATOR = K.IXCREATOR"
   
   "EXECSQL DECLARE C_IX CURSOR FOR" IX_QUERY  
   IF SQLCODE = 0 THEN DO
      "EXECSQL OPEN C_IX"
      IF SQLCODE = 0 THEN DO
         DO WHILE SQLCODE = 0
            "EXECSQL FETCH C_IX INTO :COLNAME"
            IF SQLCODE = 0 THEN DO
               IF INDEX_COLS.COLNAME = "" THEN
                  INDEX_COLS.COLNAME = "IX"
               CALL LOG_MESSAGE "Index column: " || COLNAME
            END
         END
         "EXECSQL CLOSE C_IX"
      END
   END
   
   ADDRESS ISPEXEC
RETURN

/* CREATE operation data entry */
CREATE_DATA_ENTRY:
   CALL LOG_MESSAGE "Displaying CREATE data entry screen"
   CALL CREATE_DYNAMIC_CREATE_PANEL
   
   "DISPLAY PANEL(DB2CREATE)"
   SELECT
      WHEN RC = 0 THEN DO
         CALL LOG_MESSAGE "User completed CREATE data entry"
         CALL BUILD_INSERT_SQL
      END
      WHEN RC = 8 THEN DO
         RETCODE = 8
         CALL LOG_MESSAGE "User cancelled CREATE operation"
      END
      OTHERWISE DO
         MSG = "CREATE panel error RC=" || RC
         RETCODE = 12
         CALL LOG_MESSAGE "ERROR: " || MSG
      END
   END
RETURN

/* WHERE condition entry for R/U/D operations */
WHERE_CONDITION_ENTRY:
   CALL LOG_MESSAGE "Displaying WHERE condition entry for " || CRUD_OP || " operation"
   CALL CREATE_DYNAMIC_WHERE_PANEL
   
   "DISPLAY PANEL(DB2WHERE)"
   SELECT
      WHEN RC = 0 THEN DO
         CALL LOG_MESSAGE "User completed WHERE condition entry"
         SELECT
            WHEN CRUD_OP = "R" THEN CALL BUILD_SELECT_SQL
            WHEN CRUD_OP = "U" THEN CALL BUILD_UPDATE_SQL  
            WHEN CRUD_OP = "D" THEN CALL BUILD_DELETE_SQL
         END
      END
      WHEN RC = 8 THEN DO
         RETCODE = 8
         CALL LOG_MESSAGE "User cancelled " || CRUD_OP || " operation"
      END
      OTHERWISE DO
         MSG = "WHERE panel error RC=" || RC
         RETCODE = 12
         CALL LOG_MESSAGE "ERROR: " || MSG
      END
   END
RETURN

/* Ask user if they want to edit SQL */
ASK_EDIT_SQL:
   "VDEFINE EDIT_SQL CHAR 1"
   EDIT_SQL = "N"
   
   "DISPLAY PANEL(DB2ASKEDIT)"
   SELECT
      WHEN RC = 0 THEN DO
         IF EDIT_SQL = "Y" THEN DO
            CALL LOG_MESSAGE "User chose to edit SQL"
            CALL SQL_EDIT_PANEL
         ELSE DO
            CALL LOG_MESSAGE "User chose not to edit SQL"
         END
      END
      WHEN RC = 8 THEN DO
         RETCODE = 8
         CALL LOG_MESSAGE "User cancelled at SQL edit prompt"
      END
      OTHERWISE DO
         MSG = "SQL edit prompt error RC=" || RC
         RETCODE = 12
      END
   END
   
   "VDELETE EDIT_SQL"
RETURN

/* SQL Edit Panel */
SQL_EDIT_PANEL:
   "VDEFINE SQL_STMT CHAR 2000"
   
   "DISPLAY PANEL(DB2EDIT)"
   SELECT
      WHEN RC = 0 THEN DO
         CALL LOG_MESSAGE "User completed SQL editing"
         IF DEEP_LOG = "Y" THEN CALL LOG_MESSAGE "Edited SQL: " || SQL_STMT
      END
      WHEN RC = 8 THEN DO
         RETCODE = 8
         CALL LOG_MESSAGE "User cancelled SQL editing"
      END
      OTHERWISE DO
         MSG = "SQL edit panel error RC=" || RC
         RETCODE = 12
      END
   END
   
   "VDELETE SQL_STMT"
RETURN

/* Ask user if they want to execute */  
ASK_EXECUTE:
   "VDEFINE EXECUTE_YN CHAR 1"
   EXECUTE_YN = "N"
   
   "DISPLAY PANEL(DB2ASKEXEC)"
   SELECT
      WHEN RC = 0 THEN DO
         IF EXECUTE_YN = "Y" THEN DO
            CALL LOG_MESSAGE "User chose to execute SQL"
         ELSE DO
            CALL LOG_MESSAGE "User chose not to execute SQL"
            RETCODE = 4
         END
      END
      WHEN RC = 8 THEN DO
         RETCODE = 8
         CALL LOG_MESSAGE "User cancelled at execute prompt"
      END
      OTHERWISE DO
         MSG = "Execute prompt error RC=" || RC
         RETCODE = 12
      END
   END
   
   "VDELETE EXECUTE_YN"
RETURN

/* Preview row count and get confirmation */
PREVIEW_AND_CONFIRM:
   CALL SHOW_PROGRESS "Calculating affected rows...", 70
   
   /* Calculate affected rows based on operation */
   SELECT
      WHEN CRUD_OP = "C" THEN AFFECTED_ROWS = 1
      WHEN CRUD_OP = "R" THEN CALL COUNT_SELECT_ROWS
      WHEN CRUD_OP = "U" | CRUD_OP = "D" THEN CALL COUNT_AFFECTED_ROWS
   END
   
   "VDEFINE AFFECTED_ROWS CHAR 10"
   "VDEFINE COMMIT_YN CHAR 1"
   COMMIT_YN = "N"
   
   "DISPLAY PANEL(DB2CONFIRM)"
   SELECT
      WHEN RC = 0 THEN DO
         IF COMMIT_YN = "Y" THEN DO
            CALL LOG_MESSAGE "User confirmed execution for " || AFFECTED_ROWS || " rows"
         ELSE DO
            CALL LOG_MESSAGE "User declined execution"
            RETCODE = 4
         END
      END
      WHEN RC = 8 THEN DO
         RETCODE = 8
         CALL LOG_MESSAGE "User cancelled at confirmation"
      END
      OTHERWISE DO
         MSG = "Confirmation panel error RC=" || RC
         RETCODE = 12
      END
   END
   
   "VDELETE AFFECTED_ROWS"
   "VDELETE COMMIT_YN" 
RETURN

/* Execute the SQL operation */
EXECUTE_OPERATION:
   CALL SHOW_PROGRESS "Executing SQL statement...", 80
   CALL LOG_MESSAGE "Executing SQL operation"
   
   ADDRESS DSNREXX
   "EXECSQL" SQL_STMT
   
   SELECT
      WHEN SQLCODE = 0 THEN DO
         CALL LOG_MESSAGE "SQL executed successfully"
         "EXECSQL COMMIT"
         CALL SHOW_PROGRESS "Operation completed successfully", 100
         CALL DISPLAY_RESULTS
      END
      WHEN SQLCODE = 100 THEN DO
         CALL LOG_MESSAGE "No rows found/affected"
         MSG = "No rows found or affected"
         CALL DISPLAY_RESULTS
      END
      OTHERWISE DO
         CALL LOG_MESSAGE "SQL Error: SQLCODE=" || SQLCODE
         "EXECSQL ROLLBACK"
         CALL HANDLE_DB2_ERROR SQLCODE, SQLERRM
         RETCODE = 12
      END
   END
   
   ADDRESS ISPEXEC
RETURN

/* Display operation results */
DISPLAY_RESULTS:
   CALL LOG_MESSAGE "Displaying operation results"
   
   "VDEFINE RESULT_MSG CHAR 78"
   RESULT_MSG = "Operation completed. SQLCODE=" || SQLCODE
   
   "DISPLAY PANEL(DB2RESULT)"
   
   "VDELETE RESULT_MSG"
RETURN

/* Show progress bar */
SHOW_PROGRESS: PROCEDURE EXPOSE PROGRESS_MSG PROGRESS_PCT DEEP_LOG
   PARSE ARG MESSAGE, PERCENT
   
   PROGRESS_MSG = MESSAGE
   PROGRESS_PCT = PERCENT || "%"
   
   /* Create progress bar visual */
   BAR_LENGTH = 20
   FILLED = (PERCENT * BAR_LENGTH) % 100
   PROGRESS_BAR = LEFT(COPIES("#", FILLED) || COPIES("-", BAR_LENGTH - FILLED), BAR_LENGTH)
   
   ADDRESS ISPEXEC
   "VDEFINE PROGRESS_BAR CHAR 20"
   "VPUT PROGRESS_MSG PROGRESS_PCT PROGRESS_BAR"
   
   "DISPLAY PANEL(DB2PROGRESS)"
   
   "VDELETE PROGRESS_BAR"
   
   IF DEEP_LOG = "Y" THEN
      CALL LOG_MESSAGE "Progress: " || PERCENT || "% - " || MESSAGE
RETURN

/* Query History functionality */
QUERY_HISTORY:
   /* Validate SSID is provided */
   IF DB2SSID = "" THEN DO
      MSG = "SSID required for Query History"
      CALL LOG_MESSAGE "Query History validation failed: " || MSG
      RETURN
   END
   
   CALL LOG_MESSAGE "Displaying Query History"
   CALL CREATE_HISTORY_TABLE
   "DISPLAY PANEL(DB2HISTORY)"
RETURN

/* Settings Panel */
SETTINGS_PANEL:
   CALL LOG_MESSAGE "Displaying Settings panel"
   CALL LOAD_SETTINGS
   
   "VDEFINE MAX_ROWS CHAR 3"
   "VDEFINE DEEP_LOG CHAR 1"  
   "VDEFINE EXPORT_DELIM CHAR 1"
   
   "DISPLAY PANEL(DB2SETTINGS)"
   SELECT
      WHEN RC = 0 THEN DO
         CALL SAVE_SETTINGS
         CALL LOG_MESSAGE "Settings saved successfully"
      END
      WHEN RC = 8 THEN DO
         CALL LOG_MESSAGE "Settings cancelled by user"
      END
      OTHERWISE DO
         MSG = "Settings panel error RC=" || RC
      END
   END
   
   "VDELETE MAX_ROWS"
   "VDELETE DEEP_LOG"
   "VDELETE EXPORT_DELIM"
RETURN

/* Load user settings */
LOAD_SETTINGS:
   /* Set defaults */
   MAX_ROWS = 200
   DEEP_LOG = "N"
   EXPORT_DELIM = ";"
   
   /* Try to load from dataset */
   ADDRESS TSO
   "ALLOC F(SETTINGS) DA('" || SETTINGS_DSN || "') SHR REUSE"
   IF RC = 0 THEN DO
      "EXECIO * DISKR SETTINGS (STEM SETTING. FINIS)"
      "FREE F(SETTINGS)"
      
      DO I = 1 TO SETTING.0
         PARSE VAR SETTING.I KEY "=" VALUE
         SELECT
            WHEN KEY = "MAX_ROWS" THEN MAX_ROWS = VALUE
            WHEN KEY = "DEEP_LOG" THEN DEEP_LOG = VALUE
            WHEN KEY = "EXPORT_DELIM" THEN EXPORT_DELIM = VALUE
         END
      END
      
      CALL LOG_MESSAGE "Settings loaded from " || SETTINGS_DSN
   END
   ELSE DO
      CALL LOG_MESSAGE "Using default settings"
   END
   
   ADDRESS ISPEXEC
RETURN

/* Save user settings */
SAVE_SETTINGS:
   SETTING.1 = "MAX_ROWS=" || MAX_ROWS
   SETTING.2 = "DEEP_LOG=" || DEEP_LOG
   SETTING.3 = "EXPORT_DELIM=" || EXPORT_DELIM
   SETTING.0 = 3
   
   ADDRESS TSO
   "ALLOC F(SETTINGS) DA('" || SETTINGS_DSN || "') NEW DELETE UNIT(SYSDA) SPACE(1,1) TRACKS"
   "EXECIO * DISKW SETTINGS (STEM SETTING. FINIS)"
   "FREE F(SETTINGS)"
   
   ADDRESS ISPEXEC
   CALL LOG_MESSAGE "Settings saved to " || SETTINGS_DSN
RETURN

/* Create log dataset for current date */
CREATE_LOG_DATASET:
   TODAY = DATE('S')
   LOG_DSN = "USER.DB2CRUD.LOG.D" || RIGHT(TODAY, 6)  /* DDMMYY format */
   
   ADDRESS TSO
   "ALLOC F(LOGFILE) DA('" || LOG_DSN || "') NEW DELETE UNIT(SYSDA) SPACE(5,5) TRACKS"
   IF RC = 0 THEN DO
      "FREE F(LOGFILE)"
      ADDRESS ISPEXEC
      CALL LOG_MESSAGE "Log dataset created: " || LOG_DSN
   END
   ELSE DO
      /* Dataset might already exist */
      ADDRESS ISPEXEC
      CALL LOG_MESSAGE "Using existing log dataset: " || LOG_DSN
   END
RETURN

/* Log message with timestamp */
LOG_MESSAGE: PROCEDURE EXPOSE LOG_DSN
   PARSE ARG MESSAGE
   
   TIMESTAMP = DATE('I') || " " || TIME('L')
   LOG_ENTRY = TIMESTAMP || " " || MESSAGE
   
   ADDRESS TSO
   "ALLOC F(LOGFILE) DA('" || LOG_DSN || "') MOD REUSE"
   IF RC = 0 THEN DO
      QUEUE LOG_ENTRY
      "EXECIO 1 DISKW LOGFILE"
      "FREE F(LOGFILE)"
   END
   
   ADDRESS ISPEXEC
RETURN

/* Handle DB2 errors with user-friendly messages */
HANDLE_DB2_ERROR: PROCEDURE EXPOSE MSG RETCODE
   PARSE ARG SQLCODE, SQLERRM
   
   "VDEFINE ERROR_CODE CHAR 10"
   "VDEFINE ERROR_MSG CHAR 78"
   "VDEFINE SUGGESTED_FIX CHAR 78"
   
   ERROR_CODE = SQLCODE
   ERROR_MSG = LEFT(SQLERRM, 78)
   
   /* Provide user-friendly error messages and suggestions */
   SELECT
      WHEN SQLCODE = -204 THEN DO
         SUGGESTED_FIX = "Check schema and table name spelling"
         MSG = "Table or view not found"
      END
      WHEN SQLCODE = -206 THEN DO
         SUGGESTED_FIX = "Verify column names in the table"
         MSG = "Column name not valid"
      END
      WHEN SQLCODE = -407 THEN DO
         SUGGESTED_FIX = "Provide values for all required columns"
         MSG = "Cannot insert NULL into required column"
      END
      WHEN SQLCODE = -530 THEN DO
         SUGGESTED_FIX = "Check foreign key constraints"
         MSG = "Foreign key constraint violation"
      END
      WHEN SQLCODE = -803 THEN DO
         SUGGESTED_FIX = "Use different values for unique columns"
         MSG = "Duplicate key value"
      END
      WHEN SQLCODE = -911 THEN DO
         SUGGESTED_FIX = "Wait and retry the operation"  
         MSG = "Deadlock or timeout occurred"
      END
      WHEN SQLCODE = -923 THEN DO
         SUGGESTED_FIX = "Reconnect to DB2 and retry"
         MSG = "Connection to DB2 lost"
      END
      OTHERWISE DO
         SUGGESTED_FIX = "Check DB2 documentation for SQLCODE " || SQLCODE
         MSG = "DB2 Error " || SQLCODE
      END
   END
   
   "DISPLAY PANEL(DB2ERROR)"
   
   "VDELETE ERROR_CODE ERROR_MSG SUGGESTED_FIX"
RETURN

/* Save query to history */
SAVE_QUERY_HISTORY:
   TODAY = DATE('S')
   DAY_MMDDYY = RIGHT(TODAY, 6)
   
   /* Generate member name */
   CRUD_CHAR = CRUD_OP
   SERIAL_NO = 1  /* This should be calculated based on existing members */
   MEMBER_NAME = CRUD_CHAR || DAY_MMDDYY || SERIAL_NO
   
   FULL_DSN = USERQRY_DSN || "(" || MEMBER_NAME || ")"
   
   ADDRESS TSO
   "ALLOC F(QRYHIST) DA('" || FULL_DSN || "') NEW DELETE UNIT(SYSDA) SPACE(1,1) TRACKS"
   IF RC = 0 THEN DO
      QUEUE "-- DB2CRUD Query History"
      QUEUE "-- Date: " || DATE() || " Time: " || TIME()
      QUEUE "-- Table: " || SCHEMA || "." || TABLENAME
      QUEUE "-- Operation: " || CRUD_OP
      QUEUE "--"
      QUEUE SQL_STMT
      QUEUE ""
      "EXECIO * DISKW QRYHIST"
      "FREE F(QRYHIST)"
      
      CALL LOG_MESSAGE "Query saved to history: " || MEMBER_NAME
   END
   ELSE DO
      CALL LOG_MESSAGE "Failed to save query to history"
   END
   
   ADDRESS ISPEXEC
RETURN

/* Cleanup and exit */
CLEANUP:
   CALL LOG_MESSAGE "DB2CRUD session ending - cleanup started"
   
   /* Close any open cursors */
   ADDRESS DSNREXX
   "EXECSQL COMMIT"
   
   /* Disconnect from DB2 */
   ADDRESS TSO "END"
   
   ADDRESS ISPEXEC
   /* Delete ISPF variables */
   "VDELETE DB2SSID SCHEMA TABLENAME CRUD_OP OPTION MSG"
   "VDELETE PROGRESS_MSG PROGRESS_PCT"
   
   CALL LOG_MESSAGE "DB2CRUD session ended successfully"
RETURN

/* Additional utility functions would be added here */
/* CREATE_DYNAMIC_CREATE_PANEL, BUILD_INSERT_SQL, etc. */
/* REXX - Dynamic ISPF Table Management for DB2CRUD */
/* Handles dynamic creation and management of ISPF tables */

/* Create dynamic ISPF table based on DB2 table structure */
CREATE_DYNAMIC_TABLE: PROCEDURE EXPOSE COL_INFO. COL_COUNT
   PARSE ARG TABLE_NAME, TABLE_TYPE
   
   /* Build NAMES list for ISPF table */
   NAME_LIST = ""
   KEY_LIST = ""
   
   DO I = 1 TO COL_COUNT
      ISPF_NAME = COL_INFO.I.ISPF_NAME
      IS_KEY = COL_INFO.I.IS_KEY
      
      NAME_LIST = NAME_LIST || ISPF_NAME
      IF IS_KEY = "Y" THEN
         KEY_LIST = KEY_LIST || ISPF_NAME
      
      IF I < COL_COUNT THEN DO
         NAME_LIST = NAME_LIST || " "
         IF IS_KEY = "Y" THEN
            KEY_LIST = KEY_LIST || " "
      END
   END
   
   /* Create ISPF table */
   ADDRESS ISPEXEC
   IF KEY_LIST <> "" THEN
      "TBCREATE" TABLE_NAME "KEYS(" || KEY_LIST || ") NAMES(" || NAME_LIST || ")"
   ELSE
      "TBCREATE" TABLE_NAME "NAMES(" || NAME_LIST || ")"
   
   CREATE_RC = RC
   
RETURN CREATE_RC

/* Add row to dynamic table */
ADD_TABLE_ROW: PROCEDURE EXPOSE COL_INFO. COL_COUNT
   PARSE ARG TABLE_NAME, VALUE_LIST
   
   /* Set ISPF variables for each column */
   DO I = 1 TO COL_COUNT
      ISPF_NAME = COL_INFO.I.ISPF_NAME
      VALUE = WORD(VALUE_LIST, I)
      
      ADDRESS ISPEXEC "VPUT" ISPF_NAME
      CALL VALUE ISPF_NAME, VALUE
   END
   
   /* Add row to table */
   ADDRESS ISPEXEC "TBADD" TABLE_NAME
   
RETURN RC

/* Create dynamic panel for data entry */
CREATE_DYNAMIC_PANEL: PROCEDURE EXPOSE COL_INFO. COL_COUNT SCHEMA TABLENAME
   PARSE ARG PANEL_NAME
   
   /* Generate panel source dynamically */
   PANEL_SOURCE = ""
   
   /* Panel header */
   PANEL_SOURCE = PANEL_SOURCE || ")ATTR DEFAULT(%+_)" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || "  + TYPE(TEXT) INTENS(LOW) COLOR(GREEN)" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || "  _ TYPE(INPUT) INTENS(HIGH) CAPS(OFF) COLOR(TURQ)" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || "  % TYPE(TEXT) INTENS(HIGH) COLOR(WHITE)" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || "  @ TYPE(TEXT) INTENS(HIGH) COLOR(YELLOW)" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || ")BODY EXPAND(||)" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || "%----------------------  DYNAMIC DATA ENTRY  ----------------------" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || "%COMMAND ===>_ZCMD" || COPIES(" ", 50) || "+" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || "+" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || "@Table: " || SCHEMA || "." || TABLENAME || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || "+" || "0A"X
   
   /* Generate field entries */
   LINE_COUNT = 0
   DO I = 1 TO COL_COUNT
      COL_NAME = COL_INFO.I.COL_NAME
      ISPF_NAME = COL_INFO.I.ISPF_NAME  
      COL_TYPE = COL_INFO.I.COL_TYPE
      COL_LENGTH = COL_INFO.I.COL_LENGTH
      NULLS = COL_INFO.I.NULLS
      
      /* Format column display */
      DISPLAY_NAME = LEFT(COL_NAME, 20)
      TYPE_INFO = "(" || COL_TYPE
      IF COL_LENGTH <> "" THEN
         TYPE_INFO = TYPE_INFO || "," || COL_LENGTH
      TYPE_INFO = TYPE_INFO || ")"
      IF NULLS = "Y" THEN
         TYPE_INFO = TYPE_INFO || " NULL"
      
      PANEL_SOURCE = PANEL_SOURCE || "+" || DISPLAY_NAME || " " || LEFT(TYPE_INFO, 15)
      PANEL_SOURCE = PANEL_SOURCE || "_" || ISPF_NAME || COPIES(" ", 30) || "+" || "0A"X
      
      LINE_COUNT = LINE_COUNT + 1
      IF LINE_COUNT // 15 = 0 THEN DO
         /* Add scroll indicators */
         PANEL_SOURCE = PANEL_SOURCE || "+" || "0A"X
         PANEL_SOURCE = PANEL_SOURCE || "+More fields below - use PF8 to scroll down" || "0A"X
      END
   END
   
   /* Panel footer */
   PANEL_SOURCE = PANEL_SOURCE || "+" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || "%Press ENTER when done or PF3 to exit" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || ")INIT" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || ")PROC" || "0A"X
   PANEL_SOURCE = PANEL_SOURCE || ")END" || "0A"X
   
   /* Write panel to temporary dataset */
   TEMP_DSN = "USERID.TEMP.PANELS(" || PANEL_NAME || ")"
   
   ADDRESS TSO
   "ALLOC F(PANELOUT) DA('" || TEMP_DSN || "') NEW UNIT(VIO) SPACE(1,1) TRACKS"
   "EXECIO * DISKW PANELOUT (STEM PANEL_SOURCE. FINIS)"
   "FREE F(PANELOUT)"
   
   /* Add to ISPF panel library */
   ADDRESS ISPEXEC "LIBDEF ISPPLIB DATASET ID('" || TEMP_DSN || "') STACK"
   
RETURN 0

/* Populate column information structure */
POPULATE_COLUMN_INFO: PROCEDURE EXPOSE COL_INFO. COL_COUNT ABBREV_LIST.
   PARSE ARG CURSOR_NAME
   
   COL_COUNT = 0
   
   ADDRESS DSNREXX
   DO WHILE SQLCODE = 0
      "EXECSQL FETCH" CURSOR_NAME "INTO :COLNAME, :COLTYPE, :LENGTH, :SCALE, :NULLS"
      IF SQLCODE = 0 THEN DO
         COL_COUNT = COL_COUNT + 1
         
         /* Store original column information */
         COL_INFO.COL_COUNT.COL_NAME = COLNAME
         COL_INFO.COL_COUNT.COL_TYPE = COLTYPE  
         COL_INFO.COL_COUNT.COL_LENGTH = LENGTH
         COL_INFO.COL_COUNT.SCALE = SCALE
         COL_INFO.COL_COUNT.NULLS = NULLS
         
         /* Create ISPF-compatible name */
         COL_INFO.COL_COUNT.ISPF_NAME = CREATE_SMART_ABBREV(COLNAME, COL_COUNT)
         
         /* Determine if this is likely a key column */
         COL_INFO.COL_COUNT.IS_KEY = "N"
         IF POS("ID", UPPER(COLNAME)) > 0 | POS("KEY", UPPER(COLNAME)) > 0 THEN
            COL_INFO.COL_COUNT.IS_KEY = "Y"
      END
   END
   ADDRESS ISPEXEC
   
RETURN COL_COUNT

/* Handle ISPF table scrolling */
HANDLE_TABLE_SCROLL: PROCEDURE
   PARSE ARG TABLE_NAME, SCROLL_CMD, DISPLAY_LINES
   
   ADDRESS ISPEXEC
   SELECT
      WHEN SCROLL_CMD = "UP" | SCROLL_CMD = "U" THEN DO
         "TBSKIP" TABLE_NAME "NUMBER(-" || DISPLAY_LINES || ")"
      END
      WHEN SCROLL_CMD = "DOWN" | SCROLL_CMD = "D" THEN DO
         "TBSKIP" TABLE_NAME "NUMBER(" || DISPLAY_LINES || ")"
      END
      WHEN SCROLL_CMD = "TOP" | SCROLL_CMD = "T" THEN DO
         "TBTOP" TABLE_NAME
      END
      WHEN SCROLL_CMD = "BOTTOM" | SCROLL_CMD = "B" THEN DO
         "TBBOTTOM" TABLE_NAME
      END
   END
   
RETURN RC

/* Export ISPF table to dataset */
EXPORT_TABLE: PROCEDURE
   PARSE ARG TABLE_NAME, OUTPUT_DSN
   
   ADDRESS ISPEXEC
   "TBOPEN" TABLE_NAME
   "TBTOP" TABLE_NAME
   
   /* Write header */
   HEADER_LINE = ""
   /* Build header from table structure */
   
   OUTPUT_LINES = ""
   LINE_COUNT = 0
   
   DO WHILE RC = 0
      "TBSKIP" TABLE_NAME
      IF RC = 0 THEN DO
         LINE_COUNT = LINE_COUNT + 1
         /* Format output line */
         OUTPUT_LINE = /* Format based on column values */
         OUTPUT_LINES = OUTPUT_LINES || OUTPUT_LINE || "0A"X
      END
   END
   
   /* Write to dataset */
   ADDRESS TSO
   "ALLOC F(EXPORT) DA('" || OUTPUT_DSN || "') NEW UNIT(SYSDA) SPACE(5,5) TRACKS"
   "EXECIO * DISKW EXPORT (STEM OUTPUT_LINES. FINIS)"
   "FREE F(EXPORT)"
   
   ADDRESS ISPEXEC "TBCLOSE" TABLE_NAME
   
RETURN LINE_COUNT
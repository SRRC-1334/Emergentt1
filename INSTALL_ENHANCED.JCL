//INSTALL  JOB CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//         NOTIFY=&SYSUID
//*
//* Enhanced Installation JCL for DB2 CRUD Operations Tool
//* This job creates all necessary datasets and installs the complete system
//*
//********************************************************************
//* Step 1: Create REXX Execution Library
//********************************************************************
//CREATEEX EXEC PGM=IEFBR14
//REXXLIB  DD DSN=&SYSUID..DB2CRUD.EXEC,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(TRK,(20,10,15)),
//         DCB=(RECFM=FB,LRECL=80,BLKSIZE=6160)
//*
//********************************************************************
//* Step 2: Create ISPF Panel Library  
//********************************************************************
//CREATEPN EXEC PGM=IEFBR14
//PANLIB   DD DSN=&SYSUID..DB2CRUD.PANELS,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(TRK,(15,5,20)),
//         DCB=(RECFM=FB,LRECL=80,BLKSIZE=6160)
//*
//********************************************************************
//* Step 3: Create User Query History Library (PDS)
//********************************************************************
//CREATEQH EXEC PGM=IEFBR14
//QRYLIB   DD DSN=&SYSUID..DB2CRUD.USERQRY,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(TRK,(10,5,50)),
//         DCB=(RECFM=FB,LRECL=80,BLKSIZE=6160)
//*
//********************************************************************
//* Step 4: Create Settings Dataset
//********************************************************************
//CREATEST EXEC PGM=IEFBR14
//SETTINGS DD DSN=&SYSUID..DB2CRUD.SETTINGS,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(TRK,(1,1)),
//         DCB=(RECFM=FB,LRECL=80,BLKSIZE=6160)
//*
//********************************************************************
//* Step 5: Create Export Work Dataset
//********************************************************************
//CREATEEX EXEC PGM=IEFBR14
//EXPORT   DD DSN=&SYSUID..DB2CRUD.EXPORT,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(5,2)),
//         DCB=(RECFM=VB,LRECL=32756,BLKSIZE=32760)
//*
//********************************************************************
//* Step 6: Initialize Settings with Defaults
//********************************************************************
//INITSET  EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
ALLOC F(SETTINGS) DA('&SYSUID..DB2CRUD.SETTINGS') NEW DELETE UNIT(SYSDA) SP(1,1)
EXECIO * DISKW SETTINGS (STEM SETTING.
MAX_ROWS=200
DEEP_LOG=N
EXPORT_DELIM=;
/*
FREE F(SETTINGS)
/*
//SETTING. DD *
MAX_ROWS=200
DEEP_LOG=N
EXPORT_DELIM=;
/*
//********************************************************************
//* Step 7: Copy REXX Programs
//********************************************************************
//COPYREXX EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.REXX(DB2CRUD),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.EXEC(DB2CRUD),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYUTIL EXEC PGM=IEBGENER  
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.REXX(DB2UTILS),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.EXEC(DB2UTILS),DISP=SHR
//SYSIN    DD DUMMY
//*
//********************************************************************
//* Step 8: Copy All ISPF Panels
//********************************************************************
//COPYMAIN EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2MAIN),DISP=SHR  
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2MAIN),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYCRT  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2CREATE),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2CREATE),DISP=SHR  
//SYSIN    DD DUMMY
//*
//COPYWHR  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2WHERE),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2WHERE),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYEDT  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2EDIT),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2EDIT),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYPROG EXEC PGM=IEBGENER  
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2PROGRESS),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2PROGRESS),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYRSLT EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2RESULT),DISP=SHR  
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2RESULT),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYHIST EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2HISTORY),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2HISTORY),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYSET  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2SETTINGS),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2SETTINGS),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYERR  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2ERROR),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2ERROR),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYHLP1 EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2HELP1),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2HELP1),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYHLP2 EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2HELP2),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2HELP2),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYHLP3 EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2HELP3),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2HELP3),DISP=SHR
//SYSIN    DD DUMMY
//*
//********************************************************************
//* Step 9: Create CLIST for Easy Execution
//********************************************************************
//CREATECL EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD *
PROC 0
/* DB2CRUD Startup CLIST */
ALLOC F(SYSPROC) DA('&SYSUID..DB2CRUD.EXEC') SHR REUSE
ALLOC F(ISPPLIB) DA('&SYSUID..DB2CRUD.PANELS') SHR REUSE
ISPEXEC SELECT CMD(%DB2CRUD)
FREE F(SYSPROC ISPPLIB)
/*
//SYSUT2   DD DSN=&SYSUID..CLIST(DB2CRUD),DISP=SHR
//SYSIN    DD DUMMY
//*
//********************************************************************
//* Step 10: Create Sample Test Table and Data
//********************************************************************  
//TESTDATA EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
DSN SYSTEM(DB2T)
RUN PROGRAM(DSNTEP2) PLAN(DSNTEP2) -
LIB('SYS1.DSNTEP2')
//SYSIN    DD *
-- Create comprehensive test table for DB2CRUD
CREATE TABLE &SYSUID..EMPLOYEE (
    EMP_ID INTEGER NOT NULL PRIMARY KEY,
    FIRST_NAME VARCHAR(30) NOT NULL,
    LAST_NAME VARCHAR(30) NOT NULL, 
    EMAIL VARCHAR(50),
    HIRE_DATE DATE,
    SALARY DECIMAL(10,2),
    DEPT_CODE CHAR(3),
    ACTIVE_FLAG CHAR(1) DEFAULT 'Y',
    LAST_UPDATED TIMESTAMP DEFAULT CURRENT TIMESTAMP,
    BIRTH_DATE DATE,
    PHONE VARCHAR(15),
    ADDRESS VARCHAR(100),
    CITY VARCHAR(30),
    STATE CHAR(2),
    ZIP_CODE CHAR(10)
);

-- Create index for testing
CREATE INDEX IX_EMPLOYEE_DEPT ON &SYSUID..EMPLOYEE (DEPT_CODE);
CREATE INDEX IX_EMPLOYEE_NAME ON &SYSUID..EMPLOYEE (LAST_NAME, FIRST_NAME);

-- Insert comprehensive test data
INSERT INTO &SYSUID..EMPLOYEE VALUES 
(1, 'JOHN', 'SMITH', 'JOHN.SMITH@COMPANY.COM', '2020-01-15', 50000.00, 
 'IT', 'Y', CURRENT TIMESTAMP, '1985-05-20', '555-1234', 
 '123 MAIN ST', 'NEW YORK', 'NY', '10001'),
(2, 'JANE', 'DOE', 'JANE.DOE@COMPANY.COM', '2019-03-20', 55000.00,
 'HR', 'Y', CURRENT TIMESTAMP, '1987-08-15', '555-5678',
 '456 ELM ST', 'CHICAGO', 'IL', '60601'),
(3, 'BOB', 'JOHNSON', 'BOB.J@COMPANY.COM', '2021-07-10', 48000.00,
 'IT', 'Y', CURRENT TIMESTAMP, '1990-12-03', '555-9012',
 '789 OAK ST', 'LOS ANGELES', 'CA', '90210'),
(4, 'SARAH', 'WILLIAMS', 'S.WILLIAMS@COMPANY.COM', '2018-11-05', 62000.00,
 'FIN', 'Y', CURRENT TIMESTAMP, '1983-04-25', '555-3456',
 '321 PINE ST', 'HOUSTON', 'TX', '77001'),
(5, 'MIKE', 'BROWN', 'M.BROWN@COMPANY.COM', '2022-02-28', 45000.00,
 'MKT', 'Y', CURRENT TIMESTAMP, '1992-09-18', '555-7890',
 '654 CEDAR ST', 'PHOENIX', 'AZ', '85001');

-- Grant necessary privileges
GRANT ALL ON &SYSUID..EMPLOYEE TO PUBLIC;

COMMIT;
/*
//
//********************************************************************
//* Step 11: Final Setup Instructions
//********************************************************************
//SETUP    EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD *
DB2CRUD Installation Complete!

To use DB2CRUD:

1. From TSO: Execute CLIST DB2CRUD
   Command: EX '&SYSUID..CLIST(DB2CRUD)'

2. Or manually:
   ALLOC F(SYSPROC) DA('&SYSUID..DB2CRUD.EXEC') SHR REUSE
   ALLOC F(ISPPLIB) DA('&SYSUID..DB2CRUD.PANELS') SHR REUSE
   ISPEXEC SELECT CMD(%DB2CRUD)

3. Test with sample table:
   Schema: &SYSUID
   Table: EMPLOYEE
   SSID: DB2T (or your DB2 subsystem)

4. Dataset locations:
   Programs: &SYSUID..DB2CRUD.EXEC
   Panels: &SYSUID..DB2CRUD.PANELS  
   Query History: &SYSUID..DB2CRUD.USERQRY
   Settings: &SYSUID..DB2CRUD.SETTINGS
   Logs: &SYSUID..DB2CRUD.LOG.Dddmmyy
   Exports: &SYSUID..DB2CRUD.EXPORT

For help, press PF1 in any panel or see member HELP in EXEC library.

Installation successful - Ready to use!
/*
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.INSTALL.LOG,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(TRK,(1,1)),
//         DCB=(RECFM=FB,LRECL=80,BLKSIZE=6160)
//SYSIN    DD DUMMY
//
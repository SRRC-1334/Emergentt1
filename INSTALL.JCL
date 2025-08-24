//INSTALL  JOB CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//         NOTIFY=&SYSUID
//*
//* Installation JCL for DB2 CRUD Operations Tool
//* This job will create the necessary datasets and copy the
//* REXX programs and ISPF panels to the appropriate libraries
//*
//********************************************************************
//* Step 1: Create REXX Execution Library
//********************************************************************
//CREATEEX EXEC PGM=IEFBR14
//REXXLIB  DD DSN=&SYSUID..DB2CRUD.EXEC,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(TRK,(10,5,10)),
//         DCB=(RECFM=FB,LRECL=80,BLKSIZE=6160)
//*
//********************************************************************
//* Step 2: Create ISPF Panel Library  
//********************************************************************
//CREATEPN EXEC PGM=IEFBR14
//PANLIB   DD DSN=&SYSUID..DB2CRUD.PANELS,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(TRK,(5,2,10)),
//         DCB=(RECFM=FB,LRECL=80,BLKSIZE=6160)
//*
//********************************************************************
//* Step 3: Copy REXX Programs
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
//COPYTABL EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*  
//SYSUT1   DD DSN=&SYSUID..SOURCE.REXX(DB2TABLE),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.EXEC(DB2TABLE),DISP=SHR
//SYSIN    DD DUMMY
//*
//********************************************************************
//* Step 4: Copy ISPF Panels
//********************************************************************
//COPYMAIN EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2MAIN),DISP=SHR  
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2MAIN),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYENTR EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2ENTRY),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2ENTRY),DISP=SHR  
//SYSIN    DD DUMMY
//*
//COPYOPER EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2OPER),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2OPER),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYCONF EXEC PGM=IEBGENER  
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2CONF),DISP=SHR
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2CONF),DISP=SHR
//SYSIN    DD DUMMY
//*
//COPYRSLT EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SYSUID..SOURCE.PANELS(DB2RSLT),DISP=SHR  
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.PANELS(DB2RSLT),DISP=SHR
//SYSIN    DD DUMMY
//*
//********************************************************************
//* Step 5: Set up LOGON PROC additions (optional)
//********************************************************************
//SETUP    EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD *
/* Add these lines to your TSO LOGON PROC or ISPF startup */
ALLOC F(SYSPROC) DA('&SYSUID..DB2CRUD.EXEC') SHR REUSE
ALLOC F(ISPPLIB) DA('&SYSUID..DB2CRUD.PANELS') SHR REUSE  
/*
//SYSUT2   DD DSN=&SYSUID..DB2CRUD.SETUP,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA, 
//         SPACE=(TRK,(1,1)),
//         DCB=(RECFM=FB,LRECL=80,BLKSIZE=6160)
//SYSIN    DD DUMMY
//*
//********************************************************************
//* Step 6: Create Sample Test Data (optional)
//********************************************************************  
//TESTDATA EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
DSN SYSTEM(DB2T)
RUN PROGRAM(DSNTEP2) PLAN(DSNTEP2) -
LIB('SYS1.DSNTEP2')
//SYSIN    DD *
-- Create sample test table for DB2CRUD tool
CREATE TABLE TESTUSER.EMPLOYEE (
    EMP_ID INTEGER NOT NULL PRIMARY KEY,
    FIRST_NAME VARCHAR(30) NOT NULL,
    LAST_NAME VARCHAR(30) NOT NULL, 
    EMAIL VARCHAR(50),
    HIRE_DATE DATE,
    SALARY DECIMAL(10,2),
    DEPT_CODE CHAR(3)
);

-- Insert sample data
INSERT INTO TESTUSER.EMPLOYEE VALUES 
(1, 'JOHN', 'SMITH', 'JOHN.SMITH@COMPANY.COM', '2020-01-15', 50000.00, 'IT'),
(2, 'JANE', 'DOE', 'JANE.DOE@COMPANY.COM', '2019-03-20', 55000.00, 'HR'),
(3, 'BOB', 'JOHNSON', 'BOB.J@COMPANY.COM', '2021-07-10', 48000.00, 'IT');

COMMIT;
/*
//
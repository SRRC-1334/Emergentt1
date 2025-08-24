# DB2 CRUD Operations Tool for Mainframe

## Overview
This is a comprehensive DB2 CRUD (Create, Read, Update, Delete) operations tool designed to run on IBM mainframes using REXX and ISPF tables. The tool provides a user-friendly interface for performing database operations without requiring detailed SQL knowledge.

## Components

### 1. Main Program
- **DB2CRUD.REXX** - Main REXX program that orchestrates the entire application

### 2. ISPF Panels
- **DB2MAIN.PANEL** - Initial input panel for DB2 connection details
- **DB2ENTRY.PANEL** - Dynamic data entry interface
- **DB2OPER.PANEL** - CRUD operation selection
- **DB2CONF.PANEL** - SQL statement confirmation
- **DB2RSLT.PANEL** - Results display

### 3. Utility Modules
- **DB2UTILS.REXX** - Utility functions for data formatting and validation
- **DB2TABLE.REXX** - Dynamic ISPF table management routines

## Features

### Dynamic Table Structure Discovery
- Automatically queries DB2 SYSCOLUMNS to get table structure
- Creates temporary ISPF tables based on the actual DB2 table
- Handles ISPF 8-character column name limitation with intelligent abbreviation

### Column Name Mapping
- Maps long DB2 column names to ISPF-compatible 8-character names
- Uses multiple strategies: abbreviation, vowel removal, acronym creation
- Prevents naming collisions with smart algorithms

### Data Type Support
- Handles all common DB2 data types (CHAR, VARCHAR, INTEGER, DECIMAL, DATE, TIME, TIMESTAMP)
- Provides appropriate validation for each data type
- Formats values correctly for SQL statement generation

### CRUD Operations
- **CREATE (INSERT)**: Add new records to the table
- **READ (SELECT)**: Query and retrieve records with WHERE conditions
- **UPDATE**: Modify existing records based on key fields
- **DELETE**: Remove records with confirmation

### User Interface
- Intuitive ISPF panel-based interface
- Color-coded fields and error messages
- Comprehensive help and instructions
- Scroll support for large result sets

## Installation Instructions

### Prerequisites
1. IBM mainframe with TSO/ISPF
2. DB2 subsystem access
3. REXX interpreter
4. Appropriate DB2 privileges for target tables

### Installation Steps

1. **Upload Files**
   ```
   Upload all .REXX files to your REXX library (typically USER.REXX.EXEC)
   Upload all .PANEL files to your ISPF panel library (typically USER.ISPF.PANELS)
   ```

2. **Set Library Allocations**
   ```
   ALLOC F(SYSPROC) DA('USER.REXX.EXEC') SHR REUSE
   ALLOC F(ISPPLIB) DA('USER.ISPF.PANELS') SHR REUSE
   ```

3. **Verify DB2 Access**
   - Ensure you have access to the target DB2 subsystem
   - Verify SELECT privilege on SYSIBM.SYSCOLUMNS
   - Confirm appropriate privileges on target tables

## Usage Instructions

### Starting the Application
1. From TSO/ISPF command line: `EX 'USER.REXX.EXEC(DB2CRUD)'`
2. Or from ISPF: `TSO EX 'USER.REXX.EXEC(DB2CRUD)'`

### Basic Workflow
1. **Initial Setup**
   - Enter DB2 SSID (4-character subsystem ID)
   - Specify schema (table owner)
   - Enter table name
   - Press ENTER to continue

2. **Data Entry**
   - System displays all columns from the specified table
   - Enter values for columns you want to use
   - Use NULL for null values
   - Press ENTER when complete

3. **Operation Selection**
   - Choose C (CREATE), R (READ), U (UPDATE), or D (DELETE)
   - Press ENTER to generate SQL

4. **SQL Confirmation**
   - Review the generated SQL statement
   - Enter Y to execute or N to modify
   - Press ENTER to proceed

5. **View Results**
   - For SELECT operations, data is displayed
   - For other operations, success/failure status shown
   - Press ENTER for new operation or PF3 to exit

## Advanced Features

### Column Name Abbreviation Logic
The system uses intelligent algorithms to create 8-character ISPF column names:
1. **Direct mapping**: Use original name if 8 characters or less
2. **Truncation**: First 6 characters + sequence number
3. **Vowel removal**: Remove vowels to create shorter names
4. **Acronym creation**: First letter of each word

### Error Handling
- Comprehensive DB2 SQLCODE interpretation
- User-friendly error messages
- Input validation with specific error descriptions
- Rollback capability for failed operations

### Performance Considerations
- Efficient cursor handling for large result sets
- Pagination support for displaying results
- Optimized ISPF table operations
- Memory management for large tables

## Customization Options

### Modifying Panel Layouts
Edit the .PANEL files to customize:
- Color schemes
- Field positions
- Help text
- Validation rules

### Adding New Data Types
Extend DB2UTILS.REXX to support additional data types:
- Add new cases to FORMAT_VALUE function
- Update VALIDATE_VALUE function
- Modify panel generation logic

### Enhancing SQL Generation
Modify DB2CRUD.REXX to add:
- Complex WHERE clauses
- JOIN operations
- Subqueries
- Aggregate functions

## Troubleshooting

### Common Issues
1. **Panel not found**: Check ISPPLIB allocation
2. **REXX not found**: Verify SYSPROC allocation  
3. **DB2 connection fails**: Confirm SSID and privileges
4. **Table not found**: Check schema and table name spelling

### Debug Mode
Add `TRACE I` at the beginning of DB2CRUD.REXX for detailed execution tracing.

### Log Files
Check these logs for detailed error information:
- TSO session log
- DB2 message log
- ISPF log (if enabled)

## Security Considerations
- Uses existing TSO/DB2 security model
- No passwords stored in code
- Relies on user's DB2 privileges
- SQL injection prevention through parameter validation

## Performance Tips
- Use specific column names in SELECT operations
- Add WHERE clauses to limit result sets
- Consider indexing on frequently queried columns
- Monitor DB2 performance statistics

## Support and Maintenance
- Regular backup of REXX and panel libraries
- Monitor DB2 SYSCOLUMNS for table structure changes
- Update column mapping logic as needed
- Test with new DB2 versions before migration

## Version History
- v1.0 - Initial release with basic CRUD operations
- Future versions may include batch operations, advanced SQL features, and enhanced UI

## Contact Information
For technical support or enhancement requests, contact your mainframe systems team.
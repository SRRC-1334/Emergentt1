# DB2 CRUD Operations Tool - Complete Enhanced Version

## 🚀 Overview
This is a comprehensive, enterprise-grade DB2 CRUD (Create, Read, Update, Delete) operations tool designed for IBM mainframes using REXX and ISPF tables. The tool provides an intuitive, user-friendly interface for performing complex database operations without requiring detailed SQL knowledge.

## ✨ Key Features

### 🎯 **Streamlined Interface**
- **Single Main Screen**: All inputs (Schema, SSID, Table, CRUD) on one screen
- **Options Menu**: Query History, Settings, Exit - all accessible from main screen
- **Smart Validation**: Context-aware field validation based on selected option
- **Command Line Support**: Full ISPF command line functionality

### 🔄 **Advanced CRUD Operations**

#### **CREATE (Insert)**
- Dynamic column discovery from DB2 SYSCOLUMNS
- Intelligent data type handling and validation
- Pre-filled default values (current date/timestamp)
- Index columns highlighted in yellow/bold
- Column mapping: Long DB2 names → ISPF-compatible C0001, C0002 format

#### **READ (Select)**
- Interactive WHERE condition builder
- Line command 'S' to select columns for conditions
- Multiple operator support: =, <>, <, >, <=, >=, LIKE, BETWEEN, IN, IS NULL
- Logic operators: AND, OR for complex conditions
- Configurable row limits (200-500)
- Export to CSV with email capability

#### **UPDATE**
- WHERE condition selection like READ
- Separate value entry for UPDATE SET clause
- Row count preview before execution
- Transaction control with rollback capability

#### **DELETE**
- WHERE condition selection for targeted deletions
- Row count preview with confirmation
- Safety checks to prevent accidental full table deletes

### 🛠️ **Advanced Features**

#### **SQL Editing**
- **Generated SQL Preview**: Shows system-generated SQL
- **Full SQL Editor**: Complete SQL modification capability
- **Syntax Highlighting**: User-friendly editing interface
- **Complex Query Support**: JOINs, subqueries, advanced WHERE clauses

#### **Query History Management**
- **Automatic Saving**: All queries saved to USER.DB2CRUD.USERQRY(CRUDddmmyysno)
- **Smart Naming**: C/R/U/D + date + sequence number (e.g., S2408251)
- **Browse & Rerun**: Select saved queries with 'S' line command
- **Edit Before Rerun**: Modify saved queries before execution

#### **Progress Tracking**
- **Visual Progress Bar**: ######### 50% completion display
- **Step-by-Step Status**: "Connecting to DB2", "Reading structure", etc.
- **Real-time Updates**: Progress updates during long operations

#### **Comprehensive Logging**
- **Daily Log Files**: USER.DB2CRUD.LOG.Dddmmyy format
- **Timestamp Format**: YYYY-MM-DD HH:MM:SS.mmm precision
- **Deep Logging Option**: Detailed SQL and operation logging
- **Session Tracking**: Complete audit trail of all operations

#### **Export & Email**
- **CSV Export**: Configurable delimiter (default semicolon)
- **Email Integration**: JCL generation for mainframe email systems
- **Large Dataset Support**: No row limits for exports
- **Custom Formatting**: User-defined export parameters

#### **Error Handling**
- **SQLCODE Interpretation**: User-friendly error messages
- **Suggested Solutions**: Context-aware fix recommendations
- **Comprehensive Coverage**: All common DB2 error scenarios
- **Error Panel**: Dedicated error display with help text

### ⚙️ **Configuration & Settings**
- **Maximum Rows**: 200-500 configurable limit
- **Deep Logging**: Toggle detailed vs basic logging
- **Export Delimiter**: Customizable CSV field separator
- **Persistent Settings**: Saved to USER.DB2CRUD.SETTINGS

## 📁 **File Structure**

### **REXX Programs**
```
DB2CRUD.REXX        - Main orchestration program
DB2UTILS.REXX       - Utility functions and SQL builders
```

### **ISPF Panels**
```
DB2MAIN.PANEL       - Main input screen with options
DB2CREATE.PANEL     - CREATE operation data entry (dynamic)
DB2WHERE.PANEL      - WHERE condition builder (dynamic)
DB2ASKEDIT.PANEL    - SQL edit confirmation
DB2EDIT.PANEL       - SQL editor with full modification
DB2ASKEXEC.PANEL    - Execution confirmation
DB2CONFIRM.PANEL    - Final commit confirmation with row count
DB2PROGRESS.PANEL   - Progress bar with status updates
DB2RESULT.PANEL     - Results display with export options
DB2HISTORY.PANEL    - Query history browser
DB2SETTINGS.PANEL   - Configuration settings
DB2ERROR.PANEL      - Error display with suggestions
DB2HELP1.PANEL      - Help system page 1
DB2HELP2.PANEL      - Help system page 2
DB2HELP3.PANEL      - Help system page 3
```

### **Installation & Documentation**
```
INSTALL_ENHANCED.JCL    - Complete installation JCL
README_COMPLETE.md      - This comprehensive documentation
```

## 🔧 **Technical Architecture**

### **Column Mapping Strategy**
- **Internal Names**: C0001, C0002, C0003... (ISPF 8-char limit)
- **Display Names**: Original DB2 column names shown to user
- **Index Highlighting**: Primary key and index columns in yellow/bold
- **Type Validation**: Data type-specific input validation

### **Database Connectivity**
- **Dynamic Connection**: Connect to any DB2 subsystem by SSID
- **SYSCOLUMNS Integration**: Real-time table structure discovery
- **SYSINDEXES Querying**: Automatic index column identification
- **Transaction Control**: Proper commit/rollback handling

### **Memory Management**
- **ISPF Table Services**: Efficient table management
- **Dynamic Panel Generation**: Runtime panel creation based on table structure
- **Cursor Management**: Proper DB2 cursor handling
- **Resource Cleanup**: Automatic resource deallocation

## 📋 **Installation Instructions**

### **Prerequisites**
- IBM Mainframe with TSO/ISPF
- DB2 subsystem access with appropriate privileges
- REXX interpreter availability
- Sufficient disk space for datasets

### **Installation Steps**

1. **Upload Files**
   ```
   Upload DB2CRUD.REXX and DB2UTILS.REXX to your REXX library
   Upload all .PANEL files to your ISPF panel library
   ```

2. **Run Installation JCL**
   ```
   Submit INSTALL_ENHANCED.JCL
   Review job output for successful completion
   ```

3. **Verify Setup**
   ```
   Check created datasets:
   - USER.DB2CRUD.EXEC (REXX programs)
   - USER.DB2CRUD.PANELS (ISPF panels)
   - USER.DB2CRUD.USERQRY (Query history)
   - USER.DB2CRUD.SETTINGS (Configuration)
   ```

4. **Test Installation**
   ```
   Execute: EX 'USER.CLIST(DB2CRUD)'
   Or manually: ISPEXEC SELECT CMD(%DB2CRUD)
   ```

## 🎮 **Usage Guide**

### **Starting the Application**
1. From TSO command line: `EX 'USER.CLIST(DB2CRUD)'`
2. Or from ISPF: `ISPEXEC SELECT CMD(%DB2CRUD)`

### **Main Screen Operation**
1. **For New Query**: Fill Schema, SSID, Table Name, CRUD → Press ENTER
2. **For Query History**: Fill SSID only → Enter "1" → Press ENTER
3. **For Settings**: Enter "2" → Press ENTER
4. **To Exit**: Enter "3" → Press ENTER

### **CRUD Operation Flow**
```
Main Screen → Data Entry → SQL Edit (optional) → Execute Confirm → 
Row Count Preview → Final Confirmation → Progress → Results → Save Query
```

### **WHERE Condition Building**
1. Put 'S' in Line Cmd column for desired columns
2. Enter Value, Operator (=, LIKE, BETWEEN, etc.)
3. Specify Logic (AND, OR) for multiple conditions
4. Press ENTER to generate SQL

### **Query History Usage**
1. Select option "1" from main screen
2. Browse saved queries by date and operation
3. Put 'S' to select query for editing/rerunning
4. Modify if needed, then execute

## 🔍 **Advanced Features**

### **Complex SQL Support**
- Full SQL editing capability before execution
- Support for JOINs, subqueries, functions
- Custom WHERE clause construction
- Advanced DB2 SQL features

### **Export Capabilities**
- CSV format with configurable delimiters
- Email integration via JCL generation
- Large dataset export (no row limits)
- Custom export formatting options

### **Monitoring & Logging**
- Complete operation audit trail
- Performance monitoring
- Error tracking and analysis
- Session management logging

## 🛡️ **Security Features**
- Uses existing TSO/DB2 security model
- No embedded passwords or credentials
- Privilege-based access control
- SQL injection prevention through parameterization
- Transaction isolation and rollback capability

## 🚨 **Error Handling**
- Comprehensive SQLCODE interpretation
- Context-aware error messages
- Suggested solution recommendations
- Recovery procedures for common issues
- Automatic rollback on errors

## 📊 **Performance Considerations**
- Efficient ISPF table management
- Optimized DB2 cursor handling
- Configurable result set limits
- Memory-conscious design
- Resource cleanup automation

## 🔄 **Maintenance**
- Regular log file cleanup
- Query history management
- Settings backup and restore
- Performance monitoring
- Version control integration

## 📞 **Support Information**
- Comprehensive help system (PF1 in any panel)
- Error message interpretation
- Common solution database
- Contact information for technical support

## 🎯 **Version Information**
- **Version**: Enhanced 2.0
- **Release Date**: 2025
- **Compatibility**: DB2 v9+ on z/OS
- **REXX Level**: Standard REXX with ISPF extensions

This tool represents a complete, enterprise-ready solution for DB2 database operations on mainframe systems, combining ease of use with powerful functionality and comprehensive error handling.
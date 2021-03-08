# RPGProcDoc
A Documentation Tool for modern RPG development on IBM i. Find all your already created Procedures and use them again and again.

### Components/Souce Members 

* QSQLSRC : RPGPROCDOC.SQL - SQL Create Script for Procedure Documentation table RPGPROCDOC
* QRPGLESRC : RPGPROCDOC.SQLRPGLE - The build program that scans and publish the Procedure Documentation both in a Db2 Table and as a JSON file
* QRPGLESRC : XXXPROCDOC - Template Program to Start the Build of your Procedure Documentation
* QCMDSRC : XXXPROCDOC - Template Command to Start the Build of your Procedure Documentation
* QPROTSRC : NLGMSG_PT and NLGCVL_PT - Example Prototypes that are used by the Template Start Build program

**Note** : You also need a Web UI to search and view the documentation. Contact me so that I can provide you with one :-)

### How to install

1. Create library RPGPROCDOC - **CRTLIB LIB(RPGPROCDOC) TEXT('RPG Procedure Documentation')**
2. Create the QSQLSRC Source File - **CRTSRCPF FILE(RPGPROCDOC/QSQLRC) RCDLEN(256) TEXT('SQL Script')**
3. Create the QRPGLESRC Source File - **CRTSRCPF FILE(RPGPROCDOC/QRPGLESRC) RCDLEN(256) TEXT('RPG ILE Source')**
4. Create the QCMDSRC Source File - **CRTSRCPF FILE(RPGPROCDOC/QCMDSRC) RCDLEN(92) TEXT('Command Source')**
5. Create the QPROTSRC Source File - **CRTSRCPF FILE(RPGPROCDOC/QPROTSRC) RCDLEN(256) TEXT('Prototype Source')**
6. Create and copy the corresponding source members according to the list above
7. Run the SQL Script for the RPGPROCDOC table and compile the programs

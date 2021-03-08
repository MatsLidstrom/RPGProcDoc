# RPGProcDoc
A Documentation Tool for modern RPG development on IBM i. Find all your already created Procedures and use them again and again.

<img width="960" alt="RPGProcDoc UI" src="https://user-images.githubusercontent.com/44493349/110350692-46d5bf00-8034-11eb-9bdf-273fb79480cc.png">


**Note** : The Web UI to Search and View the Documentation is not include here. Contact me to get a copy of it :-)


## The Build Part

By writing a structured documentation per procedure prototype, the RPGProcDoc tool can scan and capture the documentation. This both in a Db2 table and as a JSON file.

### Example:

```
//----------------------------------------------------------------------
//  @Procedure_Name        : send_Message
//  @Procedure_Description : Sends a message to the memory that later can be picked up by the requester by using the receive_Messages procedure
//  @Procedure_Source      : QRPGLESRC,NLGMSG_PR
//  @Procedure_Prototype   : /include QPROTSRC,NLGMSG_PT
//  @Procedure_Input       : p_Message
//  @Procedure_Output      : *none
//  @Procedure_Example     : p_ID      = 'Field ID' ;
//  @Procedure_Example     : p_Message = 'Message text' ;
//  @Procedure_Example     : send_Message(p_Message) ;
//----------------------------------------------------------------------
dcl-PR send_Message ;
       ID           like(T_Messages.ID)      const ;
       Message      like(T_Messages.Message) const ;
end-PR ;
```
### Tags

**Note** : The tag @Procedure_Name is madatory. The tags @Procedure_Source and @Procedure_Prototype are used as filter options in the Web UI.

New tags can be added as needed and should be structured as in the example.

### Components/Source Members 

* QSQLSRC : RPGPROCDOC.sql - SQL Create Script for Procedure Documentation table RPGPROCDOC
* QRPGLESRC : RPGPROCDOC.sqlrpgle - The build program that scans and publish the Procedure Documentation both in a Db2 Table and as a JSON file
* QRPGLESRC : XXXPROCDOC.rpgle - Template Program to Start the Build of your Procedure Documentation
* QCMDSRC : XXXPROCDOC.cmd - Template Command to Start the Build of your Procedure Documentation
* QPROTSRC : NLGMSG_PT.rpgle and NLGCVL_PT.rpgle - Example Prototypes that are used by the Template Start Build program

### How to install

1. Create library RPGPROCDOC - **CRTLIB LIB(RPGPROCDOC) TEXT('RPG Procedure Documentation')**
2. Create the QSQLSRC Source File - **CRTSRCPF FILE(RPGPROCDOC/QSQLSRC) RCDLEN(256) TEXT('SQL Script')**
3. Create the QRPGLESRC Source File - **CRTSRCPF FILE(RPGPROCDOC/QRPGLESRC) RCDLEN(256) TEXT('RPG ILE Source')**
4. Create the QCMDSRC Source File - **CRTSRCPF FILE(RPGPROCDOC/QCMDSRC) RCDLEN(92) TEXT('Command Source')**
5. Create the QPROTSRC Source File - **CRTSRCPF FILE(RPGPROCDOC/QPROTSRC) RCDLEN(256) TEXT('Prototype Source')**
6. Create and copy the corresponding source members according to the list above
7. Run the SQL Script for the RPGPROCDOC table and compile the programs in QRPGLESRC and the Command in QCMDSRC 

### How to use it

The RPG Procedure Documentation is built by executing the Start Build Command (xxxprocdoc in this example). This can be made when new or changed documentation exists. A new JSON file will be built and it is also possible to store older versions in an archive. The Db2 Table RPGPROCDOC will hold all versions and can be queried and/or cleared depending on the needs. 

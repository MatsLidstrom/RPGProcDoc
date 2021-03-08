**free
ctl-opt actgrp('RPGProcDoc');

// ------------------------------------------------------------------------------------
// Program.........: RPGProcDoc
// Description.....: RPG Procedure Documentaion
// ................: Generates JSON File with Documantation taken from Prototype Source
// Author..........: Mats Lidström
// Created.........: 2018-08-04
// Version.........: V1.5 2018-11-01
// Version.........: V2.0 2021-03-06 - RPGProcDoc Table and JSON via SQL
// Version.........: V2.1 2021-03-07 - Handle up to 999 Doc Source Files
// ------------------------------------------------------------------------------------

exec sql SET OPTION COMMIT = *NONE, CLOSQLCSR = *ENDMOD, DATFMT = *ISO;

// Declare Global Data Structures
dcl-ds  MemberList qualified dim(9999);
    MemberName char(10);
end-ds;

dcl-ds  DocLineList qualified dim(9999);
    DocLine     varchar(512);
    Label       like(pMainLabel);
    Value       varchar(512);
end-ds;


// Templates/References
dcl-ds tSourceFile qualified template;
    DocSourceFile          char(10);
    DocLibrary             char(10);
end-ds;

dcl-s   tCommand                    varchar(256);
dcl-s   tFileNameWithPath           varchar(512);

// Declare Gloabal Variables
dcl-s   gblCharTimestamp            varchar(19);
dcl-s   gblProcDocName              like(pProcDocName);
dcl-s   gblCreationTimestamp        timestamp;
dcl-s   gblSequenceNumber           int(10);
dcl-s   gblProcedureName            varchar(256);
dcl-s   gblDocSourceMember          like(MemberList.MemberName);
dcl-s   gblDocSourceFile            like(tSourceFile.DocSourceFile);
dcl-s   gblDocLibrary               like(tSourceFile.DocLibrary);
dcl-s   gblDocLineRows              like(index);
dcl-s   gblCreateArchive            like(pCreateArchive);
dcl-s   gblTargetDirectory          like(pTargetDirectory);
dcl-s   gblDocHeader                like(pDocHeader);
dcl-s   gblMainLabel                like(pMainLabel);
dcl-s   gblDocLineInd               like(pDocLineInd);
dcl-s   gblLabelInd                 like(pLabelInd);
dcl-s   gblLabelValueSeparator      like(pLabelValueSeparator);
dcl-s   gblJustInCase               like(pJustInCase);
dcl-s   gblStartPosMainLabelValue   like(index);
dcl-s   gblMemberRows               like(index);

// Work fields for Main
dcl-s   index                       int(5);
dcl-s   x                           like(index);

// Declare Global Constants
dcl-s   cQuote                      char(1) inz('''');

// --------------------------------
// Description.....: Main procedure
// --------------------------------

dcl-pi *n;
    pSourceFiles            likeds(tSourceFile) dim(999) const;
    pProcDocName            varchar(128) const;
    pCreateArchive          char(1) const;
    pTargetDirectory        varchar(256) const;
    pDocHeader              varchar(128) const;
    pMainLabel              varchar(128) const;
    pDocLineInd             char(10) const;
    pLabelInd               varchar(10) const;
    pLabelValueSeparator    varchar(10) const;
    pJustInCase             char(1) const;
end-pi;

    init_WorkFields();

    // Process all requuested Doc Source Files
    for index = 1 to %elem(pSourceFiles);

        if pSourceFiles(index).DocSourceFile = *blank;
            leave;
        endif;

        gblDocSourceFile = pSourceFiles(index).DocSourceFile;
        gblDocLibrary = pSourceFiles(index).DocLibrary;

        get_PrototypeMembers();

        // Get and process Doc Lines for all Prototype Members in Source File
        for x = 1 to (gblMemberRows);
            gblDocSourceMember = MemberList(x).MemberName;
            get_DocLines();
            get_LabelsAndValues();
        endfor;

    endfor;

    create_JSON();

*inlr = *on;

// -------------------------------------
// Sub Procedure...: init_WorkFields
// Description.....: Initiate Workfields
// -------------------------------------
dcl-proc init_WorkFields;

    gblCreationTimestamp = %timestamp();
    // Format a charcter Timestamp
    gblCharTimestamp = %char(gblCreationTimestamp);
    gblCharTimestamp = %scanrpl('.' : ':' : gblCharTimestamp);
    %subst(gblCharTimestamp : 11: 1) = ' ';

    gblProcDocName = pProcDocName;
    clear gblSequenceNumber;
    clear gblProcedureName;

    gblCreateArchive = 'N';
    if pCreateArchive <> *blanks;
        gblCreateArchive = pCreateArchive;
    endif;

    gblTargetDirectory = '/www/rpgprocdoc/htdocs/json';
    if pTargetDirectory <> *blanks;
        gblTargetDirectory = pTargetDirectory;
    endif;

    gblDocHeader = 'RPG Procedure Documentation';
    if pDocHeader <> *blanks;
        gblDocHeader = pDocHeader;
    endif;

    gblDocHeader = %trim(gblDocHeader) + ' (by RPGProcDoc at ' + %trim(gblCharTimestamp) + ')';

    gblMainLabel = 'Procedure_Name';
    if pMainLabel <> *blanks;
        gblMainLabel = pMainLabel;
    endif;

    gblDocLineInd = '//  @';
    if pDocLineInd <> *blanks;
        gblDocLineInd = pDocLineInd;
    endif;

    gblLabelInd = '@';
    if pLabelInd <> *blanks;
        gblLabelInd = pLabelInd;
    endif;

    gblLabelValueSeparator = ':';
    if pLabelValueSeparator <> *blanks;
        gblLabelValueSeparator = pLabelValueSeparator;
    endif;

    gblJustInCase = 'N';
    if pJustInCase <> *blanks;
        gblJustInCase = pJustInCase;
    endif;

    return;

end-proc;

// -------------------------------------------------------------------------------------------------
// Sub Procedure...: get_PrototypeMembers
// Description.....: Get list of Prototype Members in Source File and create Alias for each in QTEMP
// -------------------------------------------------------------------------------------------------
dcl-proc get_PrototypeMembers;

    dcl-s   wCommand    like(tCommand);

    if gblJustInCase = 'Y';
        exec sql DROP TABLE QTEMP.DocMembers;  // Delete if exist (just in case)
    endif;

    // Get list of Prototype members from Prototype File
    wCommand = 'DSPFD FILE(' + %trim(gblDocLibrary) + '/' + %trim(gblDocSourceFile) + 
               ') TYPE(*MBRLIST) OUTPUT(*OUTFILE) OUTFILE(QTEMP/DocMembers)';
    exec_Command(wCommand);

    clear MemberList;
    gblMemberRows = %elem(MemberList); // Get no of elements in Memberlist

    // Get Members into DS List
    exec sql DECLARE C1 CURSOR FOR SELECT MLNAME AS MemberName FROM QTEMP.DocMembers FOR READ ONLY;
    exec sql OPEN C1;
    exec sql FETCH C1 FOR :gblMemberRows ROWS INTO :MemberList;
    exec sql GET DIAGNOSTICS :gblMemberRows = ROW_COUNT;
    exec sql CLOSE C1;

    exec sql DROP TABLE QTEMP.DocMembers; // Delete TEMP Table when used

    return;

end-proc;

// -----------------------------------------------------------
// Sub Procedure...: get_DocLines
// Description.....: Get all Doc Lines from a Prototype Member
// -----------------------------------------------------------
dcl-proc get_DocLines;

    dcl-s   SQLStatement    varchar(512);

    if gblJustInCase = 'Y';
        // Delete if exist (just in case)
        SQLStatement = 'DROP ALIAS QTEMP.' + %trim(gblDocSourceMember);
        exec sql PREPARE ST FROM :SQLStatement;
        exec sql EXECUTE ST;
    endif;

    // Create Temp Alias to read Prototyp Member
    SQLStatement = 'CREATE ALIAS QTEMP.' + %trim(gblDocSourceMember) + ' FOR ' + %trim(gblDocLibrary) + '.' +
                   %trim(gblDocSourceFile) + ' (' + %trim(gblDocSourceMember) + ')';
    exec sql PREPARE ST FROM :SQLStatement;
    exec sql EXECUTE ST;

    clear DocLineList;
    gblDocLineRows = %elem(DocLineList); // Get no of elements in DocLineList

    // Get Doc Lines into DS List
    SQLStatement = 'SELECT SRCDTA AS DocLine FROM QTEMP.' + %trim(gblDocSourceMember) +
                   ' WHERE SRCDTA LIKE ' + cQuote + '%' + %trim(gblDocLineInd) + '%' + cQuote + ' FOR READ ONLY';

    exec sql PREPARE S2 FROM :SQLStatement;
    exec sql DECLARE C2 CURSOR FOR S2;
    exec sql OPEN C2;
    exec sql FETCH C2 FOR :gblDocLineRows ROWS INTO :DocLineList;
    exec sql GET DIAGNOSTICS :gblDocLineRows = ROW_COUNT;
    exec sql CLOSE C2;

    // Delete Temp Alias when used
    SQLStatement = 'DROP ALIAS QTEMP.' + %TRIM(gblDocSourceMember);
    exec sql PREPARE ST FROM :SQLStatement;
    exec sql EXECUTE ST;

    return;

end-proc;

// ------------------------------------------------------
// Sub Procedure...: get_LabelsAndValues
// Description.....: Get Labels and Values from Doc Lines
// ------------------------------------------------------
dcl-proc get_LabelsAndValues;

    dcl-s   wCurrLabel    like(DocLineList.Label);
    dcl-s   wPrevLabel    like(DocLineList.Label);
    dcl-s   wLabelSeq     like(index);
    dcl-s   y             like(index);

    wPrevLabel = *blank;
    wLabelSeq = 1;

    for y = 1 to (gblDocLineRows);

        DocLineList(y).Label = get_Label(DocLineList(y).DocLine);
        DocLineList(y).Value = get_Value(DocLineList(y).DocLine);

        wCurrLabel = DocLineList(y).Label;

        // Handle Duplicate Labels
        if wCurrLabel <> *blank and wCurrLabel = wPrevLabel and wCurrLabel <> gblMainLabel;
            wLabelSeq = wLabelSeq + 1;
            DocLineList(y).Label = %trim(wCurrLabel) + '_' + %trim(%char(%editc(wLabelSeq : 'Z')));
        else;
            wLabelSeq = 1;
        endif;

        if DocLineList(y).Label = gblMainLabel;
            gblProcedureName = DocLineList(y).Value;
        else;
            insert_RPGProcDocTable(DocLineList(y).Label : DocLineList(y).Value);
        endif;

        wPrevLabel = wCurrLabel;

    endfor;

    return;

end-proc;

// -----------------------------------------
// Sub Procedure...: get_Label
// Description.....: Get Label from Doc Line
// -----------------------------------------
dcl-proc get_Label;

    dcl-pi *n like(outLabel);
        inDocLine    like(DocLineList.DocLine) const;
    end-pi;

        dcl-s   outLabel    like(DocLineList.Label);
        dcl-s   z           like(index);
        dcl-s   StartPos    like(index);
        dcl-s   EndPos      like(index);

        clear outLabel; //Init

        StartPos = %scan(gblLabelInd : inDocLine : 1) + 1;

        if StartPos > *zero;
            EndPos = *zero; //Init

            for z = StartPos to %size(inDocLine);
                if %subst(inDocLine : z : 1) = *blank;
                    EndPos = z -1; // Real StartPos of Value
                    z = %size(inDocLine) + 1; //End FOR loop
                endif;
            endfor;

            if EndPos > *zero;
                outLabel = %subst(inDocLine : StartPos : EndPos - StartPos + 1 );
            else;
                outLabel = %subst(inDocLine : StartPos);
            endif;
        endif;

    return outLabel;

end-proc;

// -----------------------------------------
// Sub Procedure...: get_Value
// Description.....: Get Value from Doc Line
// -----------------------------------------
dcl-proc get_Value;

    dcl-pi *n like(outValue);
        inDocLine    like(DocLineList.DocLine) const;
    end-pi;

        dcl-s   outValue                like(DocLineList.Value);
        dcl-s   z                       like(index);
        dcl-s   StartPos                like(index);

        clear outValue; //Init

        if get_Label(inDocline) <> gblMainLabel;
            StartPos = gblStartPosMainLabelValue;  // StartPos of Value the same as for the Main Label
        else;

            StartPos = %scan(gblLabelValueSeparator : inDocLine : 1) + 1; // Gets position after Label Value Separator

            if StartPos > *zero;
                // Get real StartPos of Value
                for z = StartPos to %size(inDocLine);
                    if %subst(inDocLine : z : 1) <> *blank;
                        StartPos = z; // Real StartPos of Value
                        z = %size(inDocLine) + 1; //End FOR loop
                    endif;
                endfor;

                gblStartPosMainLabelValue = StartPos;
            endif;

        endif;

        outValue = %subst(inDocLine : StartPos);

    return outValue;

end-proc;

// ----------------------------------------------------------------------
// Sub Procedure...: create_JSON
// Description.....: Create JSON file with loaded Prototype Documentation
// ----------------------------------------------------------------------
dcl-proc create_JSON;

    dcl-s  wFileNameWithPath    like(tFileNameWithPath);
    dcl-s  wPosition            like(index);
    dcl-s  wTargetArchive       like(gblTargetDirectory);
    dcl-s  wCharTimestamp       like(gblCharTimestamp);

    // Create or refresh RPGProcDoc Standard File in IFS
    wFileNameWithPath = %trim(gblTargetDirectory) + '/' +  %trim(gblProcDocName) + '.json';

    create_JSON_IFS_File(wFileNameWithPath);

    if gblCreateArchive = 'Y';  // Create Archive File in IFS ../archive

        // Archive Directory should be located on same level as Target Directory
        wPosition = %scanr('/' : gblTargetDirectory);
        if wPosition = *zero;
          wTargetArchive = 'archive/';
        else;
          wTargetArchive = %subst(gblTargetDirectory : 1 : wPosition) + 'archive/';
        endif;

        // Trim Timestamp for Archive Filename
        wCharTimestamp = gblCharTimestamp;
        wCharTimestamp = %scanrpl(' ' : '' : wCharTimestamp);
        wCharTimestamp = %scanrpl('-' : '' : wCharTimestamp);
        wCharTimestamp = %scanrpl('.' : '' : wCharTimestamp);
        wCharTimestamp = %scanrpl(':' : '' : wCharTimestamp);

        wFileNameWithPath = %trim(wTargetArchive) + %trim(gblProcDocName) + '_' + %trim(wCharTimestamp) + '.json';
        create_JSON_IFS_File(wFileNameWithPath);
    endif;

    return;

end-proc;

// ----------------------------------------------------------
// Sub Procedure...: create_JSON_IFS_File
// Description.....: Create JSON File on the IFS
// ----------------------------------------------------------
dcl-proc create_JSON_IFS_File;

    dcl-pi *n;
        inFileNameWithPath  like(tFileNameWithPath) const;
    end-pi;

        dcl-s   IFS_File    sqltype(CLOB_FILE);

        // Set the JSON File info
        clear IFS_File;
        IFS_File_Name = inFileNameWithPath; // Path including filename
        IFS_File_NL   = %len(%trim(IFS_File_Name));
        IFS_File_FO   = SQFOVR; // Open mode
                                // SQFOVR Override
                                // SQFCRT Create
                                // SQFAPP Append
                                // SQFRD  Read

        // Build the JSON file from the data in RPProcDoc table and place it on the requested localtion in the IFS
        // NOTE!!! Jobs CCSID can not be 65535
        exec sql
            WITH X AS (
                SELECT
                    JSON_OBJECT('Procedure_Name' : TRIM(ProcedureName),
                                'Procedure_Info' :
                                '{' CONCAT LISTAGG(('"' CONCAT TRIM(LabelName) CONCAT '":"' CONCAT TRIM(LabelValue) CONCAT
                                '"'), ',') WITHIN GROUP(ORDER BY SequenceNumber) CONCAT '}'
                                FORMAT JSON) AS ProcedureObject
                FROM RPGProcDoc
                WHERE ProcDocName = :gblProcDocName AND CreationTimestamp = :gblCreationTimestamp
                GROUP BY ProcDocName, CreationTimestamp, DocLibrary, DocSourceFile, ProcedureName
                ORDER BY ProcDocName, CreationTimestamp, DocLibrary, DocSourceFile, ProcedureName)

            SELECT
                JSON_OBJECT('Header'     : :gblDocHeader,
                            'Procedures' : JSON_ARRAYAGG((ProcedureObject) FORMAT JSON)
                )
                INTO :IFS_File
                FROM X;

    end-proc;

    // ----------------------------------------------
    // Sub Procedure...: insert_RPGProcDocTable
    // Description.....: Insert into RPGProcDoc Table
    // ----------------------------------------------
    dcl-proc insert_RPGProcDocTable;

        dcl-pi *n;
            inLabel           like(DocLineList.Label) const;
            inValue           like(DocLineList.Value) const;
        end-pi;

            gblSequenceNumber += 1;

            exec sql
                INSERT INTO RPGProcDoc
                    VALUES(:gblProcDocName, :gblCreationTimestamp, :gblSequenceNumber, :gblProcedureName,
                           :inLabel, :inValue, :gblDocSourceMember, :gblDocSourceFile, :gblDocLibrary);

    return;

end-proc;

// ---------------------------------
// Sub Procedure...: exec_Command
// Description.....: Execute Command
// ---------------------------------
dcl-proc exec_Command;

    dcl-pi *n;
        inCommand like(tCommand) const;
    end-pi;

        dcl-pr QCMDEXC extpgm;
            *n char(256) options(*varsize) const;
            *n packed(15:5) const;
        end-pr;

        QCMDEXC(inCommand:%len(%trimr(inCommand)));

    return;

end-proc;

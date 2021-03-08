**free
ctl-opt actgrp('RPGProcDoc');

// -----------------------------------------------------
// Program.........: XXXProcDoc
// Description.....: Start RPGProcDoc for My Application
// Author..........: Mats Lidström
// Created.........: 2018-08-05
// -----------------------------------------------------

dcl-pr RPGProcDoc extpgm;
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
end-pr;

    dcl-ds tSourceFile qualified template;
        DocSourceFile          char(10);
        DocLibrary             char(10);
    end-ds;

    dcl-ds   SourceFiles            likeds(tSourceFile) dim(999); // No Default
    dcl-s    ProcDocName            varchar(120) inz(' '); // No Default
    dcl-s    CreateArchive          char(1)      inz(' '); // Default 'N'. If 'Y' must the directory Archive exist in TargetDirectory
    dcl-s    TargetDirectory        varchar(132) inz(' '); // Default '/www/rpgprocdoc/htdocs/json' Must exist
    dcl-s    DocHeader              varchar(132) inz(' '); // Default 'RPG Procedure Documentation'
    dcl-s    MainLabel              varchar(132) inz(' '); // Default 'Procedure_Name'
    dcl-s    DocLineInd             char(10)     inz(' '); // Default '//  @'
    dcl-s    LabelInd               varchar(10)  inz(' '); // Default '@'
    dcl-s    LabelValueSeparator    varchar(10)  inz(' '); // Default ':'
    dcl-s    JustInCase             char(1)      inz(' '); // Default 'N'

    clear SourceFiles;
    SourceFiles(1).DocSourceFile = 'QPROTSRC';
    SourceFiles(1).DocLibrary = 'RPGPROCDOC';
    ProcDocName = 'XXXProcDoc';
    DocHeader = 'My Applications RPG Procedure Documentation';

    RPGProcDoc(SourceFiles : ProcDocName : CreateArchive : TargetDirectory : DocHeader : MainLabel : DocLineInd : LabelInd : LabelValueSeparator: JustInCase);

*inlr = *on;

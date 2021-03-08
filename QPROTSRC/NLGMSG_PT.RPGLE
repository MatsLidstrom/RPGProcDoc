**free
//**********************************************************************
// LWW            Next Level
//**********************************************************************
//
// Description..: NLGMSG - Handles messaging between functions
// Programmer...: Mats Lidström
// Company......: Apper Systems
// Date.........: 2018-10-08
//
// Ändrad:
//   2018-11-19 CÖ  Utökat så man kan skicka med ID med meddelandet.
//                  Bättre hantering för webben.
//
// *********************************************************************

dcl-ds T_Messages   Qualified Template ;
       ID               char(128) ;
       Message          char(512) ;
end-ds ;

dcl-ds p_Messages       likeds(T_Messages) dim(128) ;

dcl-s  p_ID             like(T_Messages.ID) ;
dcl-s  p_Message        like(T_Messages.Message) ;
dcl-s  p_MessageRows    int(5) ;

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

//----------------------------------------------------------------------
//  @Procedure_Name        : receive_Messages
//  @Procedure_Description : Receives messages from the previous requested procedure that returned false
//  @Procedure_Source      : QRPGLESRC,NLGMSG_PR
//  @Procedure_Prototype   : /include QPROTSRC,NLGMSG_PT
//  @Procedure_Input       : *none
//  @Procedure_Output      : p_Messages     dim(128)             with fields p_Messages.ID and p_Messages.Message
//  @Procedure_Output      : p_MessageRows
//  @Procedure_Example     : receive_Messages(p_Messages : p_MessageRows) ;
//----------------------------------------------------------------------
dcl-PR receive_Messages ;
       Messages     likeds(T_Messages) dim(128) ;
       MessageRows  like(p_MessageRows) ;
end-PR ;

//----------------------------------------------------------------------
//  @Procedure_Name        : show_Message
//  @Procedure_Description : Shows a message on the Green Screen
//  @Procedure_Source      : QRPGLESRC,NLGMSG_PR
//  @Procedure_Prototype   : /include QPROTSRC,NLGMSG_PT
//  @Procedure_Input       : p_Message
//  @Procedure_Output      : *none
//  @Procedure_Example     : p_Message = 'Message text' ;
//  @Procedure_Example     : show_Message(p_Message) ;
//----------------------------------------------------------------------
dcl-PR show_Message ;
       Message      like(T_Messages.Message) const ;
end-PR ;

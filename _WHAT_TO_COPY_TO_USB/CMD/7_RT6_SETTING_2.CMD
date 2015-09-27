/*
 * RT6_SETTING.CMD  by mira308sw
 *
 * Change some configuration in user_config.dat
 * WARNING: Confirm script reboot question at the end !
 *			do NOT reboot manually !
 *
 * v 1.00: 28/12/2013   first release
 * v 1.01: 02/01/2014   add "Map DRM"
 * v 1.02: 02/03/2014   add "Audio mode" 0=normal 1=hifi 2=hifiCAN 3=arkamys 4=arkamys+hifi 5=???
 * v 1.03: 01/04/2014   add "DSG" Detecteur Sous Gonfiature : 1=enable
 */

typedef unsigned char           BYTE;
typedef unsigned short          WORD;
typedef unsigned long           DWORD;

typedef int                     BOOL;

typedef void                    DIR;
typedef void                    FILE;

typedef enum { ERROR=-1,OK=0 }  STATUS;

#define NULL                    (void*)0
#define TRUE                    1
#define FALSE                   0


char*   strcat                  ( char *dest,char *s );
char*   strcpy                  ( char *dest,char *src );

/* Functions and data types from MMI module
 */
#define NO                            0
#define YES                           1

STATUS  ClearScreen                   ( void );
STATUS  ShowNavigationQuestionScreen  ( char *txt, int *answ );

void    RebootSystem              ( void );
void*   UPGFindSymbol             ( char *sym );



/* these functions work only on modified Builtinsrneg.out crc=e49f2d91
 * this is a method to call any function, throw modified AddUPGHistoryCommentary
 * function
 * GFC = Generic Function Call
 */
int     AddUPGHistoryCommentary	 ( void *funptr,... );   // max 7 parameters
#define GFC                             AddUPGHistoryCommentary

#define GetAudioConfigData(d)   GFC( UPGFindSymbol( "GetAudioConfigData__6UP_MODR15AudioConfigData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 ), \
                                     d )
#define GetGeneralConfigData(d) GFC( UPGFindSymbol( "GetGeneralConfigData__6UP_MODR17GeneralConfigData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 ), \
                                     d )
#define GetDisplayConfigData(d) GFC( UPGFindSymbol( "GetDisplayConfigData__6UP_MODR17DisplayConfigData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 ), \
                                     d )
#define GetAASConfigData(d)     GFC( UPGFindSymbol( "GetAASConfigData__12C_BCM_UP_AASR13AASConfigData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 )+0x78, \
                                     d )
#define GetVANConfigData(d)     GFC( UPGFindSymbol( "GetVANConfigData__6UP_MODR13VANConfigData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 ), \
                                     d )
#define GetMapConfigData(d)     GFC( UPGFindSymbol( "GetMapConfigData__6UP_MODR13MapConfigData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 ), \
                                     d )
#define GetVANData(d)           GFC( UPGFindSymbol( "GetVANData__6UP_MODP7VANData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 ), \
                                     d )

#define SetAudioConfigData(d)   GFC( UPGFindSymbol( "SetAudioConfigData__6UP_MODRC15AudioConfigData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 ), \
                                     d )
#define SetGeneralConfigData(d) GFC( UPGFindSymbol( "SetGeneralConfigData__6UP_MODRC17GeneralConfigData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 ), \
                                     d )
#define SetDisplayConfigData(d) GFC( UPGFindSymbol( "SetDisplayConfigData__6UP_MODRC17DisplayConfigData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 ), \
                                     d )
#define SetAASConfigData(d)     GFC( UPGFindSymbol( "SetAASConfigData__12C_BCM_UP_AASR13AASConfigData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 )+0x78, \
                                     d )
#define SetVANConfigData(d)     GFC( UPGFindSymbol( "SetVANConfigData__6UP_MODRC13VANConfigData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 ), \
                                     d )
#define SetMapConfigData(d)     GFC( UPGFindSymbol( "SetMapConfigData__6UP_MODRC13MapConfigData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 ), \
                                     d )
#define SetVANData(d)           GFC( UPGFindSymbol( "SetVANData__6UP_MODPC7VANData" ),  \
                                     GFC( UPGFindSymbol( "GetObjPtr__15C_OBJ_PTR_TableUsUs" ),0x46B4,0 ), \
                                     d )



int ChangeData  ( char *txt,int offset,int size,BYTE *data,int nval,int *val )
{
  char msg[80];
  int x,next,i;
  int l_answ;
  int org;

  switch( size )
  {
  case 1: x = *(BYTE*)(data+offset); break;
  case 2: x = *(WORD*)(data+offset); break;
  case 4: x = *(DWORD*)(data+offset); break;
  }
  org = x;
  do
  {
    next = val[0];
    for( i=nval-1 ; i>=0 ; i-- )
      if( x<val[i] )
        next = val[i];
    GFC( UPGFindSymbol( "sprintf" ),msg,"%s=%d. Change to %d ?",txt,x,next );
    ShowNavigationQuestionScreen( msg,&l_answ );
    if( l_answ==YES )
      x = next;
  }
  while( l_answ==YES && nval>2 );

  switch( size )
  {
  case 1: *(BYTE*)(data+offset) = x; break;
  case 2: *(WORD*)(data+offset) = x; break;
  case 4: *(DWORD*)(data+offset) = x; break;
  }
  return x==org ? NO : YES;
}

BYTE data[2048];
int  vonoff[]={ 0,1 };
int  vspeed[]={ 5,225 };
int  vbeep[]={ 2,5,8 };
int  vvmf[]={ 0,1,2,3,4 };
int  vam[]={ 0,1,2,3,4,5 };

#define VALS( v )   sizeof( v )/sizeof( *v ),v

int main ( int argc,char *argv[] )
{
  int   l_answ;

  if( GetGeneralConfigData( data )!=OK )
    ShowNavigationQuestionScreen( "Error in GetGeneralConfigData",&l_answ );
  else
  {
    l_answ  = ChangeData( "Video speed",0,1,data,VALS( vspeed ) );
    if( l_answ!=NO && SetGeneralConfigData( data )!=OK )
      ShowNavigationQuestionScreen( "Error in SetGeneralConfigData",&l_answ );
  }

  if( GetAudioConfigData( data )!=OK )
    ShowNavigationQuestionScreen( "Error in GetAudioConfigData",&l_answ );
  else
  {
    l_answ  = ChangeData( "Audio Mode"    , 0,1,data,VALS( vam ) );
    l_answ += ChangeData( "Front beep vol",26,1,data,VALS( vbeep ) );
    l_answ += ChangeData( "Rear beep vol" ,27,1,data,VALS( vbeep ) );
    data[29] = data[26];
    data[30] = data[27];
    if( l_answ!=NO && SetAudioConfigData( data )!=OK )
      ShowNavigationQuestionScreen( "Error in SetAudioConfigData",&l_answ );
  }

  if( GetDisplayConfigData( data )!=OK )
    ShowNavigationQuestionScreen( "Error in GetDisplayConfigData",&l_answ );
  else
  {
    l_answ  = ChangeData( "Ext temp"     , 0,4,data,VALS( vonoff ) );
    l_answ += ChangeData( "Conf menu"    , 4,4,data,VALS( vonoff ) );
    l_answ += ChangeData( "Enable HARM02",24,4,data,VALS( vonoff ) );
    l_answ += ChangeData( "Enable HARM03",28,4,data,VALS( vonoff ) );
    if( l_answ!=NO && SetDisplayConfigData( data )!=OK )
      ShowNavigationQuestionScreen( "Error in SetDisplayConfigData",&l_answ );
  }

  if( GetVANData( data )!=OK )
    ShowNavigationQuestionScreen( "Error in GetVANData",&l_answ );
  else
  {
    l_answ  = ChangeData( "DSG"     , 8,4,data,VALS( vonoff ) );
    if( l_answ!=NO && SetVANData( data )!=OK )
      ShowNavigationQuestionScreen( "Error in SetVANData",&l_answ );
  }

  if( GetVANConfigData( data )!=OK )
    ShowNavigationQuestionScreen( "Error in GetVANConfigData",&l_answ );
  else
  {
    l_answ  = ChangeData( "VMF/VCCF"     ,12,4,data,VALS( vvmf ) );
    if( l_answ!=NO && SetVANConfigData( data )!=OK )
      ShowNavigationQuestionScreen( "Error in SetVANConfigData",&l_answ );
  }

  if( GetAASConfigData( data )!=OK )
    ShowNavigationQuestionScreen( "Error in GetAASConfigData",&l_answ );
  else
  {
    l_answ  = ChangeData( "Rear park sensor" , 0,4,data,VALS( vonoff ) );
    l_answ += ChangeData( "Front park sensor", 4,4,data,VALS( vonoff ) );
    if( l_answ!=NO && SetAASConfigData( data )!=OK )
      ShowNavigationQuestionScreen( "Error in SetAASConfigData",&l_answ );
  }

  if( GetMapConfigData( data )!=OK )
    ShowNavigationQuestionScreen( "Error in GetMapConfigData",&l_answ );
  else
  {
    l_answ  = ChangeData( "Maps DRM" , 0,4,data,VALS( vonoff ) );
    if( l_answ!=NO && SetMapConfigData( data )!=OK )
      ShowNavigationQuestionScreen( "Error in SetMapConfigData",&l_answ );
  }

  ShowNavigationQuestionScreen( "Finish. Reboot ?",&l_answ );
  if( l_answ==YES )
    RebootSystem();

  return OK;
}
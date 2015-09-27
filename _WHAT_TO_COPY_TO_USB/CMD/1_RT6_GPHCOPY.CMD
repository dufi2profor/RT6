/*
 * RT6_GPHCOPY.CMD by mira308sw
 *
 * script to write GPH files from CD/USB to /SDC partition on RT6
 *
 * v:01.00  06/04/2011
 * v:01.01  02/01/2013	add some folder for sw:2.21
 * v:01.02  02/03/2013	remove call to functions UnprotectHDDpartition
 */

#define RTX_DRIVE     "/SDC"
#define CD_DRIVE      "/D"
#define USB_DRIVE     "/bd0"
#define GPH_PATH      RTX_DRIVE "/Data_Base/Graphics/RNEG"

char* g_GphFile[]=
{
  "/Common/FNT_common.gph.bz2",
  "/Common/GEN_common.gph.bz2",
  "/DE/GEN_DE.gph.bz2",
  "/DU/GEN_DU.gph.bz2",
  "/EN/GEN_EN.gph.bz2",
  "/ES/GEN_ES.gph.bz2",
  "/FR/GEN_FR.gph.bz2",
  "/HARM00/$$$$_HA00.gph.bz2",
  "/HARM00/GEN_HA00.gph.bz2",
  "/HARM00/LRG_HA00.gph.bz2",
  "/HARM01/$$$$_HA00.gph.bz2",
  "/HARM01/GEN_HA01.gph.bz2",
  "/HARM01/LRG_HA01.gph.bz2",
  "/HARM02/$$$$_HA00.gph.bz2",
  "/HARM02/GEN_HA02.gph.bz2",
  "/HARM02/LRG_HA02.gph.bz2",
  "/HARM03/$$$$_HA00.gph.bz2",
  "/HARM03/GEN_HA03.gph.bz2",
  "/HARM03/LRG_HA03.gph.bz2",
  "/IT/GEN_IT.gph.bz2",
  "/PL/GEN_PL.gph.bz2",
  "/PO/GEN_PO.gph.bz2",
  "/RU/GEN_RU.gph.bz2",
  "/TU/GEN_TU.gph.bz2",
};

#define BUILTINS_FILE "BUILTINS.OUT"
#define TRUE          1
#define FALSE         0
#define NO            0
#define YES           1
#define OK            0
#define ERROR        -1
#define NOFILE        1
#define NULL          ((void*)0)

int     ShowNavigationQuestionScreen ( char *text,int *answer );
int     ShowNavigationBargraph       ( void );
int     StepBargraph        ( char *txt, int per );
int     ClearScreen         ( void );

int     UPGCopy             ( char *src,char *dst,int cut );
void*   UPGFindSymbol       ( char *sym );
int     GetFileSize         ( char *file,int *size );
void    RebootSystem        ( void );

char*   strcpy              ( char *target,char *source );
char*   strcat              ( char *target,char *source );
int     strcmp              ( char *s1,char *s2 );


/* these functions work only on modified Builtinsrneg.out crc=
 * this is a method to call any function, throw modified AddUPGHistoryCommentary
 * function
 * GFC = GenericFunctionCall
 */
int     AddUPGHistoryCommentary	 ( void *funptr,... );   // max 7 parameters
#define GFC                             AddUPGHistoryCommentary
#define UNPROTECTHDDPARTITION(p)        GFC( pf_unprotect,p )
#define REMOVETURBOBOOTINFO()           GFC( pf_rtbi )

void *pf_unprotect;
void *pf_rtbi;

int   InitFunctionPtr ( void )
{
  int   l_iAnsw;

  pf_unprotect  =UPGFindSymbol( "UnprotectHddPartition__FPCc" );
  pf_rtbi       =UPGFindSymbol( "RemoveTurboBootInfo__13C_FILE_SEARCH" );

  if( pf_unprotect  !=NULL &&
      pf_rtbi       !=NULL )
  {
      return OK;
  }
  ShowNavigationQuestionScreen( "InitFunctionPtr() FAILED!", &l_iAnsw );
  return ERROR;
}


int   CopyGPH ( char *p_drv,char *p_file )
{
  int   l_error;
  int   l_size;
  int   l_answ;
  char  l_src[256];
  char  l_dst[256];
  char  l_msg[256];

  strcpy( l_src,p_drv );
  strcat( l_src,p_file );
  if( GetFileSize( l_src,&l_size )==ERROR )
    return NOFILE;

  strcpy( l_msg,"Copy " );
  strcat( l_msg,p_file );
  strcat( l_msg," to RT6 ?" );
  ShowNavigationQuestionScreen( l_msg, &l_answ );
  if( l_answ==NO )
    return OK;

  ShowNavigationBargraph();
  StepBargraph( "coping...",33 );
  strcpy( l_dst,GPH_PATH  );
  strcat( l_dst,p_file );
  l_error=UPGCopy( l_src,l_dst,0 );
  if( !l_error )
  {
    StepBargraph( "coping...",75 );
    strcat( l_src,".inf" );
    strcat( l_dst,".inf" );
    l_error=UPGCopy( l_src,l_dst,0 );
  }
  ClearScreen();
  return l_error;
}

int   main ( int argc,char* argv[] )
{
  int   l_answ=YES;
  int   l_i;
  int   l_nGph=sizeof( g_GphFile )/sizeof( *g_GphFile );
  int   l_bExist=FALSE;

  if( InitFunctionPtr()!=OK )
    return OK;

/*	
  if( UNPROTECTHDDPARTITION( RTX_DRIVE )!=OK )
    ShowNavigationQuestionScreen( "Error in UnprotectHddPartition!",&l_answ );
  else
  {
*/  
    for( l_i=0 ; l_i<l_nGph ; l_i++ )
    {
      switch( CopyGPH( argv[1],g_GphFile[l_i] ) )
      {
      case OK:
        l_bExist=TRUE;
        break;
      case ERROR:
        return OK;
      }
    }
    if( l_bExist==FALSE && strcmp( argv[1],USB_DRIVE )!=0 )
    {
      for( l_i=0 ; l_i<l_nGph ; l_i++ )
        if( CopyGPH( USB_DRIVE,g_GphFile[l_i] )==ERROR )
          return OK;
    }
    if( REMOVETURBOBOOTINFO()==OK )
    {
      ShowNavigationQuestionScreen( "Files copied. Reboot ?",&l_answ );
      if( l_answ==YES )
        RebootSystem();
    }
/*	
  }
*/  
  return OK;
}


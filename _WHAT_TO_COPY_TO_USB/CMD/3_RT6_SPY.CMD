/*
 * RT6_SPY.CMD  by mira308sw
 *
 * Copy SPY data to USB and clear /I/SPY
 *
 * version:
 * 01.00: 06/04/2011
 */


/* Functions and data types from Integrated C Interpreter
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

STATUS  xcopy                   ( char *src,char *dest );
STATUS  xdelete                 ( char *src );
int     strcmp                  ( char *s1,char *s2 );
char*   strrchr                 ( char *s,int c );
char*   strcat                  ( char *dest,char *s );
char*   strcpy                  ( char *dest,char *src );
int     strlen                  ( char *s );

#define NO                            0
#define YES                           1

STATUS  ClearScreen                   ( void );
STATUS  ShowNavigationBargraph        ( void );
STATUS  StepBargraph                  ( char *txt, int per );
STATUS  ShowNavigationQuestionScreen  ( char *txt, int *answ );

int     UPGSearchFile       ( char *fn, char *root, char *param, char *tabledir );
STATUS  UPGGetSearchResult  ( int ndx,char *res );
STATUS  UPGMKDir            ( char *dir);

/* Drive letters
 */
#define DRIVE_USB       "/bd0"
#define DRIVE_CD        "/D"
#define DRIVE_TFFS      "/F"
#define DRIVE_JBX       "/J"
#define DRIVE_HDD       "/SDC"
#define DRIVE_NAV       "/SDH"
#define DRIVE_USER      "/SDI"




/****************************** SPY.CMD ******************************/

#define SPY_PATH    DRIVE_USER "/SPY"


char* _strchr ( char *p_s,char p_c )
{
  for( ; *p_s ; p_s++ )
    if( *p_s==p_c )
      return p_s;
  return NULL;
}

int   MakeDir ( char *p_sPath )
{
  char  *l_p=_strchr( p_sPath+1,'/' );
  for( l_p=_strchr( l_p+1,'/' ) ; l_p ; l_p=_strchr( l_p+1,'/' ) )
  {
    *l_p=0;
    if( UPGMKDir( p_sPath )!=OK )
      return ERROR;
    *l_p='/';
  }
  return UPGMKDir( p_sPath );
}

int  main ( int argc, char **argv )
{
  int   l_iAnsw = FALSE;
  int   l_iCopyAll;
  int   l_iCopy;
  int   l_nFile;
  int   l_i;
  char  l_sFile[256];
  char  l_sPath[256];

  ShowNavigationQuestionScreen( "Copy ALL spy data ?",&l_iCopyAll );
  ShowNavigationBargraph();
  StepBargraph( "Searching spy data",0 );
  l_nFile=UPGSearchFile( "*.*",SPY_PATH,NULL,NULL );
  for( l_i=0 ; l_i<l_nFile ; l_i++ )
  {
    if( UPGGetSearchResult( l_i,l_sFile )==ERROR )
      continue;
    *strrchr( l_sFile,'/' )=0;
    if( strcmp( l_sFile,l_sPath )==0 )
      continue;
    if( l_iCopyAll )
      l_iCopy=YES;
    else
    {
      strcpy( l_sPath,"Copy " );
      strcat( l_sPath,strrchr( l_sFile,'/' ) );
      strcat( l_sPath," ?" );
      ShowNavigationQuestionScreen( l_sPath,&l_iCopy );
    }
    if( l_iCopy )
    {
      ShowNavigationBargraph();
      StepBargraph( "Coping...",100*l_i/l_nFile );
      strcpy( l_sPath,DRIVE_USB );
      strcat( l_sPath,l_sFile+strlen( DRIVE_USER ) );
      MakeDir( l_sPath );
      if( xcopy( l_sFile,l_sPath )!=OK )
      {
        strcpy( l_sPath,"ERROR coping " );
        strcat( l_sPath,l_sFile );
        ShowNavigationQuestionScreen( l_sPath,&l_iAnsw );
      }
    }
    strcpy( l_sPath,"Delete " );
    strcat( l_sPath,strrchr( l_sFile,'/' ) );
    strcat( l_sPath," ?" );
    ShowNavigationQuestionScreen( l_sPath,&l_iAnsw );
    if( l_iAnsw==YES )
    {
      ShowNavigationBargraph();
      StepBargraph( "Delete...",100*l_i/l_nFile );
      if( xdelete( l_sFile )!=OK )
      {
        strcpy( l_sPath,"ERROR deleting " );
        strcat( l_sPath,l_sFile );
        ShowNavigationQuestionScreen( l_sPath,&l_iAnsw );
      }
    }
    strcpy( l_sPath,l_sFile );
  }
  ShowNavigationQuestionScreen( "Copy completed!",&l_iAnsw );

  ClearScreen();
  return OK;
}


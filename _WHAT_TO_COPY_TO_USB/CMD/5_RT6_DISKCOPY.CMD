/*
 * RT6_DISKCOPY.CMD
 * by mira308sw
 *
 * Copy RT6 / emyway+ / RNEG2011 HardDisk Partitions to USB
 *
 * ver:01.00  02/04/2011 :   first release
 */


/*** GLOBAL DEFINES ****/


// Script Types
typedef int  STATUS;
typedef void DIR;
typedef int  BOOL;
typedef int  size_t;
typedef void FILE;

#define TRUE            (1)
#define FALSE           (0)
#define OK              (0)
#define ERROR           (-1)
#define NULL            (void*) 0

// Drive letters
#define DRIVE_HDD       "/SDC"
#define DRIVE_NAV       "/SDH"
#define DRIVE_USER      "/SDI"
#define DRIVE_CD        "/D"
#define DRIVE_TFFS      "/F"
#define DRIVE_JBX       "/J"
#define DRIVE_USB       "/bd0"


/*** EXTERN FUNCTION DECLARATIONS ***/

// File operations
STATUS UPGDelete          (char* fn);
STATUS UPGCopy            (char* p_source, char* p_dest, int p_cut);
int    UPGSearchFile      (char* Filename, char *RootDir, char *Param, char *TableDir );
STATUS UPGGetSearchResult (int index , char *SearchResult );
void*  UPGFindSymbol      ( char *sym );
int    ExecuteFlasherOut  ( void *funptr,... );   // max 7 parameters
STATUS GetFileSize        (char* file, int *size);
STATUS xdelete            (char* src);

char*  fgets              (char* buf, size_t n, FILE * fp);
int    fputs              (char* s, FILE * fp);
FILE*  fopen              (char* filename, char * mode );
int    fclose             (FILE* fp);

// String operations
STATUS strcpy             (char* target, char* source);
STATUS strcat             (char* target, char* source);
int    strlen             (char* str);
int    atoi               (char * p_str);

// MMI UPG Panel management
STATUS ClearScreen                  (void);
STATUS ShowNavigationBargraph       (void);
STATUS StepBargraph                 (char *text, int index);
STATUS ShowNavigationQuestionScreen (char *text, int *answer);

// Others
STATUS taskDelay          (int ticks);
//STATUS StopHDDActivity    (void);
//STATUS UpdateFSImage      (void);




/****************************** HD_COPY ******************************/
#define _1MBYTE                 (1048576)
#define YES                     (1)
#define NO                      (0)
#define MAX_SIZE                (50*_1MBYTE)
#define USB_NOTCOPIED_FILE      "/bd0/HDCPY_NOTCOPIED.TXT"
#define USB_LASTCOPIED_FILE     "/bd0/HDCPY_LASTCOPIED.TXT"
#define USB_LIST_FILE           "/bd0/HDCPY_FILELIST.TXT"
#define COL_SEP                 '\t'

typedef struct
{
  int   m_unit;
  int   m_mega;
} t_longint;

void AddFileSize ( t_longint *p_liSize,int p_iAdd )
{
  p_liSize->m_unit += p_iAdd;
  if( p_liSize->m_unit > _1MBYTE )
  {
    p_liSize->m_mega += p_liSize->m_unit/_1MBYTE;
    p_liSize->m_unit %= _1MBYTE;
  }
}

char* _strchr ( char *p_s,int c )
{
  for( ; *p_s && *p_s!=c ; p_s++ );
  return p_s;
}

void _itoa ( int i,char* s,int base )
{
  char l_s[16];
  int  n=0,m=0;
  if( i<0 )
  {
    s[m++]='-';
    i=-i;
  }
  do
  {
    l_s[n++]=(char)('0'+(i%base));
    i/=base;
  }
  while( i );
  for( --n ; n>=0 ; n--,m++ )
    s[m]=l_s[n];
  s[m]=0;
}

int  CreateList ( FILE* p_pList,char* p_pDrive,t_longint *p_liSize )
{
  char l_sFile[256];
  char l_sText[80];
  int  l_nFile;
  int  l_iSize;
  int  l_i;
  int  l_iPerc;

  ShowNavigationBargraph();
  strcpy( l_sText,"Reading " );
  strcat( l_sText,p_pDrive );
  StepBargraph( l_sText,0 );

  l_nFile=UPGSearchFile( "*.*",p_pDrive,NULL,NULL );
  l_iPerc=l_nFile/10;

  for( l_i=0 ; l_i<l_nFile ; )
  {
    if( UPGGetSearchResult( l_i,l_sFile )==ERROR )
      l_i++;
    else
    {
      fputs( l_sFile,p_pList );
      if( GetFileSize( l_sFile,&l_iSize )!=ERROR )
      {
        l_sFile[0]=COL_SEP;
        _itoa( l_iSize,l_sFile+1,10 );
        fputs( l_sFile,p_pList );
        AddFileSize( p_liSize,l_iSize );
      }
      fputs( "\r\n",p_pList );
      l_i++;
      if( l_i>=l_iPerc )
      {
        StepBargraph( l_sText,100*l_i/l_nFile );
        l_iPerc+=l_nFile/10;
      }
    }
  }
  _itoa( l_nFile,l_sText,10 );
  strcat( l_sText," files found on " );
  strcat( l_sText,p_pDrive );
  StepBargraph( l_sText,100 );
  taskDelay( 1000 );

  return l_nFile;
}

int  ReadLastCopied ( void )
{
  char  l_s[16];
  char *l_sLast;
  FILE *l_pLast=fopen( USB_LASTCOPIED_FILE,"r" );
  if( l_pLast==NULL )
    return 0;
  l_sLast=fgets( l_s,sizeof( l_s ),l_pLast );
  fclose( l_pLast );
  if( l_sLast==NULL )
    return 0;
  return atoi( l_sLast );
}

int  WriteLastCopied ( int p_iLast )
{
  char  l_s[16];
  FILE *l_pLast=fopen( USB_LASTCOPIED_FILE,"w" );
  if( l_pLast==NULL )
    return ERROR;
  _itoa( p_iLast,l_s,10 );
  fputs( l_s,l_pLast );
  fputs( "\n",l_pLast );
  fclose( l_pLast );
  return OK;
}

int  WriteNotCopied ( char *p_sFile )
{
  FILE *l_pNoCpy;

  if( p_sFile )
    l_pNoCpy=fopen( USB_NOTCOPIED_FILE,"a" );
  else
    l_pNoCpy=fopen( USB_NOTCOPIED_FILE,"w" );

  if( l_pNoCpy==NULL )
    return ERROR;

  if( p_sFile )
  {
    fputs( p_sFile,l_pNoCpy );
    fputs( "\r\n",l_pNoCpy );
  }
  fclose( l_pNoCpy );
  return OK;
}

int  CopyFile ( FILE* p_pList,int p_i,int p_pLast )
{
  char l_sSrc[256];
  char l_sDst[256];
  char *l_p;
  int  l_iSize;

  for( ; p_pLast<p_i ; p_pLast++ )
    if( fgets( l_sSrc,sizeof( l_sSrc ),p_pList )==NULL )
      return ERROR;
  for( l_p=l_sSrc ; *l_p && *l_p!=COL_SEP && *l_p!='\n' && *l_p!='\r' ; l_p++ );
  *l_p=0;
  if( GetFileSize( l_sSrc,&l_iSize )==ERROR )
  {
    WriteNotCopied( l_sSrc );
    return OK;
  }
  strcpy( l_sDst,DRIVE_USB );
  strcat( l_sDst,l_sSrc );
  if( UPGCopy( l_sSrc,l_sDst,FALSE )==ERROR )
  {
    WriteNotCopied( l_sSrc );
    return ERROR;
  }
  return l_iSize;
}

int  CopyList ( FILE* p_pList,int p_iTotal )
{
  char  l_s[256];
  int   l_i;
  int   l_iSize;
  int   l_iPerc;
  int   l_iList=0;
  int   l_iLast=ReadLastCopied();

  do
  {
    l_iPerc=0;
    l_iSize=0;
    ShowNavigationBargraph();
    do
    {
      if( l_iSize>=l_iPerc )
      {
        StepBargraph( "Coping...",l_iSize/(MAX_SIZE/100) );
        l_iPerc=l_iSize+(MAX_SIZE/10);
      }
      l_i=CopyFile( p_pList,++l_iLast,l_iList );
      if( l_i==ERROR )
        return ERROR;
      l_iSize+=l_i;
      l_iList=l_iLast;
    }
    while( l_iSize<MAX_SIZE && l_iLast<p_iTotal );

    if( l_iLast>=p_iTotal )
      l_i=NO;
    else
    {
      _itoa( 100*l_iLast/p_iTotal,l_s,10 );
      strcat( l_s,"% done. Continue ?" );
      ShowNavigationQuestionScreen( l_s,&l_i );
    }
  }
  while( l_i==YES );

  WriteLastCopied( l_iLast );
  return OK;
}

int  hd_copy ( void )
{
  char  l_s[256];
  int   l_iAnsw;
  int   l_iLast;
  int   l_iCreate;
  int   l_nFile;
  FILE* l_pList;
  t_longint l_liTotSize;

  l_pList=fopen( USB_LIST_FILE,"r" );
  if( l_pList==NULL )
    l_iCreate=TRUE;
  else
  {
    l_liTotSize.m_unit=0;
    l_liTotSize.m_mega=0;
    l_iLast=ReadLastCopied();

    for( l_nFile=0 ; fgets( l_s,sizeof( l_s ),l_pList )!=NULL ; l_nFile++ )
    {
      if( l_nFile>=l_iLast )
        AddFileSize( &l_liTotSize,atoi( _strchr( l_s,COL_SEP )+1 ) );
    }
    fclose( l_pList );

    if( !l_nFile )
      l_iCreate=TRUE;
    else
    {
      l_iCreate=FALSE;
      strcpy( l_s,"Found existing list. " );
      _itoa( 100*l_iLast/l_nFile,l_s+strlen( l_s ),10 );
      strcat( l_s,"% already copied. Continue ?" );
      ShowNavigationQuestionScreen( l_s,&l_iAnsw );
      if( l_iAnsw==NO )
      {
        ShowNavigationQuestionScreen( "Start another copy ?",&l_iAnsw );
        if( l_iAnsw==NO )
          return OK;
        l_iCreate=TRUE;
      }
    }
  }
  if( l_iCreate==TRUE )
  {
    l_iLast=0;
    l_nFile=0;
    l_liTotSize.m_unit=0;
    l_liTotSize.m_mega=0;

    if( WriteLastCopied( l_iLast )==ERROR || WriteNotCopied( NULL )==ERROR )
      return ERROR;

    l_pList=fopen( USB_LIST_FILE,"wb" );
    if( l_pList==NULL )
      return ERROR;

    ShowNavigationQuestionScreen( "Copy Main Disk ?",&l_iAnsw );
    if( l_iAnsw==YES )
      l_nFile+=CreateList( l_pList,DRIVE_HDD,&l_liTotSize );

    ShowNavigationQuestionScreen( "Copy Flash Disk ?",&l_iAnsw );
    if( l_iAnsw==YES )
      l_nFile+=CreateList( l_pList,DRIVE_TFFS,&l_liTotSize );

    ShowNavigationQuestionScreen( "Copy User Disk ?",&l_iAnsw );
    if( l_iAnsw==YES )
      l_nFile+=CreateList( l_pList,DRIVE_USER,&l_liTotSize );

    ShowNavigationQuestionScreen( "Copy Navy Disk ?",&l_iAnsw );
    if( l_iAnsw==YES )
      l_nFile+=CreateList( l_pList,DRIVE_NAV,&l_liTotSize );

    ShowNavigationQuestionScreen( "Copy Jukebox Disk ?",&l_iAnsw );
    if( l_iAnsw==YES )
      l_nFile+=CreateList( l_pList,DRIVE_JBX,&l_liTotSize );

    fclose( l_pList );
    ShowNavigationBargraph();
    StepBargraph( "List created",100 );
    taskDelay( 1000 );
  }

  if( l_nFile<=0 )
  {
    UPGDelete( USB_LIST_FILE );
    ShowNavigationQuestionScreen( "Empty list, script is aborted",&l_iAnsw );
    return ERROR;
  }

  _itoa( l_nFile-l_iLast,l_s,10 );
  strcat( l_s," files, " );
  if( l_liTotSize.m_mega>1024 )
  {
    _itoa( (l_liTotSize.m_mega+1023)/1024,l_s+strlen( l_s ),10 );
    strcat( l_s,"GByte" );
  }
  else if( l_liTotSize.m_mega )
  {
    _itoa( l_liTotSize.m_mega,l_s+strlen( l_s ),10 );
    strcat( l_s,"MByte" );
  }
  else if( l_liTotSize.m_unit>1024 )
  {
    _itoa( (l_liTotSize.m_unit+1023)/1024,l_s+strlen( l_s ),10 );
    strcat( l_s,"KByte" );
  }
  else
  {
    _itoa( l_liTotSize.m_unit,l_s+strlen( l_s ),10 );
    strcat( l_s,"Byte" );
  }
  strcat( l_s," required. Continue ?" );
  ShowNavigationQuestionScreen( l_s,&l_iAnsw );
  if( l_iAnsw==NO )
    return OK;

  l_pList=fopen( USB_LIST_FILE,"r" );
  if( l_pList==NULL )
    return ERROR;
  l_iAnsw=CopyList( l_pList,l_nFile );
  fclose( l_pList );

  return l_iAnsw;
}

int  main ( int argc, char **argv )
{
  int  l_iAnsw = FALSE;

  if( hd_copy()==ERROR )
    ShowNavigationQuestionScreen( "Copy failed", &l_iAnsw );
  else
    ShowNavigationQuestionScreen( "Copy completed!",&l_iAnsw );

  ClearScreen();
  return OK;
}


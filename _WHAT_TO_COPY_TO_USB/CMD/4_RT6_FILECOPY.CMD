/*
 * RT6_FILECOPY.CMD
 * by mira308sw
 *
 * Copy selected files between USB and RT6
 * ver:01.00  06/04/2011 :  first release
 *
 * Use:
 * The script can run either from USB or CD support.
 * On usb device Must Exist the folders READn and/or WRITEn and/or DELETEn
 * n can be in range 1-9 and Must Be sequential ( ex: READ1,READ2,READ3 )
 * a total of 27 different job (9 read + 9 write + 9 delete) can be programmed
 * simultaneously on the same usb device, the user can decide if execute or not,
 * each single job.
 * inside the READn, WRITEn, DELETEn folder Must Exist the file DESCRIPTION.TXT
 * it contain a brief description of job ( ex: "Copy MAP to RT6" ) that will
 * be displayed to user.
 * also there Must Exist the exact folders structure for the files you want
 * to read/write on RT4 (ex: /READ1/I/USER_DATA/USER_PROFILE/USER_COM.DAT )
 * also if you want read or delete from RT6, a dummy file Must Exist on usb
 * device inside the sub folder of READn or DELETEn.
 * existing files in destination folder are overwritten without confirm.
 * the script execute big job, coping 50 MByte at a time, let the user choice
 * if continue or suspend, copy can be continued the next time user run the script.
 * to save the suspension copy point, the script write the following
 * additional files on usb device:
 * /LASTJOB.TXT: store the last READn or WRITEn used folder
 * /READn|WRITEn|DELETEn/RTCPY_FILELIST.TXT:
 *                        store a complete list of files found in folder
 * /READn|WRITEn|DELETEn/RTCPY_LASTCOPIED.TXT:
 *                        store line number of last copied file in the list.
 * /READn|WRITEn|DELETEn/RTCPY_NOTCOPIED.TXT:
 *                        store files not copied due to read or write error.
 *
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
#define DRIVE_TFFS      "/F"
#define DRIVE_NAV       "/SDH"
#define DRIVE_USER      "/SDI"
#define DRIVE_JBX       "/J"
#define DRIVE_USB       "/bd0"


/*** EXTERN FUNCTION DECLARATIONS ***/

// File operations
STATUS UPGDelete          (char* p_file);
STATUS UPGCopy            (char* p_source, char* p_dest, int p_cut);
int    UPGSearchFile      (char* Filename, char *RootDir, char *Param, char *TableDir );
STATUS UPGGetSearchResult (int index , char *SearchResult );
STATUS GetFileSize        (char* file, int *size);

char*  fgets              (char* buf, size_t n, FILE * fp);
int    fputs              (char* s, FILE * fp);
FILE*  fopen              (char* filename, char * mode );
int    fclose             (FILE* fp);

// String operations
char*  strstr             (char* str, char* substr);
STATUS strcpy             (char* target, char* source);
STATUS strcat             (char* target, char* source);
int    strlen             (char* str);
int    atoi               (char * p_str);

// MMI UPG Panel management
STATUS ClearScreen                  (void);
STATUS ShowNavigationBargraph       (void);
STATUS StepBargraph                 (char *text, int index);
STATUS ShowNavigationQuestionScreen (char *text, int *answer);
void   RebootSystem                 (void);

// Others
STATUS taskDelay          (int ticks);
void*  UPGFindSymbol      ( char *sym );
//STATUS UnprotectHddPartition	( char *drive );



/****************************** RT_COPY ******************************/
#define _1MBYTE                 (1048576)
#define YES                     (1)
#define NO                      (0)
#define BREAK                   (2)
#define MAX_SIZE                (50*_1MBYTE)
#define USB_NOTCOPIED_FILE      "/RTCPY_NOTCOPIED.TXT"
#define USB_LASTCOPIED_FILE     "/RTCPY_LASTCOPIED.TXT"
#define USB_LIST_FILE           "/RTCPY_FILELIST.TXT"
#define USB_DESCR_FILE          "/DESCRIPTION.TXT"
#define USB_READ_DIR            "/bd0/READ"
#define USB_WRITE_DIR           "/bd0/WRITE"
#define USB_DELETE_DIR          "/bd0/DELETE"
#define USB_LASTJOB_FILE        "/bd0/RTCPY_LASTJOB.TXT"
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

int  ReadDescription ( char *p_sPath,char *p_sDescr,int p_iMaxDescr )
{
  FILE *l_pFile;
  char  l_sPath[256];

  strcpy( l_sPath,p_sPath );
  strcat( l_sPath,USB_DESCR_FILE );
  l_pFile=fopen( l_sPath,"r" );
  if( l_pFile==NULL )
    return ERROR;
  fgets( p_sDescr,p_iMaxDescr,l_pFile );
  fclose( l_pFile );
  return OK;
}

int  CreateList ( FILE* p_pList,char* p_sJob,t_longint *p_liSize )
{
  char l_sDescr[256];
  char l_sFile[256];
  char l_sText[256];
  char*l_p;
  int  l_nFile;
  int  l_iSize;
  int  l_i;
  int  l_iPerc;
  int  l_iSkipped=0;

  ReadDescription( p_sJob,l_sDescr,sizeof( l_sDescr ) );
  ShowNavigationBargraph();
  StepBargraph( l_sDescr,0 );

  l_nFile=UPGSearchFile( "*.*",p_sJob,NULL,NULL );
  l_iPerc=l_nFile/10-1;

  for( l_i=0 ; l_i<l_nFile ; l_i++ )
  {
    if( UPGGetSearchResult( l_i,l_sFile )==ERROR ||
        strstr( l_sFile,USB_LIST_FILE )!=NULL ||
        strstr( l_sFile,USB_LASTCOPIED_FILE )!=NULL ||
        strstr( l_sFile,USB_NOTCOPIED_FILE )!=NULL ||
        strstr( l_sFile,USB_DESCR_FILE )!=NULL )
    {
      l_iSkipped++;
    }
    else
    {
      l_p=l_sFile+strlen( p_sJob );
      fputs( l_p,p_pList );
      if( strstr( p_sJob,USB_WRITE_DIR )!=NULL )
        l_p=l_sFile;
      if( GetFileSize( l_p,&l_iSize )!=ERROR )
      {
        l_sFile[0]=COL_SEP;
        _itoa( l_iSize,l_sFile+1,10 );
        fputs( l_sFile,p_pList );
        AddFileSize( p_liSize,l_iSize );
      }
      fputs( "\r\n",p_pList );
      if( l_i>=l_iPerc )
      {
        StepBargraph( l_sDescr,100*(l_i+1)/l_nFile );
        l_iPerc+=l_nFile/10;
      }
    }
  }
  l_nFile-=l_iSkipped;
  _itoa( l_nFile,l_sText,10 );
  strcat( l_sText," files found" );
  StepBargraph( l_sText,100 );
  taskDelay( 1000 );

  return l_nFile;
}

int  ReadLastCopied ( char *p_sPath )
{
  char  l_s[16];
  char *l_sLast;
  FILE *l_pLast;
  char  l_sPath[256];

  strcpy( l_sPath,p_sPath );
  strcat( l_sPath,USB_LASTCOPIED_FILE );
  l_pLast=fopen( l_sPath,"r" );
  if( l_pLast==NULL )
    return 0;
  l_sLast=fgets( l_s,sizeof( l_s ),l_pLast );
  fclose( l_pLast );
  if( l_sLast==NULL )
    return 0;
  return atoi( l_sLast );
}

int  WriteLastCopied ( char *p_sPath,int p_iLast )
{
  char  l_s[16];
  FILE *l_pLast;
  char  l_sPath[256];

  strcpy( l_sPath,p_sPath );
  strcat( l_sPath,USB_LASTCOPIED_FILE );
  l_pLast=fopen( l_sPath,"w" );
  if( l_pLast==NULL )
    return ERROR;
  _itoa( p_iLast,l_s,10 );
  fputs( l_s,l_pLast );
  fputs( "\n",l_pLast );
  fclose( l_pLast );
  return OK;
}

int  WriteNotCopied ( char *p_sPath,char *p_sFile )
{
  FILE *l_pNoCpy;
  char  l_sPath[256];

  strcpy( l_sPath,p_sPath );
  strcat( l_sPath,USB_NOTCOPIED_FILE );

  if( p_sFile )
    l_pNoCpy=fopen( l_sPath,"a" );
  else
    l_pNoCpy=fopen( l_sPath,"w" );

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

int  CopyFile ( FILE* p_pList,int p_i,int p_pLast,char *p_sJob )
{
  char l_sSrc[256];
  char l_sDst[256];
  char l_sFile[256];
  char *l_p;
  int  l_iSize;

  for( ; p_pLast<p_i ; p_pLast++ )
    if( fgets( l_sFile,sizeof( l_sFile ),p_pList )==NULL )
      return ERROR;
  for( l_p=l_sFile ; *l_p && *l_p!=COL_SEP && *l_p!='\n' && *l_p!='\r' ; l_p++ );
  *l_p=0;
  if( strstr( p_sJob,USB_DELETE_DIR )!=NULL )
  {
    UPGDelete( l_sFile );
    return OK;
  }
  if( strstr( p_sJob,USB_READ_DIR )!=NULL )
  {
    strcpy( l_sSrc,l_sFile );
    strcpy( l_sDst,p_sJob );
    strcat( l_sDst,l_sFile );
  }
  if( strstr( p_sJob,USB_WRITE_DIR )!=NULL )
  {
    strcpy( l_sDst,l_sFile );
    strcpy( l_sSrc,p_sJob );
    strcat( l_sSrc,l_sFile );
  }
  if( GetFileSize( l_sSrc,&l_iSize )==ERROR )
  {
    WriteNotCopied( p_sJob,l_sFile );
    return OK;
  }
  if( UPGCopy( l_sSrc,l_sDst,FALSE )==ERROR )
  {
    WriteNotCopied( p_sJob,l_sFile );
    return ERROR;
  }
  return l_iSize;
}

int  CopyList ( FILE* p_pList,int p_iTotal,char *p_sJob )
{
  char  l_sDescr[256];
  char  l_s[256];
  int   l_i;
  int   l_iSize;
  int   l_iPerc;
  int   l_iList=0;
  int   l_iLast=ReadLastCopied( p_sJob );

  ReadDescription( p_sJob,l_sDescr,sizeof( l_sDescr ) );
  do
  {
    l_iPerc=0;
    l_iSize=0;
    ShowNavigationBargraph();
    do
    {
      if( l_iSize>=l_iPerc )
      {
        StepBargraph( l_sDescr,l_iSize/(MAX_SIZE/100) );
        l_iPerc=l_iSize+(MAX_SIZE/10);
      }
      l_i=CopyFile( p_pList,++l_iLast,l_iList,p_sJob );
      if( l_i==ERROR )
      {
        WriteLastCopied( p_sJob,l_iLast-1 );
        return ERROR;
      }
      l_iSize+=l_i;
      l_iList=l_iLast;
    }
    while( l_iSize<MAX_SIZE && l_iLast<p_iTotal );

    if( l_iLast>=p_iTotal )
      l_i=-1;
    else
    {
      _itoa( 100*l_iLast/p_iTotal,l_s,10 );
      strcat( l_s,"% done. Continue ?" );
      ShowNavigationQuestionScreen( l_s,&l_i );
    }
  }
  while( l_i==YES );

  WriteLastCopied( p_sJob,l_iLast );
  return ( l_i<0 ? OK : BREAK );
}

int  ReadLastJob ( char *p_sJob,int p_iMaxJob )
{
  FILE *l_pLast;
  l_pLast=fopen( USB_LASTJOB_FILE,"r" );
  if( l_pLast==NULL )
    return ERROR;
  fgets( p_sJob,p_iMaxJob,l_pLast );
  fclose( l_pLast );
  return OK;
}

int  WriteLastJob ( char *p_sJob )
{
  FILE *l_pLast;
  l_pLast=fopen( USB_LASTJOB_FILE,"w" );
  if( l_pLast==NULL )
    return ERROR;
  fputs( p_sJob,l_pLast );
  fclose( l_pLast );
  return OK;
}

int ExecuteJob ( char *p_sJob )
{
  char  l_sList[256];
  char  l_sText[256];
  char  l_s[256];
  int   l_iAnsw;
  int   l_iLast;
  int   l_iCreate;
  int   l_nFile;
  int   l_i;
  FILE* l_pList;
  t_longint l_liTotSize;

  strcpy( l_sList,p_sJob );
  strcat( l_sList,USB_LIST_FILE );
  l_pList=fopen( l_sList,"r" );
  if( l_pList==NULL )
    l_iCreate=TRUE;
  else
  {
    l_liTotSize.m_unit=0;
    l_liTotSize.m_mega=0;
    l_iLast=ReadLastCopied( p_sJob );

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
      ReadDescription( p_sJob,l_s,sizeof( l_s ) );
      strcat( l_s,": " );
      _itoa( 100*l_iLast/l_nFile,l_s+strlen( l_s ),10 );
      strcat( l_s,"% already copied. Continue ?" );
      ShowNavigationQuestionScreen( l_s,&l_iAnsw );
      if( l_iAnsw==NO )
      {
        ShowNavigationQuestionScreen( "Abort and run next Job?",&l_iAnsw );
        if( l_iAnsw==YES )
          return OK;
        else
          return BREAK;
       }
    }
  }
  if( l_iCreate==TRUE )
  {
    l_iLast=0;
    l_nFile=0;
    l_liTotSize.m_unit=0;
    l_liTotSize.m_mega=0;

    if( WriteLastCopied( p_sJob,l_iLast )==ERROR ||
        WriteNotCopied( p_sJob,NULL )==ERROR )
      return ERROR;

    strcpy( l_sText,"Execute: " );
    l_i=strlen( l_sText );
    if( ReadDescription( p_sJob,l_sText+l_i,sizeof( l_sText )-l_i )!=OK )
      return OK;
    strcat( l_sText," ?" );
    ShowNavigationQuestionScreen( l_sText,&l_iAnsw );
    if( l_iAnsw==NO )
      return OK;

    l_pList=fopen( l_sList,"wb" );
    if( l_pList==NULL )
      return ERROR;
    l_nFile+=CreateList( l_pList,p_sJob,&l_liTotSize );
    fclose( l_pList );

    if( l_nFile<=0 )
    {
      UPGDelete( l_sList );
      ShowNavigationQuestionScreen( "Empty list, script is aborted",&l_iAnsw );
      return ERROR;
    }
  }
  WriteLastJob( p_sJob );

  if( strstr( p_sJob,USB_DELETE_DIR )!=NULL )
  {
    _itoa( l_nFile-l_iLast,l_s,10 );
    strcat( l_s," files to delete. Continue ?" );
  }
  else
  {
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
  }
  ShowNavigationQuestionScreen( l_s,&l_iAnsw );
  if( l_iAnsw==NO )
  {
    ShowNavigationQuestionScreen( "Abort and Run next Job?",&l_iAnsw );
    if( l_iAnsw==YES )
      return OK;
    else
      return BREAK;
  }
  l_pList=fopen( l_sList,"r" );
  if( l_pList==NULL )
    return ERROR;
  l_iAnsw=CopyList( l_pList,l_nFile,p_sJob );
  fclose( l_pList );

  return l_iAnsw;
}

int  InitializeJob ( char *p_sJob )
{
  char l_sFile[256];

  strcpy( l_sFile,p_sJob );
  strcat( l_sFile,USB_LIST_FILE );
  UPGDelete( l_sFile );
  strcpy( l_sFile,p_sJob );
  strcat( l_sFile,USB_LASTCOPIED_FILE );
  UPGDelete( l_sFile );
  strcpy( l_sFile,p_sJob );
  strcat( l_sFile,USB_NOTCOPIED_FILE );
  UPGDelete( l_sFile );
  return OK;
}

int  SearchNextJob ( char *p_sJob )
{
  char l_sDescr[256];
  char *l_p=p_sJob+strlen( p_sJob )-1;
  if( *l_p<'9' )
  {
    (*l_p)++;
    if( ReadDescription( p_sJob,l_sDescr,sizeof( l_sDescr ) )==OK )
      return InitializeJob( p_sJob );
  }
  if( strstr( p_sJob,USB_READ_DIR ) )
  {
    strcpy( p_sJob,USB_WRITE_DIR );
    strcat( p_sJob,"1" );
    if( ReadDescription( p_sJob,l_sDescr,sizeof( l_sDescr ) )==OK )
      return InitializeJob( p_sJob );
  }
  if( strstr( p_sJob,USB_WRITE_DIR ) )
  {
    strcpy( p_sJob,USB_DELETE_DIR );
    strcat( p_sJob,"1" );
    if( ReadDescription( p_sJob,l_sDescr,sizeof( l_sDescr ) )==OK )
      return InitializeJob( p_sJob );
  }
  return ERROR;
}

int  SearchFirstJob ( char *p_sJob )
{
  char l_sDescr[256];
  strcpy( p_sJob,USB_READ_DIR );
  strcat( p_sJob,"1" );
  if( ReadDescription( p_sJob,l_sDescr,sizeof( l_sDescr ) )==OK )
    return InitializeJob( p_sJob );
  strcpy( p_sJob,USB_WRITE_DIR );
  strcat( p_sJob,"1" );
  if( ReadDescription( p_sJob,l_sDescr,sizeof( l_sDescr ) )==OK )
    return InitializeJob( p_sJob );
  strcpy( p_sJob,USB_DELETE_DIR );
  strcat( p_sJob,"1" );
  if( ReadDescription( p_sJob,l_sDescr,sizeof( l_sDescr ) )==OK )
    return InitializeJob( p_sJob );
  return ERROR;
}

int  rt_copy ( void )
{
  char  l_sJob[256];
  int   l_i;

  if( ReadLastJob( l_sJob,sizeof( l_sJob ) )!=OK )
    if( SearchFirstJob( l_sJob )!=OK )
      return ERROR;
  do
  {
    l_i=ExecuteJob( l_sJob );
    if( l_i!=OK )
      return l_i;
  }
  while( SearchNextJob( l_sJob )==OK );

  UPGDelete( USB_LASTJOB_FILE );
  return OK;
}

int  main ( int argc, char **argv )
{
  int  l_iAnsw = FALSE;

//  if( ERROR==UnprotectHddPartition( DRIVE_HDD ) )
//    ShowNavigationQuestionScreen( "Unable to unprotect " DRIVE_HDD,&l_iAnsw );

  switch( rt_copy() )
  {
  case ERROR:
    ShowNavigationQuestionScreen( "Copy failed!", &l_iAnsw );
    break;
  case OK:
    ShowNavigationQuestionScreen( "Copy completed. Reboot ?",&l_iAnsw );
    if( l_iAnsw==YES )
      RebootSystem();
    break;
  case BREAK:
    ShowNavigationQuestionScreen( "Copy halted by user!",&l_iAnsw );
    break;
  }
  ClearScreen();
  return OK;
}


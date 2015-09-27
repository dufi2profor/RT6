/*
 * RT6_usercom.exe  -  written by mira308sw
 *
 * script to read/write user_com.dat file from usb devide.
 *
 *  v01.00	06/04/2011	-
 *  v01.01	19/06/2012	- copy all .dat files
 *  v01.02	01/04/2013	- fixed bug in check if .dat is present on source disk
 *  v01.03	18/07/2013	- test with call to unprotecthddpartition
 *  v01.04	01/11/2013	- remove reboot at the end
 */

#define RTX_DIR       "/SDI/USER_DATA/User_profile"
#define USB_DIR       "/bd0"
#define COM_FILE      "/User_com.dat"
#define CONFIG_FILE   "/User_config.dat"
#define USER1_FILE    "/User_1.dat"
#define USER2_FILE    "/User_2.dat"
#define USER3_FILE    "/User_3.dat"
#define USER4_FILE    "/User_4.dat"
#define INF_FILE(file)   file ".inf"

#define NO            0
#define YES           1
#define OK            0
#define ERROR        -1

int     GetFileSize (char* file, int* size);
int     ShowNavigationQuestionScreen (char* text, int* answer);
int     UPGCopy ( char *src,char *dst,int cut );
void    RebootSystem ( void );

void*   UPGFindSymbol       ( char *sym );
int     AddUPGHistoryCommentary	 ( void *funptr,... );   // max 7 parameters
#define GFC                             AddUPGHistoryCommentary
#define UNPROTECTHDDPARTITION(p)        GFC( UPGFindSymbol( "UnprotectHddPartition__FPCc" ),p )


int   main ( int argc,char* argv[] )
{
  int   size;
  int   answ=NO;

  if( GetFileSize( USB_DIR COM_FILE,&size )==OK ||
      GetFileSize( USB_DIR CONFIG_FILE,&size )==OK ||
      GetFileSize( USB_DIR USER1_FILE,&size )==OK ||
      GetFileSize( USB_DIR USER2_FILE,&size )==OK ||
      GetFileSize( USB_DIR USER3_FILE,&size )==OK ||
      GetFileSize( USB_DIR USER4_FILE,&size )==OK )
    ShowNavigationQuestionScreen( "WRITE files user_???.dat to RT6 ?",&answ );

  if( answ==YES )
  {
/*  
    if( OK==UNPROTECTHDDPARTITION( "/SDI" ) )
       ShowNavigationQuestionScreen( "UnprotectHDD return OK",&answ );
    else
       ShowNavigationQuestionScreen( "UnprotectHDD return ERROR",&answ );
*/       
    UPGCopy(           USB_DIR COM_FILE,            RTX_DIR COM_FILE  ,0 );
    UPGCopy( INF_FILE( USB_DIR COM_FILE ),INF_FILE( RTX_DIR COM_FILE ),0 );
    UPGCopy(           USB_DIR CONFIG_FILE,            RTX_DIR CONFIG_FILE  ,0 );
    UPGCopy( INF_FILE( USB_DIR CONFIG_FILE ),INF_FILE( RTX_DIR CONFIG_FILE ),0 );
    UPGCopy(           USB_DIR USER1_FILE,            RTX_DIR USER1_FILE  ,0 );
    UPGCopy( INF_FILE( USB_DIR USER1_FILE ),INF_FILE( RTX_DIR USER1_FILE ),0 );
    UPGCopy(           USB_DIR USER2_FILE,            RTX_DIR USER2_FILE  ,0 );
    UPGCopy( INF_FILE( USB_DIR USER2_FILE ),INF_FILE( RTX_DIR USER2_FILE ),0 );
    UPGCopy(           USB_DIR USER3_FILE,            RTX_DIR USER3_FILE  ,0 );
    UPGCopy( INF_FILE( USB_DIR USER3_FILE ),INF_FILE( RTX_DIR USER3_FILE ),0 );
    UPGCopy(           USB_DIR USER4_FILE,            RTX_DIR USER4_FILE  ,0 );
    UPGCopy( INF_FILE( USB_DIR USER4_FILE ),INF_FILE( RTX_DIR USER4_FILE ),0 );
    ShowNavigationQuestionScreen( "Files copied. Reboot with EJECT long press.",&answ );
  }
  else
  {
    ShowNavigationQuestionScreen( "READ files user_???.dat from RT6?",&answ );
    if( answ==YES )
    {
      UPGCopy(           RTX_DIR COM_FILE,            USB_DIR COM_FILE  ,0 );
      UPGCopy( INF_FILE( RTX_DIR COM_FILE ),INF_FILE( USB_DIR COM_FILE ),0 );
      UPGCopy(           RTX_DIR CONFIG_FILE,            USB_DIR CONFIG_FILE  ,0 );
      UPGCopy( INF_FILE( RTX_DIR CONFIG_FILE ),INF_FILE( USB_DIR CONFIG_FILE ),0 );
      UPGCopy(           RTX_DIR USER1_FILE,            USB_DIR USER1_FILE  ,0 );
      UPGCopy( INF_FILE( RTX_DIR USER1_FILE ),INF_FILE( USB_DIR USER1_FILE ),0 );
      UPGCopy(           RTX_DIR USER2_FILE,            USB_DIR USER2_FILE  ,0 );
      UPGCopy( INF_FILE( RTX_DIR USER2_FILE ),INF_FILE( USB_DIR USER2_FILE ),0 );
      UPGCopy(           RTX_DIR USER3_FILE,            USB_DIR USER3_FILE  ,0 );
      UPGCopy( INF_FILE( RTX_DIR USER3_FILE ),INF_FILE( USB_DIR USER3_FILE ),0 );
      UPGCopy(           RTX_DIR USER4_FILE,            USB_DIR USER4_FILE  ,0 );
      UPGCopy( INF_FILE( RTX_DIR USER4_FILE ),INF_FILE( USB_DIR USER4_FILE ),0 );
      ShowNavigationQuestionScreen( "Copy completed.",&answ );
    }
    else
      ShowNavigationQuestionScreen( "Finish.",&answ );
  }
  return OK;
}

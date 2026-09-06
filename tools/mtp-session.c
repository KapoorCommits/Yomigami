
/* Local USB transfer helper using Amazon's installed libmtp. No delete command. */
#include "libmtp.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
static LIBMTP_mtpdevice_t *dev;
static uint32_t storage;
static int exists(uint32_t parent,const char *name) {
    LIBMTP_file_t *f=LIBMTP_Get_Files_And_Folders(dev,storage,parent),*next;int found=0;
    while(f){next=f->next;if(!strcmp(f->filename,name))found=1;LIBMTP_destroy_file_t(f);f=next;}return found;
}
int main(void) {
    setbuf(stdout,NULL);setbuf(stderr,NULL);LIBMTP_Init();
    LIBMTP_raw_device_t *raw=NULL;int n=0;
    int err=LIBMTP_Detect_Raw_Devices(&raw,&n);
    if(err||!n){fprintf(stderr,"No MTP device (%d)\n",err);return 1;}
    for(int i=0;i<n;i++)if(raw[i].device_entry.vendor_id==0x1949){dev=LIBMTP_Open_Raw_Device_Uncached(&raw[i]);break;}
    free(raw);if(!dev){fprintf(stderr,"Cannot open Kindle USB session\n");return 2;}
    if(LIBMTP_Get_Storage(dev,0)||!dev->storage){fprintf(stderr,"Cannot read storage\n");return 3;}
    storage=dev->storage->id;
    printf("READY storage=%u free=%llu\n",storage,(unsigned long long)dev->storage->FreeSpaceInBytes);
    char line[4096];
    while(fgets(line,sizeof(line),stdin)) {
        line[strcspn(line,"\r\n")]=0;
        char *cmd=strtok(line,"\t"),*a=strtok(NULL,"\t"),*b=strtok(NULL,"\t"),*c=strtok(NULL,"\t");
        if(!cmd)continue;
        if(!strcmp(cmd,"quit"))break;
        if(!strcmp(cmd,"ls")&&a){
            LIBMTP_file_t *f=LIBMTP_Get_Files_And_Folders(dev,storage,(uint32_t)strtoul(a,NULL,10)),*next;
            while(f){next=f->next;printf("%u\t%s\t%llu\t%s\n",f->item_id,f->filetype==LIBMTP_FILETYPE_FOLDER?"DIR":"FILE",(unsigned long long)f->filesize,f->filename);LIBMTP_destroy_file_t(f);f=next;}
        }else if(!strcmp(cmd,"get")&&a&&b){
            struct stat st;if(!stat(b,&st)){puts("ERROR local destination exists");continue;}
            printf("GET %d\n",LIBMTP_Get_File_To_File(dev,(uint32_t)strtoul(a,NULL,10),b,NULL,NULL));
        }else if(!strcmp(cmd,"mkdir")&&a&&b){
            uint32_t parent=(uint32_t)strtoul(a,NULL,10);
            if(exists(parent,b)){puts("ERROR remote destination exists");continue;}
            printf("MKDIR %u\n",LIBMTP_Create_Folder(dev,b,parent==0xffffffff?0:parent,storage));
        }else if(!strcmp(cmd,"put")&&a&&b&&c){
            uint32_t parent=(uint32_t)strtoul(a,NULL,10);struct stat st;
            if(exists(parent,c)||stat(b,&st)||!S_ISREG(st.st_mode)){puts("ERROR exists or invalid file");continue;}
            LIBMTP_file_t *f=LIBMTP_new_file_t();f->parent_id=parent==0xffffffff?0:parent;f->storage_id=storage;f->filename=strdup(c);f->filesize=st.st_size;f->filetype=LIBMTP_FILETYPE_UNKNOWN;
            int result=LIBMTP_Send_File_From_File(dev,b,f,NULL,NULL);printf("PUT %d id=%u bytes=%llu\n",result,f->item_id,(unsigned long long)f->filesize);LIBMTP_destroy_file_t(f);
        }else puts("ERROR unknown command");
        LIBMTP_Dump_Errorstack(dev);LIBMTP_Clear_Errorstack(dev);puts("DONE");
    }
    LIBMTP_Release_Device(dev);return 0;
}

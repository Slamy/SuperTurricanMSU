#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>

struct wave
{
	unsigned char *rawPCM;
	unsigned int len;
	unsigned int numberOfSamples;
};

struct wave intro={0,0,0};
struct wave loop={0,0,0};


void readWave(char *path, struct wave *wav)
{
	int expectedFileSize=0;
	
	char *fileEnding=path+strlen(path)-4;
	assert(!strcmp(fileEnding,".wav"));
	
	unsigned int wavHeaderInt[25];
	unsigned short *wavHeaderShort=(unsigned short*)wavHeaderInt;
	unsigned char *wavHeaderChar=(unsigned char*)wavHeaderInt;
	
	FILE *f=fopen(path,"rb");
	assert(f);
	
	expectedFileSize=36-16;
	int bytesRead=fread(wavHeaderChar,1,36,f); //Lese den ersten Header und sofort den ersten Chunk. Dieser muss "fmt " sein.
	assert(bytesRead==36);
	
	assert(wavHeaderChar[0]=='R');
	assert(wavHeaderChar[1]=='I');
	assert(wavHeaderChar[2]=='F');
	assert(wavHeaderChar[3]=='F');
	
	assert(wavHeaderChar[8]=='W');
	assert(wavHeaderChar[9]=='A');
	assert(wavHeaderChar[10]=='V');
	assert(wavHeaderChar[11]=='E');
	
	int fileSize=wavHeaderInt[4>>2];
	
	assert(wavHeaderChar[12]=='f');
	assert(wavHeaderChar[13]=='m');
	assert(wavHeaderChar[14]=='t');
	assert(wavHeaderChar[15]==' ');
	
	int fmtLength=wavHeaderInt[16>>2];
	int formatTag=wavHeaderShort[20>>1];
	int channels=wavHeaderShort[22>>1];
	int sampleRate=wavHeaderInt[24>>2];
	int bytesPerSecond=wavHeaderInt[28>>2];
	int blockAlign=wavHeaderShort[32>>1];
	int bitsPerSample=wavHeaderShort[34>>1];
	
	//printf("Samplerate: %d\n",sampleRate);
	assert(fmtLength==16);
	assert(formatTag==1); //PCM
	assert(channels==2);
	assert(sampleRate==44100);
	assert(bytesPerSecond==44100*2*2); //SampleRate * Kanäle * SampleSize
	assert(blockAlign==4);
	assert(bitsPerSample==16);
	
	for(;;)
	{
		expectedFileSize+=8;
		bytesRead=fread(wavHeaderChar,1,8,f); //Lese Typ und Größe des nächsten Chunks
		if (bytesRead==0) //wenn es exakt stimmt, ist alles ok.
			break;
		
		assert(bytesRead==8);
		
		int dataBlockSize=wavHeaderInt[4>>2];
		expectedFileSize+=dataBlockSize;
		
		if (!memcmp(wavHeaderChar,"data",4))
		{
			wav->rawPCM=malloc(dataBlockSize);
			assert(wav->rawPCM);
			
			
			bytesRead=fread(wav->rawPCM,1,dataBlockSize,f);
			assert(bytesRead==dataBlockSize);
			wav->len=dataBlockSize;
			wav->numberOfSamples=dataBlockSize/blockAlign;
		}
		else if (!memcmp(wavHeaderChar,"LIST",4))
		{
			//Brauchen wir nicht. Einfach überspringen.
			assert(!fseek(f,dataBlockSize,SEEK_CUR));
		}
		else if (!memcmp(wavHeaderChar,"id3 ",4))
		{
			//Brauchen wir nicht. Einfach überspringen.
			assert(!fseek(f,dataBlockSize,SEEK_CUR));
		}
		else
		{
			wavHeaderChar[5]='\0';
			printf("Unbekannter Block:%s\n",wavHeaderChar);
			assert(0);
		}
		
		
		//printf("block align: %d\n",blockAlign);
		//printf("dataBlockSize: %d\n",dataBlockSize);
		//printf("fileSize: %d\n",fileSize);
		//assert(dataBlockSize-8 ==fileSize-44);
	}
	
	//printf("fileSize: %d\nexpectedFileSize: %d\n",fileSize,expectedFileSize);
	
	assert(fileSize==expectedFileSize);
	
	fclose(f);
}

void writeMSUfile(char *path)
{
	char *fileEnding=path+strlen(path)-4;
	assert(!strcmp(fileEnding,".pcm"));
	
	FILE *f=fopen(path,"wb");
	assert(f);
	
	int bytesWritten;
	
	bytesWritten=fwrite("MSU1",1,4,f);
	assert(bytesWritten==4);
	
	int loopPoint;
	
	if (intro.rawPCM) //Gibt es kein Intro?
		loopPoint=intro.numberOfSamples;
	else
		loopPoint=0;
	
	bytesWritten=fwrite(&loopPoint,1,4,f);
	assert(bytesWritten==4);
	
	
	if (intro.rawPCM) 
	{
		bytesWritten=fwrite(intro.rawPCM,1,intro.len,f);
		assert(bytesWritten==intro.len);
	}
	
	assert(loop.rawPCM);
	
	bytesWritten=fwrite(loop.rawPCM,1,loop.len,f);
	assert(bytesWritten==loop.len);
		
	fclose(f);
}

int main(int argc, char **argv)
{
	
	if (argc==3)
	{
		readWave(argv[1],&loop);
		writeMSUfile(argv[2]);
		printf("[ %s ] -> %s\n",argv[1],argv[2]);
	}
	else if (argc==4)
	{
		readWave(argv[1],&intro);
		readWave(argv[2],&loop);
		writeMSUfile(argv[3]);
		printf("%s [ %s ] -> %s\n",argv[1],argv[2],argv[3]);
	}
	else
	{
		printf("Brauche Parameter!\n");
		return 2;
	}
	
	return 0;
}

#include <stdio.h>

void fileaddr(unsigned int addr) {

	unsigned int addr2;
	
	addr2 = ((addr & 0x7f0000) >> 1) + (addr & 0x7fff);
	printf("virtuell %x -> physical %x\n",addr,addr2);
}

void archaddr(unsigned int addr) {

	unsigned int addr2;
	
	addr2 = ((addr & 0x7f8000) << 1) + 0x8000 + (addr & 0x7fff);
	printf("physical %x -> virtuell %x\n",addr,addr2);
}


int main()
{
	fileaddr(0x0c8006);
	fileaddr(0x5fb0+0x8000);
	
	archaddr(0x5fb0);
	archaddr(0x07ea0);
	
	fileaddr(0xac43a);
	
	archaddr(1088);
	archaddr(1199);
	archaddr(2122);
	archaddr(6897);
	fileaddr(0x0c8191);
	
	archaddr(563);
	archaddr(70160);
	archaddr(180728);
	archaddr(220169);
	archaddr(223143);
	archaddr(397184);
	
	archaddr(397215);
	archaddr(397221);
	
	
	
	
	return 0;
}
#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main(int argc, char* argv[])
{
	FILE *fptr;
	char* filename;
	char* writestr;

	syslog(LOG_USER, "Writing utility running.");

	if (argc != 3)
	{
		syslog(LOG_ERR, "Utility takes two arguments.");
		return 1;
	}

	filename = argv[1];
	writestr = argv[2];
	printf("Writing %s to file %s\n", writestr, filename);

	syslog(LOG_DEBUG, "Writing %s to file %s", writestr, filename);
	fptr = fopen(filename, "w+");
	fprintf(fptr, "%s", writestr);

	fclose(fptr);

	return 0;
}

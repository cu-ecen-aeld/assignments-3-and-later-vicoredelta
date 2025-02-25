#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main(int argc, char* argv[])
{
	FILE *fptr;
	char* filename;
	char* writestr;
	
	openlog(NULL, 0, LOG_USER);

	if (argc != 3)
	{
		syslog(LOG_ERR, "Utility takes two arguments.");
		return 1;
	}

	filename = argv[1];
	writestr = argv[2];

	syslog(LOG_DEBUG, "Writing %s to file %s", writestr, filename);
	fptr = fopen(filename, "w");
	fprintf(fptr, "%s", writestr);

	fclose(fptr);
	closelog();

	return 0;
}

  int debugFlag = 0;
  int prefixIndex = 0;
  int infectedFlag = 0;
  char buffer[BUFFER_SIZE];

  int i = 0;
  while (i < argc) { /* Check Modes */
    if (strcmp(argv[i], "-D") == 0)
      debugFlag = 1;
    else if (strncmp(argv[i], "-p", 2) == 0)
      prefixIndex = i;
    else if (strncmp(argv[i], "-a", 2) == 0)
      infectedFlag = 1;
    i++;
  }

  int fileDesc = system_call(SYS_OPEN, ".", O_RDONLY, 0777); /* exit if not opened */
  if (debugFlag == 1)
      debugPrint(SYS_OPEN, fileDesc);
  
  int wirtenBytes = system_call(SYS_GETDENTS, fileDesc, buffer, BUFFER_SIZE);
  if (debugFlag == 1)
      debugPrint(SYS_GETDENTS, wirtenBytes);

  i = 0;
  while (i < wirtenBytes) {
    struct ent* entity = (struct ent *)(buffer + i);
    if (prefixIndex > 0) {
      if (strncmp(entity->buf, argv[prefixIndex] + 2, strlen(argv[prefixIndex] + 2)) == 0) {
        char* type = buffer + i + entity->len - 1;
        int j = *type;

        printToStdFile(STDOUT, entity->buf);
        printToStdFile(STDOUT, "\t\t");
        printToStdFile(STDOUT, itoa(j));
        printToStdFile(STDOUT, "\n");
        if (debugFlag == 1)
          debugPrint(SYS_WRITE, 1);
      }
    } else {
      char* type = buffer + i + entity->len - 1;
      int j = *type;

      printToStdFile(STDOUT, entity->buf);
      printToStdFile(STDOUT, "\t\t");
      printToStdFile(STDOUT, itoa(j));
      printToStdFile(STDOUT, "\n");
      if (debugFlag == 1)
        debugPrint(SYS_WRITE, 1);
    }
    i += entity->len;
  }
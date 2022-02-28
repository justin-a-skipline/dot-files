#ifndef PYTHON_RT_GRAPH_H
#define PYTHON_RT_GRAPH_H

#include "stdio.h"
#include "unistd.h"

#define EASY_PRINTF(value) printf("\n" #value ": %f", (float)value)

#define GRAPHPRINTF1(value) do { \
	char text[150]; \
	int count = snprintf(text, sizeof(text), "\r\rRTGRAPH add " #value " %f\n", (float)(value)); \
	if (count > 0) write(9, text, (size_t)count); \
	} while (0)

#define GRAPHPRINTF2(value, x_value) do { \
	char text[150]; \
	int count = snprintf(text, sizeof(text), "\r\rRTGRAPH add " #value " %f %f\n", (float)(value), (float)(x_value)); \
	if (count > 0) write(9, text, (size_t)count); \
	} while (0)

#define GRAPHPRINTF_TIMESTAMP(value) do { \
	char text[150]; \
	int count = snprintf(text, sizeof(text), "\r\rRTGRAPH add_time " #value " %f\n", (float)(value)); \
	if (count > 0) write(9, text, (size_t)count); \
	} while (0)

#endif

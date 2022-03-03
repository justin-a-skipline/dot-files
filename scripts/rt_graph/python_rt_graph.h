#ifndef PYTHON_RT_GRAPH_H
#define PYTHON_RT_GRAPH_H

#include "stdio.h"
#include "unistd.h"

#define EASY_PRINTF(value) printf("\n" #value ": %f", (float)value)

#define GRAPHPRINTF1(value) do { \
	printf("\r\rRTGRAPH add " #value " %f\n", (float)(value)); \
	} while (0)

#define GRAPHPRINTF2(value, x_value) do { \
	printf("\r\rRTGRAPH add " #value " %f %f\n", (float)(value), (float)(x_value)); \
	} while (0)

#define GRAPHPRINTF_TIMESTAMP(value) do { \
	printf("\r\rRTGRAPH add_time " #value " %f\n", (float)(value)); \
	} while (0)

#endif

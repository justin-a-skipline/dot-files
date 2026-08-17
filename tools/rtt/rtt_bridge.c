/*
 * Copyright (C) Skip-Line, Inc. of La Grande, Oregon.
 * Proprietary and Confidential.  All Rights Reserved.
 * Unauthorized copying of this file, via any medium, is strictly prohibited.
 *
 */

/**
 * @file rtt_bridge.c
 *
 * @date Apr 21 2026
 * @author justin-a
 * @brief Bidirectional RTT to stdin/stdout bridge for testing
 *
 * This program bridges RTT Channel 0 to stdin/stdout for bidirectional
 * communication. Used for testing when UART is not available.
 *
 * Usage: rtt_bridge | nc -l 12345
 *   - Reads from RTT Channel 0, writes to stdout
 *   - Reads from stdin, writes to RTT Channel 0
 *   - Fully bidirectional
 */

#include <SEGGER_RTT.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#define BUFFER_SIZE 1024
#define RTT_CHANNEL 0

/**
 * @brief Set stdin to non-blocking mode
 */
static void set_nonblock(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags == -1) {
        perror("fcntl F_GETFL");
        exit(1);
    }
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

/**
 * @brief Main bridge loop
 */
int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;

    unsigned char buffer[BUFFER_SIZE];
    ssize_t bytes_read;
    int has_rtt = 0;

    printf("RTT Bidirectional Bridge\n");
    printf("=========================\n");

    // Initialize RTT
    SEGGER_RTT_Init();

    // Configure RTT channels if not already configured by target
    SEGGER_RTT_ConfigUpBuffer(RTT_CHANNEL, NULL, NULL, 0, SEGGER_RTT_MODE_NO_BLOCK_SKIP);
    SEGGER_RTT_ConfigDownBuffer(RTT_CHANNEL, NULL, NULL, 0, SEGGER_RTT_MODE_NO_BLOCK_SKIP);

    printf("RTT initialized on Channel %d\n", RTT_CHANNEL);
    printf("Starting bidirectional bridge...\n");
    fflush(stdout);

    // Set stdin to non-blocking
    set_nonblock(STDIN_FILENO);

    // Set stdout to unbuffered for immediate transmission
    setvbuf(stdout, NULL, _IONBF, 0);

    // Main bridge loop
    while (1) {
        // Direction 1: RTT → stdout (MCU → network)
        bytes_read = SEGGER_RTT_Read(RTT_CHANNEL, buffer, BUFFER_SIZE);
        if (bytes_read > 0) {
            if (write(STDOUT_FILENO, buffer, bytes_read) != bytes_read) {
                perror("write to stdout");
                break;
            }
            if (!has_rtt) {
                fprintf(stderr, "\n✓ Receiving data from MCU via RTT\n");
                has_rtt = 1;
            }
        }

        // Direction 2: stdin → RTT (network → MCU)
        bytes_read = read(STDIN_FILENO, buffer, BUFFER_SIZE);
        if (bytes_read > 0) {
            int written = SEGGER_RTT_Write(RTT_CHANNEL, buffer, bytes_read);
            if (written != bytes_read) {
                fprintf(stderr, "Warning: Only wrote %d/%zd bytes to RTT\n", written, bytes_read);
            }
            if (!has_rtt) {
                fprintf(stderr, "\n✓ Sending data to MCU via RTT\n");
            }
        } else if (bytes_read < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
            // Error reading stdin (not just "no data")
            perror("read from stdin");
            break;
        }

        // Small sleep to prevent busy-waiting
        usleep(1000); // 1ms
    }

    return 0;
}

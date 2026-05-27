// C reference for ada-ccv smoke test.
//
// Calls ccv_read_impl + ccv_flip the same way the Ada binding does.
// If this works, the bug is in Ada's FFI. If this also crashes,
// CCV itself has an issue with how we're calling it.
//
// Build:
//   clang c-ref.c -I/Users/tony/dev/ccv/lib \
//                 -L/Users/tony/dev/ccv/lib -lccv \
//                 -framework Accelerate -lpthread -o c-ref
// Run:
//   ./c-ref fixtures/book.bmp

#include <stdio.h>
#include <stdlib.h>
#include "ccv.h"

int main(int argc, char** argv) {
    const char* path = argc > 1 ? argv[1] : "fixtures/book.bmp";
    printf("c-ref: opening %s\n", path);

    ccv_enable_default_cache();

    // ===== Test 1: ccv_read_impl directly, mirroring Ada =====
    ccv_dense_matrix_t* mat = NULL;
    int rc = ccv_read_impl(path, &mat, CCV_IO_ANY_FILE | CCV_IO_RGB_COLOR, 0, 0, 0);
    printf("ccv_read_impl returned %d  (CCV_IO_FINAL=%d)\n", rc, CCV_IO_FINAL);
    printf("matrix pointer: %p\n", (void*)mat);

    if (mat == NULL) {
        printf("ccv_read_impl returned non-null status but mat is NULL — bad.\n");
        ccv_drain_cache();
        return 1;
    }

    // ===== Test 2: ccv_flip on the loaded matrix =====
    ccv_dense_matrix_t* flipped = NULL;
    ccv_flip(mat, &flipped, 0, CCV_FLIP_X);
    printf("ccv_flip done. flipped pointer: %p\n", (void*)flipped);

    if (flipped != NULL) {
        // ===== Test 3: write the result =====
        size_t len = 0;
        int wrc = ccv_write(flipped, "c-ref-output.bmp", &len, CCV_IO_BMP_FILE, NULL);
        printf("ccv_write returned %d, wrote %zu bytes\n", wrc, len);
        ccv_matrix_free(flipped);
    }

    ccv_matrix_free(mat);
    ccv_drain_cache();
    printf("c-ref: done.\n");
    return 0;
}

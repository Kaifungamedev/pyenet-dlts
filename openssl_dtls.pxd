"""OpenSSL DTLS C API declarations for pyenet."""

cdef extern from "openssl/ssl.h" nogil:
    ctypedef struct SSL_CTX
    ctypedef struct SSL
    ctypedef struct SSL_METHOD

    # DTLS methods
    const SSL_METHOD* DTLS_method()
    const SSL_METHOD* DTLS_server_method()
    const SSL_METHOD* DTLS_client_method()

    # Context lifecycle
    SSL_CTX* SSL_CTX_new(const SSL_METHOD *method)
    void SSL_CTX_free(SSL_CTX *ctx)
    long SSL_CTX_set_options(SSL_CTX *ctx, long options)
    int SSL_CTX_set_cipher_list(SSL_CTX *ctx, const char *str)

    # Context certificate/key
    int SSL_CTX_use_certificate_file(SSL_CTX *ctx, const char *file, int type)
    int SSL_CTX_use_PrivateKey_file(SSL_CTX *ctx, const char *file, int type)
    int SSL_CTX_check_private_key(SSL_CTX *ctx)

    # Context verification
    void SSL_CTX_set_verify(SSL_CTX *ctx, int mode, void *callback)

    # SSL object lifecycle
    SSL* SSL_new(SSL_CTX *ctx)
    void SSL_free(SSL *ssl)
    void SSL_set_bio(SSL *ssl, BIO *rbio, BIO *wbio)

    # SSL handshake and state
    void SSL_set_accept_state(SSL *ssl)
    void SSL_set_connect_state(SSL *ssl)
    int SSL_do_handshake(SSL *ssl)
    int SSL_is_init_finished(SSL *ssl)

    # SSL read/write
    int SSL_read(SSL *ssl, void *buf, int num)
    int SSL_write(SSL *ssl, const void *buf, int num)

    # SSL error handling
    int SSL_get_error(SSL *ssl, int ret)

    # DTLS timeout handling
    long SSL_ctrl(SSL *ssl, int cmd, long larg, void *parg)

    # Constants
    enum:
        SSL_FILETYPE_PEM
        SSL_VERIFY_PEER
        SSL_VERIFY_NONE
        SSL_ERROR_NONE
        SSL_ERROR_WANT_READ
        SSL_ERROR_WANT_WRITE
        SSL_ERROR_SSL
        SSL_ERROR_SYSCALL
        DTLS_CTRL_HANDLE_TIMEOUT
        DTLS_CTRL_GET_TIMEOUT

cdef extern from "openssl/bio.h" nogil:
    ctypedef struct BIO
    ctypedef struct BIO_METHOD

    const BIO_METHOD* BIO_s_mem()
    BIO* BIO_new(const BIO_METHOD *type)
    int BIO_read(BIO *b, void *data, int dlen)
    int BIO_write(BIO *b, const void *data, int dlen)
    size_t BIO_ctrl_pending(BIO *b)

cdef extern from "openssl/err.h" nogil:
    unsigned long ERR_get_error()
    unsigned long ERR_peek_error()
    char* ERR_error_string(unsigned long e, char *buf)
    void ERR_clear_error()

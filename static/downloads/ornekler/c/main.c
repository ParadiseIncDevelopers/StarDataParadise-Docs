#include <StarDataParadiseDLLler.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static sdp_text text(const char* value) {
    sdp_text result = {value, (uint32_t)strlen(value)};
    return result;
}

int main(void) {
    const char *address = getenv("SDP_HOST"), *port_text = getenv("SDP_PORT");
    const char *name = getenv("SDP_TLS_NAME"), *ca = getenv("SDP_CA");
    const char *user = getenv("SDP_USER"), *password = getenv("SDP_PASSWORD");
    if (!address || !port_text || !name || !ca || !user || !password) {
        fputs("SDP_HOST, SDP_PORT, SDP_TLS_NAME, SDP_CA, SDP_USER, SDP_PASSWORD gerekir.\n", stderr);
        return 2;
    }
    char *end = NULL;
    long port = strtol(port_text, &end, 10);
    if (!*port_text || *end || port < 1 || port > 65535) return 2;
    sdp_open_options options = {0};
    options.struct_size = sizeof(options);
    options.abi_version = SDP_ABI_VERSION;
    options.address = text(address);
    options.port = (uint16_t)port;
    options.server_name = text(name);
    options.ca_file = text(ca);
    options.username = text(user);
    options.password = text(password);
    options.timeout_ms = 5000;
    sdp_connection connection = 0;
    sdp_error error = {0};
    sdp_buffer capabilities = {0};
    sdp_status status = sdp_open(&options, &connection, &error);
    if (status == SDP_OK) status = sdp_get_capabilities(connection, &capabilities, &error);
    if (status == SDP_OK) {
        fwrite(capabilities.data, 1, capabilities.size, stdout);
        fputc('\n', stdout);
    } else {
        fprintf(stderr, "code=%d sqlstate=%s correlation=%s\n", error.code, error.sqlstate, error.correlation_id);
    }
    sdp_buffer_free(&capabilities);
    if (connection) sdp_close(connection, NULL);
    return status == SDP_OK ? 0 : 1;
}

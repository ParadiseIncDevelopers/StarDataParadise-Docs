#include <StarDataParadiseDLLler.hpp>
#include <charconv>
#include <cstdlib>
#include <iostream>
#include <string_view>

int main() {
    const char* address = std::getenv("SDP_HOST");
    const char* port_text = std::getenv("SDP_PORT");
    const char* name = std::getenv("SDP_TLS_NAME");
    const char* ca = std::getenv("SDP_CA");
    const char* user = std::getenv("SDP_USER");
    const char* password = std::getenv("SDP_PASSWORD");
    if (!address || !port_text || !name || !ca || !user || !password) {
        std::cerr << "SDP_HOST, SDP_PORT, SDP_TLS_NAME, SDP_CA, SDP_USER, SDP_PASSWORD gerekir.\n";
        return 2;
    }
    std::string_view port_string(port_text);
    uint16_t port{};
    auto parsed = std::from_chars(port_string.data(), port_string.data()+port_string.size(), port);
    if (parsed.ec != std::errc{} || parsed.ptr != port_string.data()+port_string.size() || !port) return 2;
    try {
        using sdp::client::text;
        sdp_open_options options{};
        options.struct_size = sizeof(options);
        options.abi_version = SDP_ABI_VERSION;
        options.address = text(address);
        options.port = port;
        options.server_name = text(name);
        options.ca_file = text(ca);
        options.username = text(user);
        options.password = text(password);
        options.timeout_ms = 5000;
        sdp::client::Connection connection(options);
        connection.health();
        std::cout << connection.capabilities().view() << '\n';
        sdp::client::Transaction transaction(connection);
        {
            sdp::client::Statement insert(connection,
                "INSERT INTO main.public.musteriler (id, ad, eposta) VALUES (:id, :ad, :eposta)",
                R"({"id":{"type":"BIGINT"},"ad":{"type":"TEXT"},"eposta":{"type":"TEXT"}})");
            auto answer = insert.execute(
                R"({"id":{"t":"i64","v":"9001"},"ad":{"t":"text","v":"SDK Deneme"},"eposta":{"t":"text","v":"demo@example.invalid"}})");
            std::cout << answer.view() << '\n';
        }
        transaction.rollback();
        std::cout << "Deneme geri alindi; musteri 9001 kalici yazilmadi.\n";
    } catch (const sdp::client::Error& error) {
        std::cerr << "code=" << error.status() << " unknown=" << error.unknown_outcome()
                  << " sqlstate=" << error.details().sqlstate << '\n';
        return 1;
    }
}

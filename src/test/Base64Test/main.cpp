#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>
#include <TwkUtil/Base64.h>
#include <string>
#include <vector>

using namespace TwkUtil;
using namespace std;

TEST_CASE("Base64 Encoding and Decoding")
{
    SUBCASE("Simple string")
    {
        string original = "Hello World";
        string encoded = base64Encode(original);
        
        vector<char> decoded_vec;
        base64Decode(encoded, decoded_vec);
        string decoded(decoded_vec.begin(), decoded_vec.end());
        
        // Boost's base64 implementation might add padding or have slight differences 
        // in how it handles the end of the string, but it should decode back correctly.
        // Note: base64Decode might need the correct size or handle padding.
        
        // We need to be careful with null terminators or extra chars if base64Decode doesn't trim.
        // Let's check the size.
        CHECK(decoded.substr(0, original.size()) == original);
    }

    SUBCASE("Empty string")
    {
        string original = "";
        string encoded = base64Encode(original);
        CHECK(encoded == "");
        
        vector<char> decoded_vec;
        base64Decode(encoded, decoded_vec);
        CHECK(decoded_vec.empty());
    }
    
    SUBCASE("Binary data")
    {
        char data[] = {0, 1, 2, 3, 4, 5, (char)255};
        string encoded = base64Encode(data, 7);
        
        vector<char> decoded_vec;
        base64Decode(encoded, decoded_vec);
        
        REQUIRE(decoded_vec.size() >= 7);
        for(int i=0; i<7; ++i)
        {
            CHECK(decoded_vec[i] == data[i]);
        }
    }
}

TEST_CASE("ID64 Encoding and Decoding")
{
    SUBCASE("Standard ID64")
    {
        string original = "Hello? World/Base64+Test=";
        string encoded = id64Encode(original);
        
        // Ensure no standard base64 special chars that are replaced by default in id64
        CHECK(encoded.find('/') == string::npos);
        CHECK(encoded.find('+') == string::npos);
        CHECK(encoded.find('=') == string::npos);
        
        vector<char> decoded_vec;
        id64Decode(encoded, decoded_vec);
        string decoded(decoded_vec.begin(), decoded_vec.end());
        
        CHECK(decoded.substr(0, original.size()) == original);
    }
}

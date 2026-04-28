#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>
#include <TwkUtil/TwkRegEx.h>
#include <string>

using namespace TwkUtil;
using namespace std;

TEST_CASE("TwkRegEx")
{
    SUBCASE("Simple Match")
    {
        RegEx re("hello (.*)");
        string target = "hello world";
        CHECK(re.match(target));
        
        // Note: TwkRegEx might have specific API for sub-matches
        // This is a basic existence test
    }

    SUBCASE("No Match")
    {
        RegEx re("hello (.*)");
        string target = "goodbye world";
        CHECK_FALSE(re.match(target));
    }
}

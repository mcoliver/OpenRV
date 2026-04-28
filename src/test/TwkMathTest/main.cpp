#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>
#include <TwkMath/Vec2.h>
#include <TwkMath/Box.h>
#include <TwkMath/Mat44.h>

using namespace TwkMath;
using namespace std;

TEST_CASE("TwkMath::Vec2")
{
    SUBCASE("Construction and Basic Operations")
    {
        Vec2f v1(1.0f, 2.0f);
        CHECK(v1.x == 1.0f);
        CHECK(v1.y == 2.0f);

        Vec2f v2 = v1 + Vec2f(3.0f, 4.0f);
        CHECK(v2.x == 4.0f);
        CHECK(v2.y == 6.0f);
        
        CHECK(v1.length() == doctest::Approx(2.236067f));
    }
}

TEST_CASE("TwkMath::Box2")
{
    SUBCASE("Intersection and Union")
    {
        Box2f b1(Vec2f(0, 0), Vec2f(10, 10));
        Box2f b2(Vec2f(5, 5), Vec2f(15, 15));
        
        Box2f b3 = b1;
        b3.extendBy(b2);
        
        CHECK(b3.min == Vec2f(0, 0));
        CHECK(b3.max == Vec2f(15, 15));
        
        CHECK(b1.intersects(b2));
        CHECK_FALSE(b1.intersects(Box2f(Vec2f(20, 20), Vec2f(30, 30))));
    }
}

TEST_CASE("TwkMath::Mat44")
{
    SUBCASE("Identity and Multiplications")
    {
        Mat44f m1; // Identity
        CHECK(m1(0,0) == 1.0f);
        CHECK(m1(1,1) == 1.0f);
        CHECK(m1(0,1) == 0.0f);
        
        Vec4f v(1, 0, 0, 1);
        Vec4f v2 = m1 * v;
        CHECK(v2.x == 1.0f);
        CHECK(v2.w == 1.0f);
    }
}

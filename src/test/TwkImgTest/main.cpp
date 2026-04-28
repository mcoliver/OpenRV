#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>
#include <TwkImg/TwkImgImage.h>
#include <TwkImg/TwkImgResampler.h>
#include <TwkMath/Color.h>

using namespace TwkImg;
using namespace TwkMath;
using namespace std;

TEST_CASE("TwkImg::BiLinearRsmp")
{
    // Create a 2x2 test image
    // (0,1)=[0,1]  (1,1)=[1,1]
    // (0,0)=[0,0]  (1,0)=[1,0]
    Image<Col4f> img(2, 2);
    img.pixel(0, 0) = Col4f(0, 0, 0, 1);
    img.pixel(1, 0) = Col4f(1, 0, 0, 1);
    img.pixel(0, 1) = Col4f(0, 1, 0, 1);
    img.pixel(1, 1) = Col4f(1, 1, 0, 1);

    BiLinearRsmp<Col4f> rsmp;

    SUBCASE("Exact pixel sample")
    {
        Col4f val;
        float cov = rsmp.sample(img, Vec2f(0, 0), val);
        CHECK(cov == 1.0f);
        CHECK(val.r == 0.0f);
        CHECK(val.g == 0.0f);
    }

    SUBCASE("Center sample (interpolation)")
    {
        Col4f val;
        float cov = rsmp.sample(img, Vec2f(0.5f, 0.5f), val);
        CHECK(cov == 1.0f);
        // Midpoint of (0,0,0,1), (1,0,0,1), (0,1,0,1), (1,1,0,1) should be (0.5, 0.5, 0, 1)
        CHECK(val.r == doctest::Approx(0.5f));
        CHECK(val.g == doctest::Approx(0.5f));
        CHECK(val.b == 0.0f);
        CHECK(val.a == 1.0f);
    }

    SUBCASE("Boundary sample")
    {
        Col4f val;
        float cov = rsmp.sample(img, Vec2f(0.5f, 0.0f), val);
        CHECK(cov == 1.0f);
        CHECK(val.r == doctest::Approx(0.5f));
        CHECK(val.g == 0.0f);
    }
}

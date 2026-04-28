#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>
#include <IOtiff/IOtiff.h>
#include <TwkFB/FrameBuffer.h>
#include <TwkUtil/File.h>
#include <iostream>

using namespace TwkFB;
using namespace std;

TEST_CASE("libtiff Dependency Probe")
{
    // 1. Create a small test FrameBuffer (8x8, RGB, UCHAR)
    int w = 8;
    int h = 8;
    int c = 3;
    FrameBuffer fb(w, h, c, FrameBuffer::UCHAR);
    
    // Fill with a pattern
    unsigned char* pixels = fb.pixels();
    for (int y = 0; y < h; ++y)
    {
        for (int x = 0; x < w; ++x)
        {
            pixels[(y * w + x) * c + 0] = x * 30; // R
            pixels[(y * w + x) * c + 1] = y * 30; // G
            pixels[(y * w + x) * c + 2] = 128;    // B
        }
    }

    // 2. Write to a temporary TIFF file
    string tempFile = "probe_test.tif";
    IOtiff io;
    
    StreamingFrameBufferIO::WriteRequest wreq;
    CHECK_NOTHROW(io.writeImage(fb, tempFile, wreq));

    // 3. Read it back
    FrameBuffer inFb;
    StreamingFrameBufferIO::ReadRequest rreq;
    CHECK_NOTHROW(io.readImage(inFb, tempFile, rreq));

    // 4. Verify dimensions and data
    CHECK(inFb.width() == w);
    CHECK(inFb.height() == h);
    CHECK(inFb.numChannels() == c);
    CHECK(inFb.dataType() == FrameBuffer::UCHAR);

    const unsigned char* inPixels = inFb.pixels();
    REQUIRE(inPixels != nullptr);
    
    // Check a few pixels
    CHECK(inPixels[0] == 0);
    CHECK(inPixels[((h-1) * w + (w-1)) * c + 0] == (w-1) * 30);
    CHECK(inPixels[((h-1) * w + (w-1)) * c + 1] == (h-1) * 30);

    // 5. Cleanup
    TwkUtil::pathRemove(tempFile);
}

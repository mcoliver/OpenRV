#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>
#include <IOpng/IOpng.h>
#include <TwkFB/FrameBuffer.h>
#include <TwkUtil/File.h>
#include <iostream>

using namespace TwkFB;
using namespace std;

TEST_CASE("libpng Dependency Probe")
{
    // 1. Create a small test FrameBuffer (8x8, RGB, UCHAR)
    int w = 8;
    int h = 8;
    int c = 3;
    FrameBuffer fb(w, h, c, FrameBuffer::UCHAR);
    
    // 2. Write to a temporary PNG file
    string tempFile = "probe_test.png";
    IOpng io;
    
    FrameBufferIO::WriteRequest wreq;
    CHECK_NOTHROW(io.writeImage(fb, tempFile, wreq));

    // 3. Read it back
    FrameBuffer inFb;
    FrameBufferIO::ReadRequest rreq;
    CHECK_NOTHROW(io.readImage(inFb, tempFile, rreq));

    // 4. Verify dimensions and data
    CHECK(inFb.width() == w);
    CHECK(inFb.height() == h);
    CHECK(inFb.numChannels() == c);
    CHECK(inFb.dataType() == FrameBuffer::UCHAR);

    // 5. Cleanup
    TwkUtil::pathRemove(tempFile);
}

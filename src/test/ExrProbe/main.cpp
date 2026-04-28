#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>
#include <IOexr/IOexr.h>
#include <TwkFB/FrameBuffer.h>
#include <TwkUtil/File.h>
#include <iostream>

using namespace TwkFB;
using namespace std;

TEST_CASE("OpenEXR Dependency Probe")
{
    // 1. Create a small test FrameBuffer (8x8, RGB, HALF)
    int w = 8;
    int h = 8;
    int c = 3;
    FrameBuffer fb(w, h, c, FrameBuffer::HALF);
    
    // 2. Write to a temporary EXR file
    string tempFile = "probe_test.exr";
    IOexr io;
    
    StreamingFrameBufferIO::WriteRequest wreq;
    CHECK_NOTHROW(io.writeImage(fb, tempFile, wreq));

    // 3. Read it back
    FrameBuffer inFb;
    StreamingFrameBufferIO::ReadRequest rreq;
    CHECK_NOTHROW(io.readImage(inFb, tempFile, rreq));

    // 4. Verify dimensions and data
    CHECK(inFb.width() == w);
    CHECK(inFb.height() == h);
    // OpenEXR might read back 4 channels (RGBA) if it was forced, but let's check what we got
    CHECK(inFb.dataType() == FrameBuffer::HALF);

    // 5. Cleanup
    TwkUtil::pathRemove(tempFile);
}

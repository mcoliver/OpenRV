#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>
#include <OpenColorIO/OpenColorIO.h>
#include <iostream>

namespace OCIO = OCIO_NAMESPACE;

TEST_CASE("OpenColorIO Dependency Probe")
{
    // A simple OCIO test that doesn't require a config file.
    // We'll create a MatrixTransform and apply it.

    SUBCASE("Matrix Transform")
    {
        // Create a matrix that swaps R and G
        double matrix[16] = { 0, 1, 0, 0,
                              1, 0, 0, 0,
                              0, 0, 1, 0,
                              0, 0, 0, 1 };

        OCIO::MatrixTransformRcPtr matrixTransform = OCIO::MatrixTransform::Create();
        matrixTransform->setMatrix(matrix);

        // Create a CPU processor
        OCIO::ConfigRcPtr config = OCIO::Config::Create();
        OCIO::ConstProcessorRcPtr processor = config->getProcessor(matrixTransform, OCIO::TRANSFORM_DIR_FORWARD);
        OCIO::ConstCPUProcessorRcPtr cpu = processor->getDefaultCPUProcessor();

        // Apply to a single pixel
        float pixel[4] = { 1.0f, 0.5f, 0.0f, 1.0f };
        OCIO::PackedImageDesc img(pixel, 1, 1, 4);
        
        CHECK_NOTHROW(cpu->apply(img));

        // R and G should be swapped
        CHECK(pixel[0] == 0.5f);
        CHECK(pixel[1] == 1.0f);
        CHECK(pixel[2] == 0.0f);
        CHECK(pixel[3] == 1.0f);
    }

    SUBCASE("Version Check")
    {
        std::string version = OCIO::GetVersion();
        CHECK(!version.empty());
        std::cout << "INFO: OCIO Version: " << version << std::endl;
    }
}

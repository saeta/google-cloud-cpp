# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This should be included from the top level CMakeLists file
set(STORAGE_CLIENT_VERSION_MAJOR 0)
set(STORAGE_CLIENT_VERSION_MINOR 1)
set(STORAGE_CLIENT_VERSION_PATCH 0)

# Configure the Compiler options, we will be using C++11 features.
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(DOXYGEN_PROJECT_NAME "Google Cloud Storage C++ Client")
set(DOXYGEN_PROJECT_BRIEF "A C++ Client Library for Google Cloud Storage")
set(DOXYGEN_PROJECT_NUMBER
    "${STORAGE_CLIENT_VERSION_MAJOR}.${STORAGE_CLIENT_VERSION_MINOR}.${STORAGE_CLIENT_VERSION_PATCH}")
set(DOXYGEN_EXAMPLE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/examples)
set(DOXYGEN_PREDEFINED "STORAGE_CLIENT_NS=v${BIGTABLE_CLIENT_VERSION_MAJOR}")
set(DOXYGEN_EXCLUDE_PATTERNS
    "*/google/cloud/storage/README.md"
    "*/google/cloud/storage/ci/*"
    "*/google/cloud/storage/examples/*.md"
    "*/google/cloud/storage/internal/*"
    "*/google/cloud/storage/testing/*"
    "*/google/cloud/storage/tests/*"
    "*/google/cloud/storage/*_test.cc")

include(GoogleCloudCppCommon)
include(IncludeNlohmannJson)

# Generate the version information from the CMake values.
configure_file(version_info.h.in version_info.h)

# Define an interface library, i.e., a library that really has no sources, and
# add public target options to it.  The targets then use the library via
# target_link_libraries(target PRIVATE storage_common_options), which
# implicitly adds the options to those targets, but does *not* add the options
# to any targets that depend on them.  This is a CMake idiom to add options to
# targets without having to painfully set special variables, it also allows
# users to add more common options without having to touch the code.
add_library(storage_common_options INTERFACE)
google_cloud_cpp_add_common_options(storage_common_options)

# Enable unit tests
enable_testing()

# Search for libcurl, in CMake 3.5 this does not define a target, but it will
# in 3.12 (see https://cmake.org/cmake/help/git-stage/module/FindCURL.html for
# details).  Until then, define the target ourselves if it is missing.
find_package(CURL REQUIRED)
if (NOT TARGET CURL::CURL)
    add_library(CURL::CURL UNKNOWN IMPORTED)
    set_property(TARGET CURL::CURL APPEND
        PROPERTY INTERFACE_INCLUDE_DIRECTORIES
            "${CURL_INCLUDE_DIR}")
    set_property(TARGET CURL::CURL APPEND
        PROPERTY IMPORTED_LOCATION
            "${CURL_LIBRARY}")
endif ()
# If the library is static, we need to explicitly link its dependencies.
# However, we should not do so for shared libraries, because the version of
# OpenSSL (for example) found by find_package() may be newer than the
# version linked against libcurl.
if ("${CURL_LIBRARY}" MATCHES "${CMAKE_STATIC_LIBRARY_SUFFIX}$")
    find_package(OpenSSL REQUIRED)
    find_package(ZLIB REQUIRED)
    set_property(TARGET CURL::CURL APPEND
        PROPERTY INTERFACE_LINK_LIBRARIES
        OpenSSL::SSL
        OpenSSL::Crypto
        ZLIB::ZLIB)
    message(STATUS "CURL linkage will be static")
else ()
    message(STATUS "CURL linkage will be non-static")
endif ()


# the client library
add_library(storage_client
    ${CMAKE_CURRENT_BINARY_DIR}/version_info.h
    bucket.h
    bucket.cc
    bucket_metadata.h
    bucket_metadata.cc
    client.h
    client.cc
    client_options.h
    client_options.cc
    credentials.h
    credentials.cc
    internal/authorized_user_credentials.h
    internal/common_metadata.h
    internal/common_metadata.cc
    internal/curl_request.h
    internal/curl_request.cc
    internal/curl_wrappers.h
    internal/curl_wrappers.cc
    internal/default_client.h
    internal/get_bucket_metadata_request.h
    internal/google_application_default_credentials_file.h
    internal/google_application_default_credentials_file.cc
    internal/http_response.h
    internal/insert_object_media_request.h
    internal/metadata_parser.h
    internal/metadata_parser.cc
    internal/nljson.h
    internal/parse_rfc3339.h
    internal/parse_rfc3339.cc
    internal/read_object_range_request.h
    internal/read_object_range_request.cc
    internal/request_parameters.h
    object.h
    object.cc
    object_metadata.h
    object_metadata.cc
    object_stream.h
    object_stream.cc
    well_known_parameters.h
    status.h
    version.h
    version.cc)
target_link_libraries(storage_client
    PUBLIC
        google_cloud_cpp_common
        CURL::CURL
        Threads::Threads
    PRIVATE
        nlohmann_json
        storage_common_options)
if (WIN32)
    target_link_libraries(storage_client
        PUBLIC
            wsock32 ws2_32)
endif ()
target_include_directories(storage_client PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>
    $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}>
    $<INSTALL_INTERFACE:include>)
target_compile_options(storage_client PUBLIC ${GOOGLE_CLOUD_CPP_EXCEPTIONS_FLAG})

add_library(storage_client_testing
    testing/canonical_errors.h
    testing/mock_client.h
    testing/mock_http_request.h
    testing/mock_http_request.cc)
target_link_libraries(storage_client_testing
    PUBLIC
        storage_client
        gmock
    PRIVATE
        nlohmann_json
        storage_common_options)
target_include_directories(storage_client_testing PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>
    $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}>
    $<INSTALL_INTERFACE:include>)
target_compile_options(storage_client_testing PUBLIC ${GOOGLE_CLOUD_CPP_EXCEPTIONS_FLAG})

include(CreateBazelConfig)
create_bazel_config(storage_client)
google_cloud_cpp_add_clang_tidy(storage_client)
create_bazel_config(storage_client_testing)

# List the unit tests, then setup the targets and dependencies.
set(storage_client_unit_tests
    bucket_metadata_test.cc
    bucket_test.cc
    internal/authorized_user_credentials_test.cc
    internal/default_client_test.cc
    internal/google_application_default_credentials_file_test.cc
    internal/metadata_parser_test.cc
    internal/nljson_test.cc
    internal/parse_rfc3339_test.cc
    internal/read_object_range_request_test.cc
    object_metadata_test.cc
    object_stream_test.cc
    object_test.cc
    link_test.cc)

foreach (fname ${storage_client_unit_tests})
    string(REPLACE "/" "_" target ${fname})
    string(REPLACE ".cc" "" target ${target})
    add_executable(${target} ${fname})
    target_link_libraries(${target}
        PRIVATE
            storage_client_testing
            storage_client
            gmock
            CURL::CURL
            storage_common_options
            nlohmann_json)
    add_test(NAME ${target} COMMAND ${target})
endforeach ()

# Export the list of unit tests so the Bazel BUILD file can pick it up.
export_list_to_bazel("storage_client_unit_tests.bzl" "storage_client_unit_tests")

add_subdirectory(tests)

if (GOOGLE_CLOUD_CPP_ENABLE_CXX_EXCEPTIONS)
    add_subdirectory(examples)
endif (GOOGLE_CLOUD_CPP_ENABLE_CXX_EXCEPTIONS)

# Install the libraries and headers in the locations determined by
# GNUInstallDirs
install(TARGETS storage_common_options nlohmann_json
    EXPORT storage-targets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

# Export the CMake targets to make it easy to create configuration files.
install(EXPORT storage-targets DESTINATION
    "${CMAKE_INSTALL_LIBDIR}/cmake/storage_client")

install(TARGETS storage_client
    EXPORT storage-targets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(DIRECTORY . DESTINATION include/storage/client
    FILES_MATCHING PATTERN "*.h"
    PATTERN "testing/*" EXCLUDE)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/version_info.h
    DESTINATION include/storage/client)

# Setup global variables used in the following *.in files.
set(GOOGLE_CLOUD_CPP_CONFIG_VERSION_MAJOR ${STORAGE_CLIENT_VERSION_MAJOR})
set(GOOGLE_CLOUD_CPP_CONFIG_VERSION_MINOR ${STORAGE_CLIENT_VERSION_MINOR})
set(GOOGLE_CLOUD_CPP_CONFIG_VERSION_PATCH ${STORAGE_CLIENT_VERSION_PATCH})
set(GOOGLE_CLOUD_CPP_PC_NAME "The Google Cloud Storage C++ Client Library")
set(GOOGLE_CLOUD_CPP_PC_DESCRIPTION "Provides C++ APIs to access Google Cloud Storage.")
set(GOOGLE_CLOUD_CPP_PC_LIBS "-lstorage_client")

# Create and install the pkg-config files.
configure_file("${PROJECT_SOURCE_DIR}/google/cloud/config.pc.in" "storage_client.pc" @ONLY)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/storage_client.pc"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig")

# Create and install the CMake configuration files.
configure_file("config.cmake.in" "storage_client-config.cmake" @ONLY)
configure_file("${PROJECT_SOURCE_DIR}/google/cloud/config-version.cmake.in"
    "storage_client-config-version.cmake" @ONLY)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/storage_client-config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/storage_client-config-version.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/storage_client")

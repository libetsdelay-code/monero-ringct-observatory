
# Appended to tests/performance_tests/CMakeLists.txt by Dockerfile.size.
monero_add_minimal_executable(size_probe size_probe.cpp)
target_link_libraries(size_probe
  PRIVATE
    wallet
    cryptonote_core
    common
    cncrypto
    epee
    ${Boost_CHRONO_LIBRARY}
    ${CMAKE_THREAD_LIBS_INIT}
    ${EXTRA_LIBRARIES})

cmake_minimum_required(VERSION 2.6)
project(metaruby)

find_package(Ruby REQUIRED)
string(REGEX REPLACE ".*(lib|share)(32|64)?/?" "\\1/" RUBY_EXTENSIONS_INSTALL_DIR ${RUBY_ARCH_DIR})
string(REGEX REPLACE ".*(lib|share)(32|64)?/?" "\\1/" RUBY_LIBRARY_INSTALL_DIR ${RUBY_RUBY_LIB_PATH})

install(DIRECTORY lib/ DESTINATION ${RUBY_LIBRARY_INSTALL_DIR} )
install(FILES package.xml DESTINATION share/${PROJECT_NAME})

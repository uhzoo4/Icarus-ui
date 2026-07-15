cmake_minimum_required(VERSION 3.16)
project(hyprctl_mock)

find_package(Qt6 REQUIRED COMPONENTS Core DBus)

add_executable(hyprctl hyprctl.cpp)
target_link_libraries(hyprctl Qt6::Core Qt6::DBus)

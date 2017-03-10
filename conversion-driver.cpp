//=======1=========2=========3=========4=========5=========6=========7=========8=========9=========0=========1=========2=========3=========4=========5=========6=========7**
//Author information
//  Author name: Sina Amini
//  Author email: sinamindev@gmail.com
//Project information
//  Project title: The Power of e
//  Purpose: This program reads two floats and an integer to compute a Taylor Series algorithm using a while loop and outputs runtime
//  Status: Performs correctly on Linux 64-bit platforms with AVX
//  Project files: Project files: conversion-driver.cpp, conversion.asm
//Module information
//  This module's call name: runme.out  This module is invoked by the user
//  Language: C++
//  Date last modified: 2014-Oct-13
//  Purpose: This module is the top level driver: it will call hexconversion
//  File name: conversion-driver.cpp
//  Status: In production.  No known errors.
//  Future enhancements: None planned
//Translator information
//  Gnu compiler: g++ -c -m64 -Wall -l conversion.lis -o conversion-driver.o conversion-driver.cpp
//  Gnu linker:   g++ -m64 -o runme.out conversion-driver.o conversion.o 
//References and credits
//  Seyfarth
//  Professor Holliday public domain programs 
//  This module is standard C++
//Format information
//  Page width: 172 columns
//  Begin comments: 61
//  Optimal print specification: Landscape, 7 points or smaller, monospace, 8½x11 paper
//
//===== Begin code area ===================================================================================================================================================

#include <stdio.h>
#include <stdint.h>
#include <ctime>
#include <cstring>

extern "C" double hexconversion();

int main(){

  double return_code = -99.99;

  printf("%s","\nThis project is programmed by Sina Amini \n");
  printf("%s","This software is running on a Lenovo Y500 with processor Intel core i7-3630QM running at 3.00GHz. \n\n");

  return_code = hexconversion();
  printf("%s%1.18lf%s\n","The driver received this number: ",return_code, ". Have a nice X86 day.");

  return 0;

}//End of main

//===== End of main =======================================================================================================================================================

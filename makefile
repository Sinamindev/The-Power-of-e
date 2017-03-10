runme: conversion-driver.cpp conversion.o
	gcc conversion-driver.cpp conversion.o -o runme

conversion.o: conversion.asm 
	nasm -f elf64 conversion.asm -o conversion.o

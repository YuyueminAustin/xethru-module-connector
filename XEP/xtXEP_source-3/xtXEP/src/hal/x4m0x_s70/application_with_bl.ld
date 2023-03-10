/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Not finished!!!!!!!!!!!!!!!!!!!!
/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/**
 * @file
 *
 * @brief Linker script for linking and creating binary executable.
 */
/* ---------------------------------------------------------------------------- */
/*                  Atmel Microcontroller Software Support                      */
/*                       SAM Software Package License                           */
/* ---------------------------------------------------------------------------- */
/* Copyright (c) 2015, Atmel Corporation                                        */
/*                                                                              */
/* All rights reserved.                                                         */
/*                                                                              */
/* Redistribution and use in source and binary forms, with or without           */
/* modification, are permitted provided that the following condition is met:    */
/*                                                                              */
/* - Redistributions of source code must retain the above copyright notice,     */
/* this list of conditions and the disclaimer below.                            */
/*                                                                              */
/* Atmel's name may not be used to endorse or promote products derived from     */
/* this software without specific prior written permission.                     */
/*                                                                              */
/* DISCLAIMER:  THIS SOFTWARE IS PROVIDED BY ATMEL "AS IS" AND ANY EXPRESS OR   */
/* IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT ARE   */
/* DISCLAIMED. IN NO EVENT SHALL ATMEL BE LIABLE FOR ANY DIRECT, INDIRECT,      */
/* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT */
/* LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,  */
/* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    */
/* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING         */
/* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, */
/* EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                           */
/* ---------------------------------------------------------------------------- */

/*------------------------------------------------------------------------------
 *      Linker script for running in internal FLASH on the ATSAMV70Q20
 *----------------------------------------------------------------------------*/

OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
SEARCH_DIR(.)

	/* Memory layout:
	 * 0x00400000 - 0x004EFFFF: Application
	 * 0x004F0000 - 0x004F7FFF: Unused
	 * 0x004F8000 - 0x004F9FFF: Temp
	 * 0x004FA000 - 0x004FBFFF: Eeprom
	 * 0x004FC000 - 0x004FDFFF: RW_Parameters
	 * 0x004FE000 - 0x004FFFFF: RO_Parameters
	 *
	 */
MEMORY
{
  rom           (rx)  : ORIGIN = 0x00400000, LENGTH = 0x000E0000 /* Use the 4 x 8kB as temp + eeprom + RW_Parameters + RO_Parameters. LENGTH = 0x00100000 - (4 * 0x2000) = 0x000FB000*/
  app_storage   (rw)  : ORIGIN = 0x004E0000, LENGTH = 0x00018000 /* 96 kB reserved to application data storage */
  RW_Parameters (rw)  : ORIGIN = 0x004F8000, LENGTH = 0x00004000 /* 16 kB reserved for RW_Parameters */
  RO_Parameters (r)   : ORIGIN = 0x004FC000, LENGTH = 0x00004000 /* 16 kB reserved for RO_Parameters */
  ram			(rwx) : ORIGIN = 0x20400000, LENGTH = 0x00060000
  extram        (rwx) : ORIGIN = 0x70000000, LENGTH = 0x00800000 /* 8MB SDRAM */
}

/* The stack size used by the application. NOTE: you need to adjust according to your application. */
STACK_SIZE = DEFINED(STACK_SIZE) ? STACK_SIZE : 0xA00;

/* The heapsize used by the application. NOTE: you need to adjust according to your application. */
HEAP_SIZE = DEFINED(HEAP_SIZE) ? HEAP_SIZE : 0x400;

/* Section Definitions */
SECTIONS
{
    .text :
    {
        . = ALIGN(4);
        _sfixed = .;
        KEEP(*(.vectors .vectors.*))
        *(.text .text.* .gnu.linkonce.t.*)
        *(.glue_7t) *(.glue_7)
        *(.rodata .rodata* .gnu.linkonce.r.*)
        *(.ARM.extab* .gnu.linkonce.armextab.*)

        /* Support C constructors, and C destructors in both user code
           and the C library. This also provides support for C++ code. */
        . = ALIGN(4);
        KEEP(*(.init))
        . = ALIGN(4);
        __preinit_array_start = .;
        KEEP (*(.preinit_array))
        __preinit_array_end = .;

        . = ALIGN(4);
        __init_array_start = .;
        KEEP (*(SORT(.init_array.*)))
        KEEP (*(.init_array))
        __init_array_end = .;

        . = ALIGN(0x4);
        KEEP (*crtbegin.o(.ctors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
        KEEP (*(SORT(.ctors.*)))
        KEEP (*crtend.o(.ctors))

        . = ALIGN(4);
        KEEP(*(.fini))

        . = ALIGN(4);
        __fini_array_start = .;
        KEEP (*(.fini_array))
        KEEP (*(SORT(.fini_array.*)))
        __fini_array_end = .;

        KEEP (*crtbegin.o(.dtors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
        KEEP (*(SORT(.dtors.*)))
        KEEP (*crtend.o(.dtors))

        . = ALIGN(4);
        _efixed = .;            /* End of text section */
    } > rom

    /* .ARM.exidx is sorted, so has to go in its own output section.  */
    PROVIDE_HIDDEN (__exidx_start = .);
    .ARM.exidx :
    {
      *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    } > rom
    PROVIDE_HIDDEN (__exidx_end = .);

    . = ALIGN(4);
    _etext = .;

    .relocate : AT (_etext)
    {
        . = ALIGN(4);
        _srelocate = .;
        *(.ramfunc .ramfunc.*);
        *(.data .data.*);
        . = ALIGN(4);
        _erelocate = .;
    } > ram

    /* .bss section which is used for uninitialized data */
    .bss (NOLOAD) :
    {
        . = ALIGN(4);
		__bss_start__ = .;
        _sbss = . ;
        _szero = .;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = . ;
        _ezero = .;
		__bss_end__ = .;
    } > ram

    /* stack section */
    .stack (NOLOAD):
    {
        . = ALIGN(8);
        _sstack = .;
        . = . + STACK_SIZE;
        . = ALIGN(8);
        _estack = .;
    } > ram

    /* heap section */
    .heap (NOLOAD):
    {
        . = ALIGN(8);
         _sheap = .;
        . = . + HEAP_SIZE;
        . = ALIGN(8);
        _eheap = .;
    } > ram

    . = ALIGN(4);
    _end = . ;
    __ram_end__ = ORIGIN(ram) + LENGTH(ram) -1 ;

	.temp_area :
    {
        . = ALIGN(4);
        _temp_area_start = .;
    } > temp_area

    .eeprom_area :
    {
        . = ALIGN(4);
        _eeprom_area_start = .;
        KEEP(*(.eeprom_area))
    } > eeprom_area

    .RW_Parameters :
    {
        . = ALIGN(4);
        _RW_Parameters_start = .;
        KEEP(*(.RW_Parameters))
        _RW_Parameters_end = .; /* This pointer should not be used, since this section may be overwritten with data with different size */
    } > RW_Parameters

    .RO_Parameters :
    {
        . = ALIGN(4);
        _RO_Parameters_start = .;
        KEEP(*(.RO_Parameters))
        _RO_Parameters_end = .; /* This pointer should not be used, since this section may be overwritten with data with different size */
    } > RO_Parameters
}
